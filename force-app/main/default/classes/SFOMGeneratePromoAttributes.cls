public class SFOMGeneratePromoAttributes{

@InvocableMethod(label='Generate Promo Attributes for Order' description='Generate Promo Attributes from Order' category='Order')
public static void generatePromoAttributes(List<ID> orderSummaryID) {

       try {
   List<PromoAttribute__c> lst = new List<PromoAttribute__c>() ;
   List<OrderItemSummary> itemSummaryList ;
   String promoJSON ;
   JSONParser parser;
    
    
      
            
        OrderSummary osm = [select Id, utmData__c,promoAttributes_json__c from  OrderSummary where Id=:orderSummaryID];
        itemSummaryList = [select Id,promoAttributes_json__c from OrderItemSummary where OrderSummaryId=:orderSummaryID ];
        promoJSON = osm.promoAttributes_json__c ;
        
             system.debug('Header PROMO JSON: ' + promoJSON );
             
             system.debug('LinesPROMO JSON: ' + itemSummaryList );
              
    if(promoJSON != null)
    {
    parser = JSON.createParser(promoJSON);
    
    //Header Level Promo Attributes
    
    while(parser.nextToken()!= null) {
            if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                                            //system.debug('Inside 1');
            while (parser.nextToken() != null) {
                                //system.debug('Inside 2');
             if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                    //system.debug('Inside 3');
             PromoAttribute__c  promoAttribute = (PromoAttribute__c)parser.readValueAs(PromoAttribute__c.class);
             promoAttribute.OrderSummaryId__c=osm.Id;
//             promoAttribute.OrderProductSummaryId__c=prodSummaryId ;
             lst.add(promoAttribute);
             }
            }
            }
          }
          }
          
          //Line Level Promo Attributes
          
           
    //LineLevel Promo Attributes
    
    if(itemSummaryList != null && itemSummaryList.size() >0)
    {
    
    for(OrderItemSummary itmSum : itemSummaryList )
    {
    promoJSON = itmSum .promoAttributes_json__c ;
    if(promoJSON != null)
    {
    system.debug('Line PROMO JSON: ' + promoJSON );
    String prodSummaryId = itmSum.Id;
     parser = JSON.createParser(promoJSON);

    while(parser.nextToken()!= null) {
            if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                                            system.debug('Inside 1');
            while (parser.nextToken() != null) {
                                system.debug('Inside 2');
             if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                    system.debug('Inside 3');
             PromoAttribute__c  promoAttribute = (PromoAttribute__c)parser.readValueAs(PromoAttribute__c.class);
             promoAttribute.OrderSummaryId__c=osm.Id;
             promoAttribute.OrderProductSummaryId__c=prodSummaryId ;
             lst.add(promoAttribute);
             }
            }
            }
          }
          }
          }
          
          }
                
                insert lst;

                  //Generate and Perist UTM Data
              
            // Parse the JSON string
            Map<String, Object> parsedData = (Map<String, Object>) JSON.deserializeUntyped(osm.utmData__c);
            
            // Create a new instance of UTM_Data__c
            Order_UTM_Data__c utmData = new Order_UTM_Data__c();
            
            // Map the JSON data to the custom object fields
            utmData.UTM_Source__c = (String) parsedData.get('utm_source');
            utmData.UTM_Medium__c = (String) parsedData.get('utm_medium');
            utmData.UTM_Campaign__c = (String) parsedData.get('utm_campaign');
            utmData.UTM_Content__c = (String) parsedData.get('utm_content');
            utmData.UTM_AdGroup__c = (String) parsedData.get('utm_adgroup');
            utmData.UTM_Device__c = (String) parsedData.get('utm_device');
            utmData.Order_Number__c = (String) parsedData.get('orderNo');
            utmData.Order_Summary__c = osm.Id;
            
            // Insert the record into the database
            insert utmData;
            } catch (Exception ex) {
            // Handle exceptions
            System.debug('Error parsing or inserting UTM data: ' + ex.getMessage());
        }
}

}