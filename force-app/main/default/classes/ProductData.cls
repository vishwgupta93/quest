public class ProductData {
    public String productName;
    public String productCode;
    public Boolean aoeRequired;
    public String gender;
    public String excludedStateCodes;
    public String maxAge;
    public String minAge;
    public String testType;
    public Boolean excludeFromRegistration;
    
    public ProductData(Product2 prod){
        this.productName = prod.Name;
        this.productCode = prod.ProductCode;
        this.aoeRequired = prod.AOE_required__c;
        this.gender = prod.Gender__c;
        this.excludedStateCodes = prod.Excluded_State_codes__c;
        this.maxAge = prod.Max_age__c;
        this.minAge = prod.Min_age__c;
        this.excludeFromRegistration = prod.Exclude_from_registration__c;
    }
}