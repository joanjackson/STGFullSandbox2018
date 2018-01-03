@isTest
private class CreateTestRecordsTest {

    static testMethod void testSupportCaseandAccounts() {
        
        Case newcase = CreateTestRecords.DefaultSupportCase();
        
        Account contractedacct = CreateTestRecords.DefaultThirdPartyContractedAccount();
        Account thirdpartyacct = CreateTestRecords.DefaultThirdPartyAccount();
        Account_Third_Party_Partner__c atpp = CreateTestRecords.LinkAccountToPartner(contractedacct.id, thirdpartyacct.id);
        
        Case c = [Select Id, Account.Support_Office__c from Case where Id = :newcase.id LIMIT 1 ];
        
        SupportOfficeMember__c member = CreateTestRecords.CreatePrimaryEngineer(c.account.support_office__c);
        
        Case contractedcase = CreateTestRecords.DefaultContractedFieldServiceCase(contractedacct.id, atpp.id);
        
        WorkOrder fwo = CreateTestRecords.DefaultFieldServiceWO(newcase.accountid, newcase.id);
        
        WorkOrder tpfwo = CreateTestRecords.DefaultThirdPartyFWO(contractedacct.id, contractedcase.id);
        
        
        system.assert(newcase.subject == 'Test Subject');
        
    }
}