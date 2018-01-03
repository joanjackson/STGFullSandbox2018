@IsTest
public with sharing class OpportunityProgrammingHierarchyTest {

	static testMethod void testBasicHierarchy()
	{
		Product2 p = new Product2(Name = 'TestProduct', ProductCOde = '1234');
		insert p;
		Account a = new Account(Name = 'testAccount');
		insert a;
		Opportunity o = new Opportunity(AccountId = a.Id, Name = 'TestOp', StageName = 'Prospect', CloseDate = Date.today());
		insert o;
		List<Programming__c> pList = new List<Programming__c>();
		Programming__c prg = new Programming__c();
		prg.Product__c = p.id;
		pList.add(prg);
		insert pList;
		
		//Create contracts
		Contract__c c = new Contract__c(Opportunity__c = o.Id, Contract_Type__c = 'FTG', Status__c = 'Draft', Account_Name__c = a.Id);
		insert c;
		
		PageReference pr = Page.OpportunityProgrammingHeirarchy; 
		pr.getParameters().put('contractId',c.id);
		List<ID> programmingList = new List<ID>();
		pr.getParameters().put('selectedKeys',JSON.serialize(programmingList));
		Test.setCurrentPageReference(pr);
		Test.startTest();
		
		
		OpportunityProgrammingHeirarchyExtension controller = new OpportunityProgrammingHeirarchyExtension(new ApexPages.StandardController(o));
		controller.loadContracts();
		controller.saveTasks();
	}

}