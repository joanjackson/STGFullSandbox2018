public with sharing class CreateTestRecords {
	
	public static Account DefaultSupportOfficeAccount()
	{
		system.debug('Creating DefaultSupportOfficeAccount');
		
		Id suppofficerectype = Utilities.RecordTypeNameToId('Account', 'Support Office');
		
		Account so = New Account(Name = 'Midwest Zone 19 Test', Type = 'Support Office', recordtypeid = suppofficerectype,
		                         account_status__c = 'Active', Major_Account_Flag__c='None', phone = '9998881234',
		                         fax = '8887775555', physical_street_address_line_1__c = '225 Testing Street',
		                         physical_city__c = 'Sioux Falls', physical_state__c = 'SD',
		                         physical_postal_code__c = '57104', Time_Zone__c = 'America/Chicago',
		                         site_id_ext_id__c = '807766A', Industry='Service', Region__c = 'Western',
		                         Area__c = 'Western-US', Zone__c = 'Denver');
		
		insert so;
		return so;
	}
	
	//pass in the id of a support office account to link the primary engineer to the support office;
	//you must create a supportofficemember linked to support office account in order to dispatch a
	//support case during a test
	public static SupportOfficeMember__c CreatePrimaryEngineer(Id suppofficeid)
	{
		Id myid = UserInfo.getUserId();
		
		SupportOfficeMember__c member = New SupportOfficeMember__c(SupportOffice__c = suppofficeid, user__c = myid,
		                                role__c = 'Primary Engineer');
		
		insert member;
		return member;
		
	}
	
	
	public static Account DefaultHospitalityAccount()
	{	
		system.debug('Creating DefaultHospitalityAccount');
		
		Id acctrectype = Utilities.RecordTypeNameToId('Account', 'Hospitality Site');
		
		Account soa = DefaultSupportOfficeAccount();
		
		Account a = New Account(Name = 'Test Hotel Account', Type = 'Hotel Site', recordtypeid = acctrectype,
		                         account_status__c = 'Active', Major_Account_Flag__c='None', phone = '9958881234',
		                         fax = '8817775555', physical_street_address_line_1__c = '222 Testing Street',
		                         physical_city__c = 'Sioux Falls', physical_state__c = 'SD',
		                         physical_postal_code__c = '57104', Time_Zone__c = 'America/Chicago',
		                         of_rooms__c = 100, support_office__c = soa.id);
		                         
		insert a;
		return a;                         
	}
	
	public static Account DefaultThirdPartyContractedAccount()
	{	
		system.debug('Creating DefaultThirdPartyContractedAccount');
		
		Id acctrectype = Utilities.RecordTypeNameToId('Account', 'Third Party Contracted Service');
		
		
		Account a = New Account(Name = 'Test Third Party Location', recordtypeid = acctrectype,
		                         account_status__c = 'Active', Major_Account_Flag__c='None', phone = '9998871234',
		                         fax = '8837775555', physical_street_address_line_1__c = '223 Testing Street',
		                         physical_city__c = 'Sioux Falls', physical_state__c = 'SD',
		                         physical_postal_code__c = '57104', Time_Zone__c = 'America/Chicago',
		                         of_rooms__c = 100);
		                         
		insert a;
		return a;                         
	}
	
	public static Account DefaultThirdPartyAccount()
	{	
		system.debug('Creating DefaultThirdPartyAccount');
		
		Id acctrectype = Utilities.RecordTypeNameToId('Account', 'Third Party');
		
		
		Account a = New Account(Name = 'Third Party Company', Type = 'Partner', recordtypeid = acctrectype,
		                         account_status__c = 'Active', Major_Account_Flag__c='None', phone = '9998861234',
		                         fax = '8897775555', physical_street_address_line_1__c = '221 Testing Street',
		                         physical_city__c = 'Sioux Falls', physical_state__c = 'SD',
		                         physical_postal_code__c = '57104', Time_Zone__c = 'America/Chicago',
		                         service_response_email__c = 'jjackson@sonifi.com');
		                         
		insert a;
		return a;                         
	}
	
	public static Account_Third_Party_Partner__c LinkAccountToPartner(Id acctid, Id partnerid)
	{
		Account_Third_Party_Partner__c atpp = New Account_Third_Party_Partner__c(Related_Account__c = acctid,
		                                      Third_Party_Partner_Account__c = partnerid, Third_Party_Unique_id__c = 'abc12345');
		                                      
		insert atpp;
		
		return atpp;                                      
	}
	
	public static Case DefaultSupportCase()
	{
		system.debug('Creating DefaultSupportCase');
		
		Id suppcaseid = Utilities.RecordTypeNameToId('Case', 'Support Case');
		Account acc = DefaultHospitalityAccount();
		Case newcase = New Case(Subject='Test Subject', accountid=acc.id, status='Open', priority='Low',
		                        Origin='Customer Incoming Call', recordtypeid=suppcaseid,
		                        case_product_type__c = 'Interactive', Issue_Type__c = 'Connectivity',
		                        Issue_Sub_Type__c = 'Circuit', Issue_Details__c = 'Circuit - Hotel',
		                        Customer_Name__c = 'Joe Blow', Customer_Role__c = 'Engineer');
		
		insert newcase;
		return newcase;
		
	}
	
	//create a contracted field service case by passing in the account id of the third party contracted service
	//account and the id of the account third party partner record related to that account
	public static Case DefaultContractedFieldServiceCase(Id acctid, Id atppid)
	{
		Id concaseid = Utilities.RecordTypeNameToId('Case', 'Contracted Field Service');
		
		Case cfscase = new Case(Subject = 'Testing Contracted Field Service Case', AccountId = acctid, Status = 'Open',
		                       Priority = 'Low', Origin = 'Third Party Field Service', Case_Product_Type__c = 'Interactive',
		                       Issue_Type__c = 'Software', Issue_Sub_Type__c = 'Content', Issue_Details__c = 'Local Guide',
		                       Third_Party_Partner__c = atppid, Partner_Ticket_Number__c = '789567', recordtypeid = concaseid);
		                       
	    insert cfscase;
	    return cfscase;	                       
	}
	
	
	public static WorkOrder DefaultFieldServiceWO(Id acctid, Id caseid)
	{
		Id fwoid = Utilities.RecordTypeNameToId('WorkOrder', 'FWO');
		
		Datetime thisdate = system.now();
		
		WorkOrder fwo = New WorkOrder(recordtypeid = fwoid, date__c = thisdate, AccountId = acctid, Caseid = caseid,
		                              priority = 'Low', Status = 'New', signature_name__c = 'Joe Blow', Signature_Date__c = thisdate,
		                              customer_title__c = 'Manager', customer_email__c = 'jjackson@sonifi.com',
		                              Invoice_Summary__c = 'This is a test of a regular field work order' );
		                              
		insert fwo;
		return fwo;
	}
	
	public static WorkOrder DefaultThirdPartyFWO(Id acctid, Id caseid)
	{
		Id fwoid = Utilities.RecordTypeNameToId('WorkOrder', 'Third Party FWO');
		
		Datetime thisdate = system.now();
		
		WorkOrder fwo = New WorkOrder(recordtypeid = fwoid, date__c = thisdate, AccountId = acctid, Caseid = caseid,
		                              priority = 'Low', Status = 'New', signature_name__c = 'Joe Blow', Signature_Date__c = thisdate,
		                              customer_title__c = 'Manager', customer_email__c = 'jjackson@sonifi.com',
		                              Invoice_Summary__c = 'This is a test of a third party fwo' );
		                              
		insert fwo;
		return fwo;
	}
    
}