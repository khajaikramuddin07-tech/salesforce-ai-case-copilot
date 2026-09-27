trigger CaseAIRequestTrigger on Case_AI_Request__e (after insert) {
    for (Case_AI_Request__e eventRecord : Trigger.New) {
        if (String.isBlank(eventRecord.Case_Id__c) || String.isBlank(eventRecord.Request_Id__c)) {
            continue;
        }
        System.enqueueJob(new AIRequestQueueable((Id) eventRecord.Case_Id__c, eventRecord.Request_Id__c));
    }
}
