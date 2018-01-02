@isTest
public with sharing class OpportunityTriggerLogicTest 
{
    static testMethod void opportunityContractRequest()
    {

        System.debug(LoggingLevel.DEBUG,'OpportunityTriggerLogicTest opportunityNoRelatedContractRequest Test .  **********    START');
 
        List<Account> accounts = DataGenerator.createAccounts(1, true);
        List<Contact> contacts = DataGenerator.createContacts(accounts[0], 1, true);
        List<Opportunity> opportunities = DataGenerator.createOpptys(accounts[0], 1, true);
        
        Opportunity o = opportunities[0];
        
        OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId=o.Id,ContactId=contacts[0].Id,IsPrimary=true);
        insert ocr;
		
		//check the contract request box on the opportunity and run the trigger by doing an update -- this will create a case
		//then uncheck it and check it again to verify the first case closes and the 2nd case is created.
		
		test.startTest();
		
		Opportunity Opp = [Select Id, Create_Contract_Request__c, GIA_Network_Engineering_Request__c, AccountId from Opportunity where Id = :o.Id LIMIT 1];
		Opp.Create_Contract_Request__c = true;
		update Opp;
		
		List<Case> newcaselist = New List<Case>();
		newcaselist = [Select Id, Status, Opportunity__c from Case ];
		
		system.debug('newcaselist size is ' +newcaselist.size());
		
		Opportunity updo = [ Select Id, Create_Contract_Request__c from Opportunity where Id = :o.id LIMIT 1 ];
		updo.Create_Contract_Request__c = false;
		update updo;
		
		Opportunity updateopp = [ Select Id, Create_Contract_Request__c from Opportunity where Id = :o.Id LIMIT 1 ];
		updateopp.Create_Contract_Request__c = true;
		
		test.stopTest();
		
		List<Case> caselist = New List<Case>();
		caselist = [ Select Id, Status from Case ];
		
		system.debug('caselist size is ' +caselist.size());
		//now there should be 2 contract request cases, one closed and one open
		
		system.assert(caselist.size() > 0);
		
		Boolean closedcase = false;
		Boolean opencase = false;
		
		for(Case reccase : caselist)
		{
		    if(reccase.Status == 'Requested')
			{  opencase = true;   }
			else
			{  closedcase = true; }
		}
		
		system.assert(opencase);
		system.assert(closedcase);
	
    }//end contract request test
    
    static testMethod void opportunityNetworkEngineeringCase()
    {

        System.debug(LoggingLevel.DEBUG,'OpportunityTriggerLogicTest opportunityNetworkEngineeringCase  **********    START');
 
        List<Account> accounts = DataGenerator.createAccounts(1, true);
        List<Contact> contacts = DataGenerator.createContacts(accounts[0], 1, true);
        List<Opportunity> opportunities = DataGenerator.createOpptys(accounts[0], 1, true);
        
        Opportunity o = opportunities[0];
        
        OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId=o.Id,ContactId=contacts[0].Id,IsPrimary=true);
        insert ocr;
		
		//check the GIA Network Engineering Request box on the opportunity and run the trigger by doing an update -- this will create a case
			
		test.startTest();
		
		Opportunity Opp = [Select Id, GIA_Network_Engineering_Request__c, AccountId from Opportunity where Id = :o.Id LIMIT 1];
		Opp.GIA_Network_Engineering_Request__c = true;
		update Opp;
		
		List<Case> newcaselist = New List<Case>();
		newcaselist = [Select Id, Status, Opportunity__c from Case ];
		
		system.debug('newcaselist size is ' +newcaselist.size());

		
		test.stopTest();
		
		List<Case> caselist = New List<Case>();
		caselist = [ Select Id, Status from Case ];
		
		system.debug('caselist size is ' +caselist.size());
		//now there should be 1 network engineering request case
		
		system.assert(caselist.size() > 0);
		
		Boolean opencase = false;
		
		for(Case reccase : caselist)
		{
		    if(reccase.Status == 'Requested')
			{  opencase = true;   }
		}
		system.assert(opencase);
	
	
    }//end network engineering request test
 
   /******************************************************************************************************
    ****************************Update Opportunity total number Rooms TEST METHODS*********************************************
    *******************************************************************************************************/

    static testMethod void UpdateTotalNoRoomsSiteSurveytest()
    {

        //create test data
        List<Opportunity_Site_Survey_Update_Status__c> statusSettings = new List<Opportunity_Site_Survey_Update_Status__c>();
        statusSettings.add(new Opportunity_Site_Survey_Update_Status__c(Name='Schedule Survey'));
        statusSettings.add(new Opportunity_Site_Survey_Update_Status__c(Name='Scheduled'));
        statusSettings.add(new Opportunity_Site_Survey_Update_Status__c(Name='In Progress'));
        statusSettings.add(new Opportunity_Site_Survey_Update_Status__c(Name='On Hold'));
        
        insert statusSettings;
        
        //Acquire test user of Profile Admin Manager
        Profile pfl = [select id from profile where name='System Administrator'];
        String randomName = 'testUser'+Math.Random()+'test'+Math.random()+'@sonifitest.com';

        System.debug(LoggingLevel.DEBUG,'OpportunityTriggerLogicTest Update Total rooms Test .  **********    START');  
       
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        
        User testUser =  DataGenerator.createUsers(Definitions.PROFILE_SystemAdmin, 1, false).get(0);

        testUser.email=randomName;
        testUser.emailencodingkey='UTF-8'; 
        testUser.lastname='Testing';
        testUser.languagelocalekey='en_US';
        testUser.localesidkey='en_US'; 
        testUser.profileid = pfl.Id;  
        testUser.country='United States'; 
        testUser.CommunityNickname = 'u1';
        testUser.timezonesidkey='America/Los_Angeles'; 
        testUser.username=randomName;
        insert testUser;
        
        Opportunity opp = DataGenerator.createOpptys(acc, 1, false).get(0);
        Opportunity opp1 = DataGenerator.createOpptys(acc, 1, false).get(0);
        Opportunity opp2 = DataGenerator.createOpptys(acc, 1, false).get(0);

        // Asset ass1;
        //Asset ass2;

        Site_survey__c ssvy1; 
        Site_survey__c ssvy2;
        Site_survey__c ssvy3;


        system.runAs(testUser)
        {        
            //Create Account and Asset
          //  ass1 = new Asset();
           // ass1.AccountId = acc.Id;
           // ass1.Name = 'Part Inventory Test Asset Install';
           // ass1.Status = 'Pending Install';
           // insert ass1;
            
            
            //create on update
            opp.of_Rooms_Opportunity__c= 50;
            opp.CPO_Approved__c = true;
            opp.Type_of_Assessment__c = 'No Charge Desktop Review';
            opp.StageName = 'Desktop Review Required';

            opp1.of_Rooms_Opportunity__c= 12;
            opp1.CPO_Approved__c = true;
            opp1.Type_of_Assessment__c = 'No Charge Desktop Review';
            opp1.StageName = 'Desktop Review Required';

        
            //make sure they do not create two site surveys
//            opp2.of_Rooms_Opportunity__c = 50;
//            opp2.CPO_Approved__c = true;
//            opp2.Type_of_Assessment__c = 'No Charge Desktop Review';
//            opp2.StageName = 'Site Survey Order Approved';
            Test.startTest();

//            insert opp2;
            
            insert opp1;

            insert opp;
            // update opp1;

            ssvy1 = new Site_survey__c();
            ssvy1.Number_of_Rooms__c= 20;        
            // ssvy1.AccountId__c = acc.Id;
            ssvy1.Status__c = 'Schedule Survey';
            ssvy1.Opportunity__c = opp.id;        
            insert ssvy1;
        
            ssvy2 = new Site_survey__c();
            ssvy2.Number_of_Rooms__c= 20;        
            // ssvy2.AccountId__c = acc.Id;
            ssvy2.Status__c = 'Schedule Survey';
            ssvy2.Opportunity__c = opp1.id;        
            insert ssvy2;
        
//            ssvy3 = new Site_survey__c();
//            ssvy3.Number_of_Rooms__c = 20;        
//            ssvy3.Status__c = 'Schedule Survey';
//            ssvy3.Opportunity__c = opp2.id;        
//            insert ssvy3;

//            opp2.of_Rooms_Opportunity__c = 75;
//            update opp2;
        
            opp.of_Rooms_Opportunity__c= 75;
            update opp;

            opp1.of_Rooms_Opportunity__c= 150;
            update opp1;
                
            Test.stopTest();
        
            List<Site_Survey__c> sites = [SELECT id, Number_of_Rooms__c FROM Site_Survey__c];
            System.debug(LoggingLevel.DEBUG,'OpportunityTriggerLogicTest Update Total number of rooms Test .  ********** '+sites.size());
            system.assertEquals(2, sites.size());
            Integer inx = 0;
            for (Site_Survey__c ssv : sites) {
                System.debug(LoggingLevel.DEBUG,'OpportunityTriggerLogicTest Total number of rooms Test .  **********   test results '+ssv.Number_of_Rooms__c +' id '+ssv.id);
                if (ssv.id == ssvy1.id)
                {               
                  system.assertEquals(75 , ssv.Number_of_Rooms__c);
                } else {
                  system.assertEquals(150 , ssv.Number_of_Rooms__c);
                }   
            }
        }
   }


    /******************************************************************************************************
    ****************************CREATE SITE SURVEY TEST METHODS*********************************************
    *******************************************************************************************************/
