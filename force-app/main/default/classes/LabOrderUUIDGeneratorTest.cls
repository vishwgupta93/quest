@IsTest
public class LabOrderUUIDGeneratorTest {
    
    @IsTest
    static void testUUIDGen() {
        // Prepare the test input
        LabOrderUUIDGenerator.LabOrderUUIDGeneratorInput input = new LabOrderUUIDGenerator.LabOrderUUIDGeneratorInput();
        input.token = 'testToken';
        
        List<LabOrderUUIDGenerator.LabOrderUUIDGeneratorInput> inputs = new List<LabOrderUUIDGenerator.LabOrderUUIDGeneratorInput>{ input };

        // Call the method
        List<LabOrderUUIDGenerator.LabOrderUUIDGeneratorOutput> outputs = LabOrderUUIDGenerator.createHubOrder(inputs);

        // Validate results
        System.assertEquals(1, outputs.size(), 'Expected 1 output record');
        
        // LabOrderUUIDGenerator.LabOrderUUIDGeneratorOutput output = outputs[0];
        
       
    }
}