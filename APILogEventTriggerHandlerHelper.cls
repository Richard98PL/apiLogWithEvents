public without sharing class APILogEventTriggerHandlerHelper {
    public void insertAPILogs(List<API_Log_Event__e> events){
        List<API_Log__c> logs = new List<API_Log__c>();
        for(API_Log_Event__e event : events){
            logs.add(parseLog(event));
        }
        List<Database.SaveResult> results = Database.insert(logs, false);
    }

    private API_Log__c parseLog(API_Log_Event__e event) {
        API_Log__c log = new API_Log__c();

        log.DML_Operation__c = event.DML_Operation__c;
        log.External_Id__c = event.External_Id__c;
        log.External_Field_API_Name__c = event.External_Field_API_Name__c;
        log.External_System__c = event.External_System__c;
        log.Is_Custom__c = event.Is_Custom__c;
        log.Main_API_Name__c = event.Main_API_Name__c;
        log.Payload__c = event.Payload__c;
        log.Response__c = event.Response__c;
        log.Salesforce_Id__c = event.Salesforce_Id__c;
        log.Status__c = event.Status__c;
        log.Status_Code__c = event.Status_Code__c;
        log.Type__c = event.Type__c;
        log.Relationship_API_Name__c = event.Relationship_API_Name__c;
        log.URL__c = event.URL__c;
        log.Method__c = event.Method__c;
        log.DML_Error__c = event.DML_Error__c;
        log.DML_Error_Message__c = event.DML_Error_Message__c;

        Boolean wasLookupSuccess = false;
        try{
            if(String.isNotBlank(event.Relationship_API_Name__c) && String.isNotBlank(event.Salesforce_Id__c)){
                log.put(event.Relationship_API_Name__c, event.Salesforce_Id__c);
                wasLookupSuccess = true;
            }
        }catch(Exception e){
            System.debug(e.getMessage());
            System.debug(e.getCause());
        }

        try{
            if(!wasLookupSuccess && String.isNotBlank(event.Relationship_API_Name__c) &&
               String.isNotBlank(event.External_Field_API_Name__c) &&
               String.isNotBlank(event.External_Id__c)){
                SObject sObj = Schema.getGlobalDescribe().get(event.Main_API_Name__c).newSObject();
                sObj.put(event.External_Field_API_Name__c, event.External_Id__c);
                log.putSObject(event.Relationship_API_Name__c.replace('__c', '__r'), sObj);
            }
        }catch(Exception e){
            System.debug(e.getMessage());
            System.debug(e.getCause());
        }

        return log;
    }
}
