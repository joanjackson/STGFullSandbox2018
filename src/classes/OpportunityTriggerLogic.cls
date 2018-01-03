// *********************************************************************************************
// Version:      0.0.1
// Author:       Etherios
// Date Created: 06/17/2013
// Description:  Class for Opportunity TriggerLogic
// 
// Copyright 2013 Etherios All rights reserved. Customer confidential. Do not distribute.
//jjackson changes to contract request case and network engineering request May 2015
// *********************************************************************************************

public without sharing class  OpportunityTriggerLogic { 
    
    //******************************************************************************************
    //Author: Etherios
    //Parameters: Trigger.new, Trigger.oldMap
    //Description: Logic for creating or updating a Contract Request related to Opportunity
    //only one Active Contract Request should exist at one time per Opportunity
    //jjackson 4/16/2015 changing this to allow more than one case per opportunity as well
    //as creating a Network Engineering case, method createNetworkEngineeringCase  BUG-00459
    //******************************************************************************************
    public static void createContractRequest(List<Opportunity> opList, Map<Id,Opportunity> opOldMap)
    {
        Utilities.writeLog('**********    START', OpportunityTriggerLogic.class, 'createContractRequest', LoggingLevel.DEBUG); 
        
        //of the opportunities in trigger.new, pick out the ones that meet the criteria for creating a contract request case
        //if opOldMap is null (new insert), look for create_contract_request__c = true for opportunities that were cloned
        Set<Id> setcreatecases = New Set<Id>();
        List<Opportunity> lstcreatecases = New List<Opportunity>();
        List<Opportunity> lstupdateopps = New List<Opportunity>();
        for(Opportunity newop : opList)
        {   
        	if(opOldMap == null)  //if inserting
        	{
        		if(newop.Create_Contract_Request__c == true)
        		{   setcreatecases.add(newop.Id);    
        	    	lstcreatecases.add(newop);   
        		}
        	}
        	else
        	{
        		if(opOldMap.get(newop.id).Create_Contract_Request__c == false && newop.Create_Contract_Request__c == true)
        		{   setcreatecases.add(newop.Id);    
        	    	lstcreatecases.add(newop);   
        		}
        	}
        }
        

        String rectypename = 'Contract Request';
        //Need Record type for Case
        ID rtId = Utilities.RecordTypeNameToId('Case', Definitions.RECORDTYPE_ContractRequest);

        if(rtId == null)
        {
            Utilities.writeLog('OpportunityTriggerLogic:createContractRequest: Contract Request record type not found.', OpportunityTriggerLogic.class, 'createContractRequest', LoggingLevel.DEBUG); 
            opList[0].addError('Contract Request record type not found');
        }
        else
        {
            Utilities.writeLog('OpportunityTriggerLogic:createContractRequest: Record type found. ' + rtId, OpportunityTriggerLogic.class, 'createContractRequest', LoggingLevel.DEBUG); 
        }               
 
        //jjackson find all open cases related to the opportunity so they can be closed before creating a new one
        List<Case> contractRequestList = [SELECT Id, Opportunity__c,Status,OwnerId, Subject from Case WHERE Opportunity__c IN :setcreatecases AND Status != 'Cancelled'
                                          AND Status != 'Closed - Completed' AND RecordTypeId = :rtId];

        //Map to easily get the relevent Contract Request for Opportunity
        Map<Id,Case> contractRequestMap = new Map<Id,Case>(); 

        //jjackson Modify existing contract requests and change them to cancelled
        List<Case> crToModify = new List<Case>(); 
		List<CaseComment> commlist = new List<CaseComment>();
        //List of Contract Requests that must be inserted first before a Chatter Post can be made
        List<Case> crToInsertWithChatter = new List<Case>(); 

        //Map<Id, ConnectApi.FeedItemInput> crFeedItemMap = new Map<Id,ConnectApi.FeedItemInput>(); //Used to keep track of Chatter items for Insert

        List<FeedItem> fiList = new List<FeedItem>();
        Map<Id,Id> crUserMap = new Map<Id,Id>();
        
        for(Case cr : contractRequestList)
        {
            contractRequestMap.put(cr.Opportunity__c, cr);  //map contains opportunity id and related case
            system.debug('adding case record to contractRequestMap: ' +cr.Opportunity__c +', ' + cr.Id +', ' + cr.subject);
        }

        Utilities.writeLog('bl_Oppportunity:createContractRequest: Contract Request Map : '+contractRequestMap, OpportunityTriggerLogic.class, 'createContractRequest', LoggingLevel.DEBUG); 

        //Loop through to find Primary Contact Role
    	//jjackson get the opportunity record type and only run the rest of the code if it is for hospitality
    	Set<Id> hosopps = New set<Id>();
        for(Opportunity op : lstcreatecases)
        {	String opprectype = Utilities.RecordTypeIdtoName('Opportunity', op.RecordTypeId);
        	if(opprectype == 'Hospitality Opportunities')
			{	
        		hosopps.add(op.Id);
        	}
        }
        
        List<OpportunityContactRole> ocrList = [SELECT Contact.Email, OpportunityId, ContactId, Role from OpportunityContactRole WHERE OpportunityId IN :hosopps AND IsPrimary = true];
		Map<Id,OpportunityContactRole> ocrMap = new Map<Id,OpportunityContactRole>();
		
		system.debug('ocrlist size is ' +ocrList.Size());
		for(OpportunityContactRole ocr : ocrList)
		{
				ocrMap.put(ocr.OpportunityId,ocr);
				system.debug('Opportunity added to ocr map is ' + ocr.OpportunityId + ', ' +ocr.Role);
		}

        //Main loop through Opportunities
        for(Opportunity op: lstcreatecases)
        {
          if(op.Create_Contract_Request__c == true)
          {  //if there is no existing contract request case on the opportunity and box is checked go ahead and create case
          	if(!contractRequestMap.containsKey(op.Id))
            	{    crToInsertWithChatter.add(OpportunityTriggerLogic.addContract(op, rtId, ocrMap, rectypename));
            		system.debug('opportunity added to crToInsertWithChatter is ' + op.Name);
   
            	}
            
            //if there is an existing contract request and the box is checked, close the existing case and create a new one
            if(contractRequestMap.containsKey(op.Id) && op.Create_Contract_Request__c == true)
 
            	{   Case crExisting = contractRequestMap.get(op.Id); //get Existing Contract Request case to close it
					 
                	 crExisting.Status = 'Cancelled';
                 	 crToModify.add(crExisting);
                  	 crToInsertWithChatter.add(OpportunityTriggerLogic.addContract(op, rtId, ocrMap, rectypename));
                  	 system.debug('opportunity added to crExisting is ' +op.Name);
                } 
                
          }//end if create_contract_request__c == true
               
         } //end for loop
        Utilities.writeLog('OpportunityTriggerLogic:createContractRequest: Contract Requests to be Inserted/Updated : '+crToModify, OpportunityTriggerLogic.class, 'createContractRequest', LoggingLevel.DEBUG); 


        if(crToModify.size() > 0) 
        {
            try{
                update crToModify;
            }
            catch(DMLException e)
            {
                opList[0].addError('Cannot update Case related to Opportunities, error is :'+e.getMessage());  
            }
            
            for(Case crexisting : crToModify) 
            {
            //Chatter updates 
                system.debug('Case being cancelled is ' +crexisting.Id +', ' + crexisting.Subject);
                fiList.add(createContractRequestFeedItem(crexisting.Id)); 
                Utilities.writeLog('OpportunityTriggerLogic:createContractRequest: Chatter FeedItems to be Inserted : '+fiList, OpportunityTriggerLogic.class, 'createContractRequest', LoggingLevel.DEBUG); 
            }
			

        }
        
        if(crToInsertWithChatter.Size() > 0 )
        {
            try{ insert crToInsertWithChatter;  }
            catch(DMLException err)
            {  opList[0].addError('Cannot insert case related to Opportunities, error is : '  +err.getMessage());  }
        
        }
        

        if(fiList.size() > 0) {
              try { insert fiList;  }
              catch (DMLException ex)
              {   opList[0].addError('Cannot create feed item related to case, error is : ' +ex.getMessage());  }
            } //end if filist size      
            
 
		Utilities.writeLog('**********    END', OpportunityTriggerLogic.class, 'createContractRequest', LoggingLevel.DEBUG); 
        
  
   } //end method

     public static void createNetworkEngineeringCase(List<Opportunity> opList, Map<Id,Opportunity> opOldMap)
    {
        Utilities.writeLog('**********    START', OpportunityTriggerLogic.class, 'createNetworkEngineeringCase', LoggingLevel.DEBUG); 
        
        List<Opportunity> lstprocessopp = New List<Opportunity>();
        
        //determine which opportunities in the trigger require network engineering cases
        for( Opportunity newop : opList )
        {
        	if(newop.GIA_Network_Engineering_Request__c == true && opOldMap.get(newop.Id).GIA_Network_Engineering_Request__c == false)
        	{
        		lstprocessopp.add(newop);
        	}
        }
  
        String rectypename = 'Network Engineering';
       //Need Record type for Case
       //ID rtId = Utilities.RecordTypeNameToIdWithObject(Definitions.RECORDTYPE_Network_Engineering, 'Case');  DEPRECATED
       ID rtId = Utilities.RecordTypeNameToId('Case', Definitions.RECORDTYPE_Network_Engineering);
       	if(rtId == null)
       	{
            Utilities.writeLog('OpportunityTriggerLogic:createNetworkEngineeringCase: Network Engineering record type not found.', OpportunityTriggerLogic.class, 'createContractRequest', LoggingLevel.DEBUG); 
            opList[0].addError('Network Engineering case record type not found');
        }
        else
        {
            Utilities.writeLog('OpportunityTriggerLogic:createNetworkEngineeringCase: Record type found. ' + rtId, OpportunityTriggerLogic.class, 'createNetworkEngineeringCase', LoggingLevel.DEBUG); 
        }             
        
        Set<Id> hosopps = New set<Id>();
        for(Opportunity op : lstprocessopp)
        {	String opprectype = Utilities.RecordTypeIdtoName('Opportunity', op.RecordTypeId);
        	if(opprectype == 'Hospitality Opportunities')
			{	
        		hosopps.add(op.Id);
        	}
        }
       
        List<OpportunityContactRole> ocrList = [SELECT Contact.Email, OpportunityId, ContactId from OpportunityContactRole WHERE OpportunityId IN :hosopps AND IsPrimary = true];
        Map<Id,OpportunityContactRole> ocrMap = new Map<Id,OpportunityContactRole>();
        
        //Loop through to find Primary Contact Role
         for(OpportunityContactRole ocr : ocrList)
        	{
            	ocrMap.put(ocr.OpportunityId,ocr);
        	}
        List<Case> lstneteng = New List<Case>();
        List<FeedItem> fiList = New List<FeedItem>();
        
        for(Opportunity opp : lstprocessopp)
        {   
             Case neNew = addContract(opp,rtId,ocrMap,rectypename);
             lstneteng.add(neNew);
                          
             //Create new Chatter update to be inserted on the opportunity
              fiList.add(NECaseCreated(opp.Id));
              
              Utilities.writeLog('OpportunityTriggerLogic:createNetworkEngineeringCase: Network Engineering Requests to be Inserted: '+neNew, OpportunityTriggerLogic.class, 'createContractRequest', LoggingLevel.DEBUG); 
          
        }                              
        
 
        if(lstneteng.Size() > 0) {
            try{
                insert lstneteng;
            }
            catch(DMLException e)
            {
                opList[0].addError('Cannot insert Network Engineering Case related to Opportunities, error is :'+e.getMessage());  
            }
        }

        
        Utilities.writeLog('OpportunityTriggerLogic:createContractRequest: Chatter FeedItems to be Inserted : '+fiList, OpportunityTriggerLogic.class, 'createContractRequest', LoggingLevel.DEBUG); 
        if(fiList.size() > 0) {
            insert fiList;
        }
        

        Utilities.writeLog('**********    END', OpportunityTriggerLogic.class, 'createNetworkEngineeringCase', LoggingLevel.DEBUG); 
        
  } //end method
    
  
    
    private static Case addContract(Opportunity op, ID rtId, Map<Id,OpportunityContactRole> ocrMap, String caserectype)
    {
        Case crNew = new Case();
        crNew.AccountId = op.AccountId;
        //Calculate case subject
        
        If(caserectype == 'Contract Request')
        {  String subject = 'Contract Request - '+ op.Name;
           Integer subjectLength = subject.length() > 254? 254 : subject.length();
           crNew.Subject = subject.substring(0,subjectLength);
        
        	crNew.Case_Quota_Category__c = op.Quota_Categories__c;
			
        	if(ocrMap.containsKey(op.Id))
        	{
            	crNew.Client_Contact__c = ocrMap.get(op.Id).ContactId;
            	crNew.Recipient_Email__c = ocrMap.get(op.Id).Contact.Email;
        	}
        	//crNew.Management_Company__c = op.Account.Management_Group__c;  This is now a formula field that pulls mgmt co from account
        	crNew.RecordTypeId = rtId;
        	crNew.Description = op.Special_Instructions__c;
        	crNew.Opportunity__c = op.Id;
        	crNew.Status = 'Requested';
        	//****SGP 03/12/2014 - Changed per SOW0003 - Sonifi Enhancements - Sprint 5 - Req 8.2
        	//****crNew.OwnerId = queueId;   
        	crNew.OwnerId = op.OwnerId;
        }
        else
        {  
           String subject = 'Network Engineering Request - '+ op.Name;
           Integer subjectLength = subject.length() > 254? 254 : subject.length();
           crNew.Subject = subject.substring(0,subjectLength);
       	   //crNew.Management_Company__c = op.Account.Management_Group__c;
           crNew.RecordTypeId = rtId;
           crNew.Opportunity__c = op.Id;
           crNew.Status = 'Requested';
           crNew.OwnerId = op.OwnerId;
        }  
        
        return crNew;
    }

 
    public static void opportunityPrimaryContactCheck(List<Opportunity> opList)
    {
        List<ID> opListID = new List<ID>();
        String rectypename;
        Set<Id> hosopps = New Set<Id>();
        
        //jjackson May 2015 only check for primary contact if it is a hospitality opportunity
        for(Opportunity op: opList)
        {
        	
        	rectypename = Utilities.RecordTypeIdtoName('Opportunity', op.RecordTypeId);
        	system.debug('PrimaryContactCheck opportunity is ' +op.Name +', ' +rectypename);
        	if(rectypename == 'Hospitality Opportunities')
			{	
        		hosopps.add(op.Id);
        	}
            
        }
                //Loop through to find Primary Contact Role
        List<OpportunityContactRole> ocrList = [SELECT Contact.Email, OpportunityId, ContactId from OpportunityContactRole WHERE OpportunityId IN :hosopps AND IsPrimary = true];
        Map<Id,OpportunityContactRole> ocrMap = new Map<Id,OpportunityContactRole>();
        system.debug('in PrimaryContactCheck, ocrlist size is ' +ocrList.Size());
        
        If(!hosopps.IsEmpty())
        { for(OpportunityContactRole ocr : ocrList)
          {
            ocrMap.put(ocr.OpportunityId,ocr);
          }
          for(Opportunity o : opList)
          {
            //if(o.StageName== 'Approved Proposal' || o.StageName == 'Contract Sent' || o.StageName == 'Closed Won')
            //jjackson 7/28/2014  Remove stagename values except Closed Won and add check for Create_Contract_Request__c
            if(o.StageName=='Closed Won'||o.Create_Contract_Request__c==true||o.GIA_Network_Engineering_Request__c == true)
            {
            	system.debug('PrimaryContactCheck inside opportunity for loop ' +o.Name);
                if(!ocrMap.containsKey(o.Id) && hosopps.Contains(o.Id))
                {
                	o.Create_Contract_Request__c = false;  //prevent case from being created if this error is thrown
                    String link = '<a href =\"'+URL.getSalesforceBaseUrl().toExternalForm()+'/p/opp/ContactRoleEditUi/e?oppid='+o.Id+'&retURL=%2F'+o.Id+'\"> Click to Add </a>';
                    o.addError('Primary Contact must be added to the Contact Roles for this Opportunity '+link, false);                
                }
            }
          }
        }   
    }
	

    private static FeedItem createContractRequestFeedItem(Id parentId)
    {
        FeedItem fi = new FeedItem();
        fi.ParentId = parentId;
        fi.body = 'Contract Request was cancelled because a new one was created for the Opportunity.';
        return fi;      
    }
    
    private static FeedItem NECaseCreated(Id oppid)
    {
        FeedItem fi = new FeedItem();
        fi.ParentId = oppid;
        fi.body = 'Network Engineering Case was created for this opportunity on ' + system.today();
        return fi;      
    }
    
    
    public static void alertContractAdmins(List<Opportunity> opList, Map<Id,Opportunity> opOldMap)
    {
        Set<Id> opIds = new Set<Id>();
        for(Opportunity o : opList)
        {
          opIds.add(o.Id);
        }
        
        Set<String> contractStatuses = new Set<String>();
        
        for(String statusName : OpportunityRelatedContractAlertStatuses__c.getAll().keyset())
        {
            contractStatuses.add(statusName);
        }
        List<Contract__c> contracts = [SELECT Opportunity__c from Contract__c WHERE Opportunity__c IN : opIds AND Status__c IN :contractStatuses];
        
    
        Set<Id> opportunityWithContracts = new Set<Id>();
        for(Contract__c c : contracts)
        {
          opportunityWithContracts.add(c.Opportunity__c);
        }
        List<Opportunity> opChanged = new List<Opportunity>();  
    
        for(Opportunity o : opList)
        {
          if((o.Amount != opOldMap.get(o.Id).Amount) && opportunityWithContracts.contains(o.Id))
          {
            opChanged.add(o);
          }
        }
        
        //get Contract admins
        List<User> contractUsers = new List<User>();
        String contractManagerProfile = Utilities.ProfileNameToId('Contract Manager');
        String contractAdminSpecialistProfile = Utilities.ProfileNameToId('Contracts Admin Specialist');
        
        List<User> contractManager = [SELECT Id from User WHERE ProfileId = :contractManagerProfile];
        List<User> contractAdminSpecialist = [SELECT Id from User WHERE ProfileId = :contractAdminSpecialistProfile];
        String message = 'The following Opportunities have changed: \n ';
        for(Opportunity o : opChanged)
        {
            message+=o.Name+'\n';
        }
        contractUsers.addAll(contractManager);
        contractUsers.addAll(contractAdminSpecialist);
        Map<Id,String> chatterMap = new Map<Id,String>();
        for(User u : contractUsers)
        {
            chatterMap.put(u.Id,message);
        }                
        //Call another function here
        if(opChanged.size() > 0)
          ChatterUtilities.doChatterPosts(chatterMap);                                                                                                  
    }
 
 
    public static void updateSiteSurvey(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        
        //check to make sure new list is not empty
        if(newList == null || newList.isEmpty()) {
            throw new Exceptions.IllegalArgumentException('Opportunity new list is empty or missing');
        }
        
        //write log
        Utilities.writeLog('Update site survey for ' + newList.size() + ' opportunities.',
                            OpportunityTriggerLogic.class, 'updateSiteSurvey', LoggingLevel.DEBUG);
       // Only change the rooms with a status of 
       //   Schedule Survey
       //   Scheduled
       //   In Progress
       //   On Hold
       // on the Site Survey
            
       //**********************************************
       // Process flow
       //  Gather a list of all Opportunity IDs
       //   soql of Site_survey__c for all matching Opportunity Ids
       //   Update each Site_survey__c number of rooms field from the Opportunity 
       //     when the status of the Site_survey is equal to above.
       //   
       //**********************************************

        Set<Id> opIds = new Set<Id>();
        
        // Gather all the Opportunities where the Old and New version's Room numbers change
        for (Opportunity opList: newList) {
            if(oldMap != null) {
                if(opList.of_Rooms_Opportunity__c != oldMap.get(opList.id).of_Rooms_Opportunity__c) { 
                    opIds.add(opList.Id);
                }
            } else {
                opIds.add(opList.Id);
            }
        }
        
        
        //query for the site surveys that are attached to the opportunity
        List<Site_Survey__c> siteSurveyList = [SELECT 
                                                  Id, 
                                                  Opportunity__c, 
                                                  Number_of_Rooms__c, 
                                                  Status__c 
                                               FROM 
                                                  Site_Survey__c 
                                               WHERE 
                                                  Opportunity__c IN :opIds 
                                                  AND Status__c IN :Opportunity_Site_Survey_Update_Status__c.getAll().keySet()];

        
        List<Opportunity> oppList = [SELECT 
                                        Id, 
                                        of_Rooms_Opportunity__c 
                                     FROM 
                                        Opportunity 
                                     WHERE 
                                        Id IN :opIds];

        Utilities.writeLog('Update site survey Sitesurvey list '+siteSurveyList+ ' size '+siteSurveyList.size(),
                            OpportunityTriggerLogic.class, 'updateSiteSurvey', LoggingLevel.DEBUG);

        Utilities.writeLog('Update site survey Opportunity list '+oppList + ' size '+oppList.size(),
                            OpportunityTriggerLogic.class, 'updateSiteSurvey', LoggingLevel.DEBUG);
        
        List<Site_Survey__c> updateSiteSurveys = new List<Site_Survey__c>();                   
        for (Opportunity upopList: oppList) {
            Utilities.writeLog('Update site opportunity ID ..........'+upoplist.id,
                            OpportunityTriggerLogic.class, 'updateSiteSurvey', LoggingLevel.DEBUG);

           for (Site_Survey__c siteitem : siteSurveyList)
           {
              if  (siteitem.Opportunity__c == upoplist.id) 
              {
                 updateSiteSurveys.add(New Site_Survey__c(Id=siteItem.Id, 
                                                          Number_of_Rooms__c=upoplist.of_Rooms_Opportunity__c));       
                 Utilities.writeLog('Update site Sitesurvey ID ..........'+siteitem.id+' '+siteitem.Opportunity__c+ ' status '+siteitem.Status__c+'  rooms '+siteitem.Number_of_Rooms__c,
                            OpportunityTriggerLogic.class, 'updateSiteSurvey', LoggingLevel.DEBUG);
                 
              }
           }
        }                            
          
        if(updateSiteSurveys.size() > 0){
            update updateSiteSurveys;
        }     
        
        Utilities.writeLog('Exit Update site survey..........total '+updateSiteSurveys.size(),
                            OpportunityTriggerLogic.class, 'updateSiteSurvey', LoggingLevel.DEBUG);
        
    }
    
    
    /*
    private ConnectApi.FeedItemInput createChatterPostInputForContractRequest(Id crId)
    {
        ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
        messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
        if(Schema.SObjectType.Group.getSobjectType() != crId.getSobjectType())
        {
            ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
            mentionSegment.id = crId;
            messageInput.messageSegments.add(mentionSegment);
        }
        textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = ' Contract Request was cancelled due to updates to Opportunity.  A new Contract Request was created';
        messageInput.messageSegments.add(textSegment);
        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        input.body = messageInput;
        return input;
    }
   */
    
    /*
     ***************************************************************************************
            Jim Johnson - Moved Functionality to Custom Button on the Opportunity
            Method code has been moved to the CustomOpportunityLogic
     ***************************************************************************************
    
    public static void createSiteSurvey(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        
        //check to make sure new list is not empty
        if(newList == null || newList.isEmpty()) {
            throw new Exceptions.IllegalArgumentException('Opportunity new list is empty or missing');
        }
        
        //write log
        Utilities.writeLog('Creating site survey for ' + newList.size() + ' opportunities.',
                            CustomOpportunityLogic.class, 'createSiteSurvey', LoggingLevel.DEBUG);
        
        //initialize var
        Site_Survey__c site;
        List<Opportunity> createList = new List<Opportunity>();
        List<Site_Survey__c> upsertList = new List<Site_Survey__c>();
        List<Site_Survey__c> siteSurveyList = new List<Site_Survey__c>();
        Set<String> oppIds = new Set<String>();
        Map<Id, Site_Survey__c> oppId2SiteSurveyMap = new Map<id, Site_Survey__c>();
        String siteSurvey = '';
        String desktopSurvey = '';
        
        //query for the queue
        QueueSobject groupQueue = [SELECT id,QueueId FROM QueueSobject WHERE SobjectType = 'Site_Survey__c'  AND Queue.DeveloperName = 'Installs_Site_Surveys' limit 1]; 
        
        //query for the record type ids
        List<RecordType> recordTypes = [SELECT SobjectType, Id, DeveloperName From RecordType WHERE SobjectType = 'Site_Survey__c' ];
        //set the record type ids
        for(RecordType rec : recordTypes){
            if(rec.DeveloperName == 'Site_Survey'){
                siteSurvey = rec.id;
            } else if(rec.DeveloperName == 'Desktop_Review') {
                desktopSurvey = rec.id;
            }
        }
        System.debug('Site survey record id is ' + siteSurvey + '. Desktop is ' + desktopSurvey);
        
        for(Opportunity opp : newList) {
            if(oldMap != null) {
                //check to see if the status has changed or initial value is end status
                if((opp.stageName =='Site Survey Order Approved' && oldMap.get(opp.id).stageName != 'Site Survey Order Approved') || (opp.stageName == 'Desktop Review Required' && oldMap.get(opp.id).stageName != 'Desktop Review Required')) {                                                                     
                    createList.add(opp);
                    oppIds.add(opp.id);
                }
            } else if(opp.stageName == 'Site Survey Order Approved' || opp.stageName == 'Desktop Review Required') {
                createList.add(opp);
            }
        }
        System.debug('Create list is ' + createList);
        
        //query for the site surveys that might be attached to the opportunity already
        siteSurveyList = [SELECT id, RecordTypeId, Opportunity__c FROM Site_Survey__c WHERE Opportunity__c IN :oppIds];
        System.debug('Site survey list is ' + siteSurveyList);
        
        //map opp id to site survey object
        for(Site_Survey__c s : siteSurveyList){
            oppId2SiteSurveyMap.put(s.Opportunity__c, s);
        }
        
        for(Opportunity opp : createList) {
            if(oppId2SiteSurveyMap.containsKey(opp.id)){
                if(opp.StageName == 'Desktop Review Required'){
                    oppId2SiteSurveyMap.get(opp.id).RecordTypeId = desktopSurvey;
                } else {
                    oppId2SiteSurveyMap.get(opp.id).RecordTypeId = siteSurvey;
                }
                upsertList.add(oppId2SiteSurveyMap.get(opp.id));
            } else {
                site = new Site_Survey__c();
                //initialize the fields
                site.Opportunity__c = opp.id;
                site.Site__c = opp.Account_ID__c;
                site.Number_of_Rooms__c = opp.of_Rooms_Opportunity__c;
                if(opp.StageName == 'Desktop Review Required'){
                    site.RecordTypeId = desktopSurvey;
                } else {
                    site.RecordTypeId = siteSurvey;
                }
                upsertList.add(site);
            }
        }
        System.debug('Upsert List is ' + upsertList);
        
        //loop through Site Surveys and if not created then set owner to queue; if not then leave it alone
        for(Site_Survey__c s : upsertList){
            s.OwnerId = groupQueue.QueueId;
        }
        System.debug('Upsert List is ' + upsertList);
        
        //if size of insert list is not 0 then insert the list
        if(upsertList.size() > 0) {
            try {
                upsert upsertList;
            } catch( Exception e) {
                Utilities.writeLog('Unable to upsert site survey to opportunities with details: ' +e.getMessage(),
                OpportunityTriggerLogic.class, 'createSiteSurvety', LoggingLevel.DEBUG);
            }
        }
    }
    */
}