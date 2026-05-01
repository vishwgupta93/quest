# Quest PSC SDK Integration — Architecture Decision Record

## The Goal

Embed the Quest PSC Scheduling SDK (a third-party browser JavaScript library hosted on CloudFront CDN) inside a Salesforce Experience Cloud community page so that both authenticated and unauthenticated (guest/incognito) users can schedule lab appointments.

---

## What We Tried and Why It Failed

### Option 1 — Load SDK directly in LWC via `loadScript`

**Idea:** Use `lightning/platformResourceLoader` to load the SDK (either from a static resource or the CDN URL) directly inside the LWC component.

**Why it failed:**  
Salesforce Experience Cloud has **Lightning Web Security (LWS)** enabled. LWS sandboxes every LWC component — it wraps `window`, intercepts global variable assignments, and isolates component execution contexts. The Quest SDK is an IIFE that assigns its export to a top-level `var`:

```js
var QuestPSC = (function() { ... })();
```

Under LWS, this top-level `var` is not accessible as `window.QuestPSC` after loading — it gets scoped to LWS's synthetic window for that component. The SDK effectively loads but `QuestPSC` is unreachable, so `QuestPSC.initialize()` throws `ReferenceError`.

---

### Option 2 — Blob URL approach

**Idea:** Fetch the SDK JS as text, wrap it in a blob URL, and inject it into an iframe — bypassing LWS by running the SDK inside the iframe's separate execution context.

**Why it failed:**  
Two compounding blockers:

1. **LWS blocked blob URLs** — `blob:` scheme URLs are considered insecure by LWS. The exact error: `"Lightning Web Security: Unable to verify [object Blob] is secure"`.
2. **CSP blocked blob: in connect-src** — Even if LWS hadn't blocked it, the community's Content Security Policy did not allow `blob:` as a connect-src origin.

---

### Option 3 — VF page iframe on the community domain

**Idea:** Host the SDK in a Visualforce page (`QuestSchedulingPage`) accessible at the community URL (`my.site.com/customerportal/apex/QuestSchedulingPage`) and embed it in an iframe inside the LWC. VF pages run outside LWS, so the SDK would execute freely.

**Why it partially worked (authenticated users) but failed for guests:**  
VF pages and Experience Cloud community pages use **separate session cookies**. When a user accesses a VF page in an iframe, Salesforce checks for a VF session cookie. If one doesn't exist, it redirects through:

```
https://[org].my.salesforce.com/visualforce/session?url=[original-vf-page-url]
```

This redirect URL is served by Salesforce's platform with a hardcoded response header:

```
Content-Security-Policy: frame-ancestors 'self'
```

This means `my.salesforce.com` will only allow itself to be framed by other `my.salesforce.com` pages. Our community parent page is on `my.site.com` — a different origin — so the browser blocks the redirect:

> *"Framing 'https://[org].my.salesforce.com/...' violates Content Security Policy directive: frame-ancestors 'self'"*

**For authenticated community users** this was intermittently fine because logging into the community auto-establishes a VF session cookie, so no redirect was needed and the VF page loaded directly. But this is fragile — any expired VF session causes the same failure. **For guest/unauthenticated users it always fails** because there is no prior session to inherit.

We have no way to override `my.salesforce.com`'s `frame-ancestors` header — it is set at the Salesforce platform level.

---

## The Solution — VF Page on a Force.com Site

**Force.com Sites** (Setup → Sites) are a distinct Salesforce hosting mechanism designed for fully public, unauthenticated web pages. Unlike Experience Cloud communities, Force.com Sites:

- Serve pages without requiring any Salesforce session initialisation
- Do **not** redirect through `my.salesforce.com` for session transfer
- Allow Apex controllers to set response headers (including `frame-ancestors *`) which actually take effect on the response — because there is no intermediate redirect to override them

We created a public Force.com Site (`scheduleappointment`) and hosted `QuestSchedulingPage` on it. The LWC iframe now points to:

```
https://[org].my.salesforce-sites.com/scheduleappointment/apex/QuestSchedulingPage
```

The page loads cleanly for any user — authenticated or guest, normal browser or incognito — with no session transfer, no redirect, and no `frame-ancestors` violation.

---

## Final Architecture

