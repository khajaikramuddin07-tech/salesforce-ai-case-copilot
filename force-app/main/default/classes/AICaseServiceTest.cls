@IsTest
private class AICaseServiceTest {
    @IsTest
    static void analyzeCaseCreatesInteractionAndPublishesEvent() {
        Case caseRecord = new Case(
            Subject = 'Credit card payment posted but available credit not updated',
            Description = 'Customer payment cleared but available credit did not refresh.',
            Status = 'New',
            Priority = 'High',
            Origin = 'Phone'
        );
        insert caseRecord;

        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());
        Test.startTest();
        Id interactionId = AICaseService.analyzeCase(caseRecord.Id);
        Test.stopTest();

        AI_Interaction__c interaction = [
            SELECT Id, Status__c, Recommendation_JSON__c, Confidence__c
            FROM AI_Interaction__c
            WHERE Id = :interactionId
        ];
        System.assertEquals('Completed', interaction.Status__c);
        System.assert(interaction.Recommendation_JSON__c.contains('Payment Posting Delay'));
        System.assertEquals(0.86, interaction.Confidence__c);
    }

    @IsTest
    static void saveAgentDecisionUpdatesInteraction() {
        Case caseRecord = new Case(Subject = 'Payment issue', Status = 'New', Priority = 'Medium', Origin = 'Web');
        insert caseRecord;

        AI_Interaction__c interaction = new AI_Interaction__c(
            Case__c = caseRecord.Id,
            Request_Id__c = 'decision-test',
            Status__c = 'Completed'
        );
        insert interaction;

        AICaseService.InteractionDTO dto = AICaseService.saveAgentDecision(interaction.Id, 'Accepted', 'Looks correct.');

        System.assertEquals('Accepted', dto.agentDecision);
        System.assertEquals('Accepted', dto.status);
    }

    private class SuccessCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"requestId":"' + extractRequestId(request.getBody()) + '","caseId":"500000000000001AAA","status":"Completed","model":"mock-case-copilot-v1","promptVersion":"case-resolution-v1","latencyMs":42,"recommendation":{"summary":"Payment cleared but available credit did not update.","category":"Payment Posting Delay","recommendedActions":["Verify payment","Check hold","Escalate if settled"],"recommendedResolution":"Escalate after validation.","draftCustomerResponse":"We are reviewing the payment status.","knowledgeReferences":[],"similarCases":[],"confidence":0.86,"reasoningSummary":"Knowledge and similar cases indicate a posting delay."}}');
            return response;
        }

        private String extractRequestId(String body) {
            Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(body);
            return (String) parsed.get('requestId');
        }
    }
}
