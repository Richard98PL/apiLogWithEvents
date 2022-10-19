public without sharing class APILogEventTriggerHandlerHelper {
    private static String operationName;
    private static Boolean firstTimeAfter = true;
    private static Boolean firstTimeBefore = true;
    private static Boolean checkIfFirstTimeAfter(){
        if(firstTimeAfter){
            firstTimeAfter = false;
            return true;
        }else{
            return false;
        }
    }
    private static Boolean checkIfFirstTimeBefore(){
        if(firstTimeBefore){
            firstTimeBefore = false;
            return true;
        }else{
            return false;
        }
    }
    private static List<SObject> triggerOldListReference;

    private Set<String> externalIdThatExists = new Set<String>();
    private Set<Id> idThatAreNotDeleted = new Set<Id>();
    private Set<String> eventUuidToSkip = new Set<String>();
    private Map<String, API_Log_Event__e> eventsWithoutSFRecord = new Map<String, API_Log_Event__e>();
    public void insertAPILogs(List<API_Log_Event__e> events){
        fillObjectsFromExternalIdOfEvents(events);
        fillObjectsFromSalesforceIdOfEvents(events);

        List<API_Log__c> logs = new List<API_Log__c>();
        for(API_Log_Event__e event : events){
            System.debug(event);
            System.debug(this.eventUuidToSkip);
            System.debug(this.eventUuidToSkip.contains(event.EventUuid));
            if(!this.eventUuidToSkip.contains(event.EventUuid)){
                logs.add(parseLog(event));
            }
        }

        List<Database.SaveResult> results = Database.insert(logs, false);
        System.debug(this.eventsWithoutSFRecord);
        if(!this.eventsWithoutSFRecord.isEmpty()){
            EventBus.publish(this.eventsWithoutSFRecord.values());
        }
        System.debug(results);
    }

    private void fillObjectsFromSalesforceIdOfEvents(List<API_Log_Event__e> events) {
        if(events.size() > 0){
            API_Log_Event__e event = events.get(0);
            if(String.isNotBlank(event.Salesforce_Id__c) &&
                    String.isNotBlank(event.Main_API_Name__c)){
                String query = 'SELECT Id, IsDeleted FROM '  + event.Main_API_Name__c +
                        ' WHERE Id IN (';
                for(API_Log_Event__e eventRecord : events){
                    query += '\'' + eventRecord.Salesforce_Id__c + '\',';
                }
                query = query.removeEnd(',');
                query += ') ALL ROWS';
                System.debug(query);
                List<SObject> results = Database.query(query);
                System.debug(results);

                Set<String> allIds = new Set<String>();
                for(SObject record : results){
                    allIds.add(record.Id);
                    if((Boolean) record.get('IsDeleted') == false){
                        this.idThatAreNotDeleted.add(record.Id);
                    }
                }

                Map<String, API_Log_Event__e> eventBySFId = new Map<String, API_Log_Event__e>();
                for(API_Log_Event__e loopEvent : events){
                    if(String.isNotBlank(loopEvent.Salesforce_Id__c)){
                        eventBySFId.put(loopEvent.Salesforce_Id__c, loopEvent);
                    }
                }

                for(String id : eventBySFId.keySet()){
                    API_Log_Event__e currentEvent = eventBySFId.get(id);
                    if(!allIds.contains(id) && currentEvent.Iteration__c < 3){
                        if(currentEvent.Iteration__c == null){
                            currentEvent.Iteration__c = 0;
                        }
                        API_Log_Event__e newEvent = currentEvent.clone();
                        newEvent.Iteration__c += 1;
                        if(newEvent.Iteration__c == 3){
                            newEvent.DML_Error__c = true;
                            newEvent.DML_Error_Message__c = 'Record not committed to the database.';
                        }
                        this.eventsWithoutSFRecord.put(currentEvent.EventUuid, newEvent);
                        this.eventUuidToSkip.add(currentEvent.EventUuid);
                    }
                }
            }
        }
        System.debug(this.idThatAreNotDeleted);
    }

    private void fillObjectsFromExternalIdOfEvents(List<API_Log_Event__e> events) {
        if(events.size() > 0){
            API_Log_Event__e event = events.get(0);
            if(String.isNotBlank(event.External_Field_API_Name__c) &&
               String.isNotBlank(event.Main_API_Name__c) &&
               String.isNotBlank(event.External_Id__c)){
                String query = 'SELECT IsDeleted, ' + event.External_Field_API_Name__c +
                        ' FROM ' + event.Main_API_Name__c +
                        ' WHERE ' + event.External_Field_API_Name__c + ' != NULL AND ' + event.External_Field_API_Name__c + ' IN (';
                for(API_Log_Event__e eventRecord : events){
                    query += '\'' + eventRecord.External_Id__c + '\',';
                }
                query = query.removeEnd(',');
                query += ') ALL ROWS';
                List<SObject> results = Database.query(query);
                System.debug(query);
                System.debug(results);

                Set<String> allIds = new Set<String>();
                for(SObject record : results){
                    allIds.add(String.valueOf(record.get(event.External_Field_API_Name__c)));
                    if((Boolean) record.get('IsDeleted') == false){
                        this.externalIdThatExists.add(String.valueOf(record.get(event.External_Field_API_Name__c)));
                    }
                }

                Map<String, API_Log_Event__e> eventByExternalId = new Map<String, API_Log_Event__e>();
                for(API_Log_Event__e loopEvent : events){
                    if(String.isNotBlank(loopEvent.External_Id__c)){
                        eventByExternalId.put(loopEvent.External_Id__c, loopEvent);
                    }
                }

                for(String id : eventByExternalId.keySet()){
                    API_Log_Event__e currentEvent = eventByExternalId.get(id);
                    if(!allIds.contains(id) && currentEvent.Iteration__c < 3){
                        if(currentEvent.Iteration__c == null){
                            currentEvent.Iteration__c = 0;
                        }
                        API_Log_Event__e newEvent = currentEvent.clone();
                        newEvent.Iteration__c += 1;
                        if(newEvent.Iteration__c == 3){
                            newEvent.DML_Error__c = true;
                            newEvent.DML_Error_Message__c = 'Record not committed to the database.';
                        }
                        this.eventsWithoutSFRecord.put(currentEvent.EventUuid, newEvent);
                        this.eventUuidToSkip.add(currentEvent.EventUuid);
                    }
                }
            }
        }
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
        log.IP__c = event.IP__c;
        log.Username__c = event.Username__c;
        log.UserId__c = event.UserId__c;
        log.Iteration__c = event.Iteration__c;

        Boolean wasLookupSuccess = false;
        try{
            if(String.isNotBlank(event.Relationship_API_Name__c) &&
                    String.isNotBlank(event.Salesforce_Id__c) &&
                    this.idThatAreNotDeleted.contains(event.Salesforce_Id__c)){
                log.put(event.Relationship_API_Name__c, event.Salesforce_Id__c);
                wasLookupSuccess = true;
            }
        }catch(Exception e){
            System.debug(e.getMessage());
            System.debug(e.getCause());
        }

        try{
            if(!wasLookupSuccess && String.isNotBlank(event.Relationship_API_Name__c) &&
                this.externalIdThatExists.contains(event.External_Id__c) &&
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

    public void handleStandardEndpointRequest(SObjectField logRelationshipField){
        if(Trigger.isBefore){
            if(checkIfFirstTimeBefore()){
                triggerOldListReference = Trigger.old != null ? Trigger.old : Trigger.new;
                operationName = Trigger.operationType.name();
            }
            return;
        }

        if(Trigger.isAfter && !checkIfFirstTimeAfter()){
            return;
        }

        List<API_Log_Event__e> platformEvents = new List<API_Log_Event__e>();
        List<SObject> records = Trigger.new == null ? Trigger.old : Trigger.new;
        String url = Url.getCurrentRequestUrl()?.getPath();
        Boolean isStandardEndpointForSObject = false;
        SObjectType triggerSObjectType;

        if(String.isNotBlank(url) && records != null && !records.isEmpty()){
            triggerSObjectType = records.get(0)?.getSObjectType();
            isStandardEndpointForSObject = url.contains('/services/data') &&
                                           url.contains('/sobjects/' + String.valueOf(triggerSObjectType));
        }

        if(!isStandardEndpointForSObject){
            return;
        }

        String operationNameWithoutContext = operationName.replace('BEFORE_', '');
        operationNameWithoutContext = operationNameWithoutContext.replace('AFTER_', '');

        Integer i = 0;
        for(SObject record : records){
            String payload = JSON.serializePretty(triggerOldListReference.get(i));
            System.debug(payload);
            API_Log_Event__e event = new APILogEventBuilder()
                    .mainSObjectType(triggerSObjectType)
                    .payload(payload)
                    .salesforceId(record.Id)
                    .relationshipField(logRelationshipField)
                    .isCustom(false)
                    .URL(url)
                    .type(APILogUtilsValues.TYPE_INCOMING)
                    .dmlOperation(operationNameWithoutContext)
                    .method(String.isBlank(operationName) ? Trigger.operationType.name() : operationName)
                    .build();
            platformEvents.add(event);
            i++;
        }
        System.debug(platformEvents);
        EventBus.publish(platformEvents);
    }
}