```
Experience Cloud Community Page (my.site.com)
│
└── questSchedulingWidget LWC
    │  • Calls Apex (QuestSchedulingController) to get OAuth token
    │  • Builds iframe URL with token + orderId [+ appointmentId]
    │  • Listens for postMessage events from iframe
    │
    └── <iframe src="my.salesforce-sites.com/..."> ← Force.com Site (public, no session)
        │
        └── QuestSchedulingPage (Visualforce)
            │  • Loads Quest PSC SDK from CloudFront CDN
            │  • Initialises SDK with token, orderId, [appointmentId]
            │  • postMessages back: RESIZE, COMPLETE, ERROR, TOKEN_EXPIRED
            │
            └── Quest PSC SDK (CloudFront CDN)
                  Renders scheduling / appointment management UI
```

### Why this works

| Concern | How it's addressed |
|---|---|
| LWS sandbox blocks SDK | SDK runs inside VF page (separate browsing context, no LWS) |
| VF session transfer blocks guest users | Force.com Site pages are fully public — no session needed |
| `frame-ancestors` on `my.salesforce.com` | Never reached — no redirect happens on Force.com Sites |
| Token security | Token fetched server-side via Named Credential + External Credential (OAuth2 client_credentials); never exposed in LWC source |
| SDK version updates | SDK loaded directly from CloudFront CDN — no static resource to redeploy |

---

## Key Constraints Discovered

- **LWS cannot be disabled per-component** in Experience Cloud — it is org-wide and applies to all LWC components.
- **Salesforce's `my.salesforce.com` session transfer endpoint has a platform-level `frame-ancestors 'self'`** that cannot be overridden by any org configuration or Apex code.
- **CSP Trusted Sites in Experience Cloud** control what the community page can *load*, but cannot override response headers sent by third-party or Salesforce platform URLs.

---

## Why Not Use the VF Page Directly?

A natural question: if the SDK runs fine in the VF page, why keep the LWC at all — why not just navigate users directly to the VF page URL?

**The hard blocker is token security.**

The Force.com Site VF page is sessionless by design — that is exactly what makes it work for guest users. But sessionless also means it has no Salesforce context: it cannot call Apex, cannot use Named Credentials, and cannot access org data.

The OAuth token (required to initialise the SDK) must be fetched via a **server-side callout** using a `client_id` and `client_secret` stored securely in the External Credential. If the VF page fetched the token itself, it would have to make a client-side JavaScript request to the Quest auth endpoint — exposing the `client_id` and `client_secret` in the browser. Anyone could open DevTools and extract them.

The LWC lives inside the authenticated community context. It calls Apex, which uses the Named Credential to fetch the token entirely server-side. Only the resulting token — short-lived and scoped — is passed to the VF page as a URL parameter.

### Division of responsibility

| Responsibility | Where |
|---|---|
| Fetch OAuth token securely (credentials never leave server) | LWC → Apex → Named Credential |
| Read `orderId` / `appointmentId` from Salesforce page context | LWC |
| Run the SDK outside LWS sandboxing | VF page (Force.com Site) |
| Refresh expired token mid-session without reloading | LWC (via postMessage bridge) |
| Post-completion actions (navigation, UI updates) | LWC |

Skipping the LWC would require exposing client credentials in the browser — a non-starter for anything beyond a local prototype.

---

## Why postMessage?

The SDK runs inside an iframe on `my.salesforce-sites.com`; the LWC is on `my.site.com`. Browsers enforce strict cross-origin isolation between these two contexts — they cannot share variables, call each other's functions, or access each other's DOM. `postMessage` is the only browser-sanctioned channel for cross-origin iframe ↔ parent communication.

Each event serves a specific purpose:

| Event | Direction | Purpose |
|---|---|---|
| `QUEST_RESIZE` | iframe → LWC | SDK content height changes as user navigates steps. VF page uses `ResizeObserver` to detect this and tells the LWC to update `iframe.style.height`, avoiding clipped content or an inner scrollbar. |
| `QUEST_TOKEN_EXPIRED` | iframe → LWC | OAuth tokens are short-lived. When the SDK fires `onTokenExpired`, the VF page cannot call Apex (no session). It posts this event to the LWC, which fetches a fresh token via Apex and posts `QUEST_NEW_TOKEN` back. The SDK's Promise resolves with the new token and the session continues without a reload. |
| `QUEST_NEW_TOKEN` | LWC → iframe | The fresh token sent back in response to `QUEST_TOKEN_EXPIRED`. |
| `QUEST_COMPLETE` | iframe → LWC | Booking succeeded. Result contains the confirmation number. LWC can react — show confirmation state, update the order card, trigger navigation, etc. |
| `QUEST_ERROR` | iframe → LWC | SDK hit an unrecoverable error. LWC surfaces a user-friendly message and resets the widget so the user can retry. |

Without this bridge, the LWC would have no visibility into what the SDK is doing, and the SDK would have no way to request a refreshed token from Salesforce.
