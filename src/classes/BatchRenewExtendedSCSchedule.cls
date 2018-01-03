global class BatchRenewExtendedSCSchedule implements Schedulable //Schedulable
{
    global void execute(SchedulableContext sc)  //SchedulableContext
	  {
		
		//pull the list of extended warranty service contracts that have enddates of today, are still active,
		//and are extended warranty service contracts
		Date dttoday = system.today();
		List<ServiceContract> lstextwarrantysc = New List<ServiceContract>();
			
		lstextwarrantysc = [ Select Id, name, status, enddate, legal_contract_line_item__r.legal_contract__c,
		                     legal_contract_line_item__r.legal_contract__r.terminate_extended_warranty__c
		                     from ServiceContract where enddate = :dttoday and
		                     status = 'Active' and name like '%Extended Warranty%' and
		                     legal_contract_line_item__r.legal_contract__r.terminate_extended_warranty__c = false ];
		                  
		if(!lstextwarrantysc.IsEmpty())
		{ BatchRenewExtendedWarrantySC.RenewExtendedWarrantyServiceContracts(lstextwarrantysc);   }
		      

	  }
}//end global class\\

/*
To schedule this in the Salesforce cron, execute the following in Developer Console
Execute Anonymous window.  This will schedule the batch every night at 10 p.m.

        BatchRenewExtendedSCSchedule b = New BatchRenewExtendedSCSchedule();
     	String nightlyatten = '0 0 22 * * ? *';
    	system.schedule('Batch Renew Extended Warranties', nightlyatten, b);


*/