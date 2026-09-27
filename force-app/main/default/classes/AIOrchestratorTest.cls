@IsTest
private class AIOrchestratorTest {
    @IsTest
    static void analyzeCaseSendsStructuredPayload() {
        Case caseRecord = new Case(
            Subject = 'Credit card payment posted but available credit not updated',
            Description = 'Payment cleared externally.',
            Status = 'New',
            Priority = 'High',
            Origin = 'Phone'
        );
        insert caseRecord;

        AIOrchestrator.AnalyzeResult result = new AIOrchestrator(new FakeTransport()).analyzeCase(caseRecord.Id, 'req-001');

        System.assertEquals('req-001', result.requestId);
        System.assertEquals('Completed', result.status);
        System.assertEquals('mock-case-copilot-v1', result.model);
    }

    @IsTest
    static void retrieversReturnRelevantBankingEvidence() {
        Case caseRecord = new Case(
            Subject = 'Credit card payment available credit issue',
            Description = 'Payment cleared but available credit is still low.'
        );

        System.assert(KnowledgeRetriever.retrieve(caseRecord).size() > 0);
        System.assert(SimilarCaseService.findSimilar(caseRecord).size() > 0);
    }

    private class FakeTransport implements AIOrchestrator.Transport {
        public HttpResponse send(HttpRequest request) {
            System.assertEquals('POST', request.getMethod());
            System.assert(request.getEndpoint().endsWith('/analyze'));
            System.assert(request.getBody().contains('knowledge'));

            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{"requestId":"req-001","caseId":"500000000000001AAA","status":"Completed","model":"mock-case-copilot-v1","promptVersion":"case-resolution-v1","latencyMs":12,"recommendation":{"summary":"Summary","category":"Payment Posting Delay","recommendedActions":["Action"],"recommendedResolution":"Resolution","draftCustomerResponse":"Draft","knowledgeReferences":[],"similarCases":[],"confidence":0.75,"reasoningSummary":"Evidence summary"}}');
            return response;
        }
    }
}
