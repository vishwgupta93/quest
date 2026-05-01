@IsTest
public class UserNameHelperTest {
 @IsTest
 static void userNameUpdate()
 {

     
     List<UserNameHelper.InputPrameters> lst = new List<UserNameHelper.InputPrameters>();
     UserNameHelper.InputPrameters InputParameter = new UserNameHelper.InputPrameters();
     InputParameter.spaceslastName = 'Doe Last Name';
     lst.add(InputParameter);
      Test.startTest();
     UserNameHelper.formatLastName(lst);
      Test.stopTest();
 }
    
}