public without sharing class APILogEventBuilder{
        String dmlOperation;
        String externalFieldApiName;
        String externalId;
        String externalSystem;
        Boolean icCustom;
        String mainApiName;
        String payload;
        String response;
        String salesforceId;
        String status;
        Integer statusCode;
        String type;

        public APILogEventBuilder dmlOperation(String value){
                this.dmlOperation = value;
                return this;
        }
        public APILogEventBuilder externalFieldApiName(String value){
                this.externalFieldApiName = value;
                return this;
        }
        public APILogEventBuilder externalId(String value){
                this.externalId = value;
                return this;
        }
        public APILogEventBuilder externalSystem(String value){
                this.externalSystem = value;
                return this;
        }
        public APILogEventBuilder mainApiName(String value){
                this.mainApiName = value;
                return this;
        }
        public APILogEventBuilder payload(String value){
                this.payload = value;
                return this;
        }
        public APILogEventBuilder response(String value){
                this.response = value;
                return this;
        }
        public APILogEventBuilder salesforceId(String value){
                this.salesforceId = value;
                return this;
        }
        public APILogEventBuilder status(String value){
                this.status = value;
                return this;
        }
        public APILogEventBuilder type(String value){
                this.type = value;
                return this;
        }
        public APILogEventBuilder statusCode(Integer value){
                this.statusCode = value;
                return this;
        }
        public APILogEventBuilder icCustom(Boolean value){
                this.icCustom = value;
                return this;
        }

        public API_Log_Event__e build(){
                API_Log_Event__e event = new API_Log_Event__e();
                event.DML_Operation__c = this.dmlOperation;
                event.External_Field_API_Name__c = this.externalFieldApiName;
                event.External_Id__c = this.externalId;
                event.External_System__c = this.externalSystem;
                event.Is_Custom__c = this.icCustom;
                event.Main_API_Name__c = this.mainApiName;
                event.Payload__c = this.payload;
                event.Response__c = this.response;
                event.Salesforce_Id__c = this.salesforceId;
                event.Status__c = this.status;
                event.Status_Code__c = this.statusCode;
                event.Type__c = this.type;
                return event;
        }
}
