public with sharing class LabOrderUUIDGenerator {
    public class LabOrderUUIDGeneratorInput {
        @InvocableVariable(label='Generate UUID' description='Generate UUID')
        public String token;
       }

    public class LabOrderUUIDGeneratorOutput {
        @InvocableVariable(label='UUID' description='UUID')
        public String uuid;
      }

    @InvocableMethod(label='Generates UUID For Lab Order' description='Generates UUID For Lab Order')
    public static List<LabOrderUUIDGeneratorOutput> createHubOrder(List<LabOrderUUIDGeneratorInput> inputs) {

        List<LabOrderUUIDGeneratorOutput> outputs = new List<LabOrderUUIDGeneratorOutput>();

        for(LabOrderUUIDGeneratorInput input : inputs)
        {
            LabOrderUUIDGeneratorOutput output = new LabOrderUUIDGeneratorOutput();

           
            String orderUUID = UUID.randomUUID().toString().toUpperCase();

           
            String formattedOrderUUID = orderUUID.substring(0, 6) + '-' + 
                                        orderUUID.substring(6, 10) + '-' + 
                                        orderUUID.substring(10);

            output.uuid = formattedOrderUUID;
            outputs.add(output);

        }
        
        return outputs;

    }
}