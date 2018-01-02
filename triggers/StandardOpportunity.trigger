trigger StandardOpportunity on Opportunity (before update, after insert, after update) 
{
    // Check for trigger processing blocked by custom setting
    try{ 
  		if(AppConfig__c.getValues('Global').BlockTriggerProcessing__c) {
        	return;
  		} else if(OpportunityTriggerConfig__c.getValues('Global').BlockTriggerProcessing__c) {
      		return; 
		}
    }
    catch (Exception e) {}
    
    //jjackson 5/23/2017 removed references to user profile to allow sys admin to run trigger code.
    //this change was necessary due to SpringCM project.
    
    //String profileName=[SELECT Id,Name FROM Profile WHERE Id=:Userinfo.getProfileId()].Name;
    
    Boolean runcode = true;
    
   // if(Test.isRunningTest())
   // {  runcode = true ;    }
    
   // if(profilename != Definitions.PROFILE_SystemAdmin)
   // {  runcode = true ;   }
    
    if(Trigger.isBefore)
    {
    	if(Trigger.isUpdate)
    	{ OpportunityTriggerLogic.opportunityPrimaryContactCheck(Trigger.new);   }
    }

    if(Trigger.isAfter) {
        
        //After Insert
        if(Trigger.isInsert) {
  			if(runcode == true)
               OpportunityTriggerLogic.opportunityPrimaryContactCheck(Trigger.new);
               OpportunityTriggerLogic.createContractRequest(Trigger.new, Trigger.oldMap); 
        }
        
        //After Update
        if(Trigger.isUpdate) {
      	 if(runcode == true )
      		
      		
      		if(Test.isRunningTest())
            {   OpportunityTriggerLogic.createContractRequest(Trigger.new, Trigger.oldMap); 
	            OpportunityTriggerLogic.CreateNetworkEngineeringCase(Trigger.new, Trigger.oldMap);
            }
            else
			{
			  if(triggerRecursionBlock.flag == true)
			  {	triggerRecursionBlock.flag = false;
	            OpportunityTriggerLogic.createContractRequest(Trigger.new, Trigger.oldMap); 
	            OpportunityTriggerLogic.CreateNetworkEngineeringCase(Trigger.new, Trigger.oldMap);
			  } 
			}
            
            OpportunityTriggerLogic.alertContractAdmins(Trigger.new, Trigger.oldMap);
            OpportunityTriggerLogic.updateSiteSurvey(Trigger.new, Trigger.oldMap);
 
        }
    }    
}