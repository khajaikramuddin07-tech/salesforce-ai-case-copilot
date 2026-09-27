@IsTest
private class AIResponseServiceTest {
    @IsTest
    static void applyInboundPayloadPersistsRecommendation() {
        Case caseRecord = new Case(Subject = 'Payment issue', Status = 'New', Priority = 'High', Origin = 'Phone');
        insert caseRecord;

        AI_Interaction__c interaction = new AI_Interaction__c(
            Case__c = caseRecord.Id,
            Request_Id__c = 'response-test',
            Status__c = 'Processing'
        );
        insert interaction;

        AIResponseService.ResponsePayload payload = new AIResponseService.ResponsePayload();
        payload.requestId = 'response-test';
        payload.status = 'Completed';
        payload.model = 'mock';
        payload.promptVersion = 'case-resolution-v1';
        payload.latencyMs = 33;
        payload.recommendation = new Map<String, Object>{
            'summary' => 'Summary',
            'category' => 'Payment Posting Delay',
            'recommendedActions' => new List<String>{ 'Verify payment' },
            'recommendedResolution' => 'Escalate after validation.',
            'draftCustomerResponse' => 'We are reviewing the payment.',
            'knowledgeReferences' => new List<Object>(),
            'similarCases' => new List<Object>(),
            'confidence' => 0.81,
            'reasoningSummary' => 'Evidence summary.'
        };

        AIResponseService.applyInboundPayload(payload);

        AI_Interaction__c updatedInteraction = [
            SELECT Status__c, Model__c, Confidence__c, Latency_Ms__c, Recommendation_JSON__c
            FROM AI_Interaction__c
            WHERE Id = :interaction.Id
        ];
        System.assertEquals('Completed', updatedInteraction.Status__c);
        System.assertEquals('mock', updatedInteraction.Model__c);
        System.assertEquals(0.81, updatedInteraction.Confidence__c);
        System.assertEquals(33, updatedInteraction.Latency_Ms__c);
        System.assert(updatedInteraction.Recommendation_JSON__c.contains('Payment Posting Delay'));
    }

    @IsTest
    static void markFailedStoresError() {
        Case caseRecord = new Case(Subject = 'Payment issue', Status = 'New', Priority = 'High', Origin = 'Phone');
        insert caseRecord;

        insert new AI_Interaction__c(
            Case__c = caseRecord.Id,
            Request_Id__c = 'failed-test',
            Status__c = 'Processing'
        );

        AIResponseService.markFailed('failed-test', 'Service unavailable');

        AI_Interaction__c updatedInteraction = [
            SELECT Status__c, Error_Message__c
            FROM AI_Interaction__c
            WHERE Request_Id__c = 'failed-test'
        ];
        System.assertEquals('Failed', updatedInteraction.Status__c);
        System.assertEquals('Service unavailable', updatedInteraction.Error_Message__c);
    }
}
