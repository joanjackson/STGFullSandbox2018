public class FieldWorkOrderDisplaySpecialInstructions {
	

	public WorkOrder wo {get;set;}
	Id cid;
	public List<Third_Party_Partner_Case_Instructions__mdt> lstinstructions {get;set;}
	String tppsiteid;

	
	
	public FieldWorkOrderDisplaySpecialInstructions(ApexPages.StandardController controller) {
    
       		 this.wo = (WorkOrder)controller.getRecord();
       		 WorkOrder fwo = [Select Id, CaseId, RecordTypeId, Third_Party_Partner_Name__c
       		                 from WorkOrder where Id = :wo.id LIMIT 1 ];

			 Id rectypeid = Utilities.RecordTypeNameToId('WorkOrder', 'Third Party FWO');
			 
			 if(fwo.recordtypeid == rectypeid && fwo.third_party_partner_name__c != null)
			 {
       		 	cid = fwo.CaseId;
       		 	tppsiteid = fwo.third_party_partner_name__c.left(7);
       		 	system.debug('cid is ' +cid);
       		 	lstinstructions = GetInstructions();
			 }
	
       		 
	}
	
	public List<Third_Party_Partner_Case_Instructions__mdt> GetInstructions()
	{
		
		
		//query the Third Party Partner Case Instructions custom metadata list to get all the instructions
		lstinstructions = [Select Instruction_Description__c, List_Order_del__c, Partner_Site_Id__c from
		                   Third_Party_Partner_Case_Instructions__mdt where Partner_Site_Id__c = :tppsiteid order by List_Order_del__c ];
		                   
		system.debug('lstinstructions size is ' +lstinstructions.size());                              

        return lstinstructions;
		
	}
    
}