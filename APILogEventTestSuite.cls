@isTest public without sharing class APILogEventTestSuite {
    @TestSetup public static void testSetup() {
        Product2 product = new Product2();
        product.Name = 'Test';
        product.VIP_Siebel_Id__c = '1-TEST';
        insert product;
    }

    @isTest public static void publishEventWithExternalIdToProduct() {

        List<API_Log_Event__e> events = new List<API_Log_Event__e>();
        events.add(new APILogEventBuilder()
                .externalField(Schema.Product2.SObjectType.fields.VIP_Siebel_Id__c)
                .externalId('1-TEST')
                .mainSObjectType(Schema.Product2.SObjectType)
                .relationshipField(Schema.API_Log__c.SObjectType.fields.Product__c)
                .build());
        Test.startTest();
        {
            EventBus.publish(events);
        }
        Test.stopTest();

        System.assert(![SELECT Id FROM API_Log__c WHERE Product__c != NULL].isEmpty());
    }

    @isTest public static void publishEventWithSalesforceIdToProduct() {
        List<API_Log_Event__e> events = new List<API_Log_Event__e>();
        events.add(new APILogEventBuilder()
                .salesforceId([SELECT Id FROM Product2 LIMIT 1].Id)
                .mainSObjectType(Schema.Product2.SObjectType)
                .relationshipField(Schema.API_Log__c.SObjectType.fields.Product__c)
                .build());
        Test.startTest();
        {
            EventBus.publish(events);
        }
        Test.stopTest();

        System.assert(![SELECT Id FROM API_Log__c WHERE Product__c != NULL].isEmpty());
    }

    @isTest public static void publishEmptyEventsTest() {
        List<API_Log_Event__e> events = new List<API_Log_Event__e>();
        events.add(new APILogEventBuilder().build());
        events.add(new APILogEventBuilder().build());
        Test.startTest();
        {
            EventBus.publish(events);
        }
        Test.stopTest();

        System.assert(![SELECT Id FROM API_Log__c].isEmpty());
    }

    @isTest public static void publishEventWithAllValues() {
        List<API_Log_Event__e> events = new List<API_Log_Event__e>();
        API_Log_Event__e event = new APILogEventBuilder()
                .dmlOperation('dmlOperation')
                .type('type')
                .statusCode(200)
                .status('status')
                .response('response')
                .payload('payload')
                .icCustom(true)
                .externalSystem('externalSystem')
                .build();
        events.add(event);
        Test.startTest();
        {
            EventBus.publish(events);
        }
        Test.stopTest();

        API_Log__c singleLog = [
                SELECT Id, Response__c, Payload__c
                FROM API_Log__c
                WHERE DML_Operation__c = 'dmlOperation' AND
                Type__c = 'type' AND
                Status_Code__c = 200 AND
                Status__c = 'status' AND
                Is_Custom__c = true AND
                External_System__c = 'externalSystem'
        ];
        System.assert(singleLog != null);
        System.assert(singleLog.Payload__c == 'payload');
        System.assert(singleLog.Response__c == 'response');
    }
}