/* NOT USED
    static testMethod void createSiteSurveySucess(){
        //create test data
        System.debug(LoggingLevel.DEBUG,'OpportunityTriggerLogicTest createSiteSurveySucess Test .  **********    START');
        
        //create test data
        List<Opportunity_Site_Survey_Update_Status__c> statusSettings = new List<Opportunity_Site_Survey_Update_Status__c>();
        statusSettings.add(new Opportunity_Site_Survey_Update_Status__c(Name='Schedule Survey'));
        statusSettings.add(new Opportunity_Site_Survey_Update_Status__c(Name='Scheduled'));
        statusSettings.add(new Opportunity_Site_Survey_Update_Status__c(Name='In Progress'));
        statusSettings.add(new Opportunity_Site_Survey_Update_Status__c(Name='On Hold'));
        
        
        Account acc = DataGenerator.createAccounts(1, true).get(0);
        System.debug('Account data is ' + acc);
        Opportunity opp = DataGenerator.createOpptys(acc, 1, false).get(0);
        Opportunity opp1 = DataGenerator.createOpptys(acc, 2, true).get(0);
        Opportunity opp2 = DataGenerator.createOpptys(acc, 1, false).get(0);
       
        //set the fields ready for creation
        //create on insert
        opp.of_Rooms_Opportunity__c = 50;
        opp.CPO_Approved__c = true;
        opp.Type_of_Assessment__c = 'No Charge Desktop Review';
        opp.StageName = 'Site Survey Order Approved';
        
        //create on update
        opp1.of_Rooms_Opportunity__c= 50;
        opp1.CPO_Approved__c = true;
        opp1.Type_of_Assessment__c = 'No Charge Desktop Review';
        opp1.StageName = 'Desktop Review Required';
        
        //make sure they do not create two site surveys
        opp2.of_Rooms_Opportunity__c = 50;
        opp2.CPO_Approved__c = true;
        opp2.Type_of_Assessment__c = 'No Charge Desktop Review';
        opp2.StageName = 'Site Survey Order Approved';
        insert opp2;
        opp2.of_Rooms_Opportunity__c = 20;
        
        Test.startTest();
        insert opp;
        update opp1;
        update opp2;
        Test.stopTest();
        
        List<Site_Survey__c> sites = [SELECT id FROM Site_Survey__c];
        System.debug(LoggingLevel.DEBUG,'OpportunityTriggerLogicTest createSiteSurveySucess Test .  ********** sites size  '+sites.size());
        system.assertEquals(3, sites.size());
        System.debug(LoggingLevel.DEBUG,'OpportunityTriggerLogicTest createSiteSurveySucess Test .  **********    START');
   }
 */  
}