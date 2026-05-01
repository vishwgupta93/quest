public without sharing class QuestSchedulingPageController {
    public QuestSchedulingPageController() {
        ApexPages.currentPage().getHeaders().put('X-Frame-Options', 'ALLOWALL');
        ApexPages.currentPage().getHeaders().put('Content-Security-Policy', 'frame-ancestors *');
    }
}