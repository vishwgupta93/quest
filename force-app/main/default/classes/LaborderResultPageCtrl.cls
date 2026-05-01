public class LaborderResultPageCtrl {
    public String pdfdata{get;set;}
    public void getPDF(){
        String loid = ApexPages.currentPage().getparameters().get('loid');
        String result = (String)LabOrderResultsInteractiveInsightsUtil.fetchResults(loid, false);
        if(result.contains('Error')){
            pdfdata = result;
        } else {
            Blob decodedBlob = EncodingUtil.base64Decode((String)result);
            pdfdata = decodedBlob.toString(); 
        } 
    }
}