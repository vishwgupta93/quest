public class UserNameHelper {
 
    public class InputPrameters {
    
        @InvocableVariable(label='Last Name' description='Last Name')
        public String spaceslastName; 
    }
    
     public class OutParameters {
        
        @InvocableVariable(label='No Spaces Last Name' description='No Spaces Last Name')
        public String noSpacesLastName;
   }
    
     @InvocableMethod(label='Format Last Name' description='Format Last Name')
    public static List<OutParameters> formatLastName(List<InputPrameters> inputs){
        OutParameters OP = new OutParameters();
        List<OutParameters> lstOp = new List<OutParameters>();
        
        String spaceslastName = inputs[0].spaceslastName;
      
        OP.noSpacesLastName = spaceslastName.replaceAll('\\s+', '');
		lstOp.add(OP);
        return lstOp;
        
    }
}