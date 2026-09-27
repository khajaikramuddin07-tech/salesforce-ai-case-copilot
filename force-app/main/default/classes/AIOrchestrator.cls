public with sharing class AIOrchestrator {
    public static final String NAMED_CREDENTIAL = 'callout:AI_Case_Copilot';

    public interface Transport {
        HttpResponse send(HttpRequest request);
    }

    public class HttpTransport implements Transport {
        public HttpResponse send(HttpRequest request) {
            return new Http().send(request);
        }
    }

    public class AnalyzeResult {
        public String requestId;
        public String caseId;
        public String status;
        public String model;
        public String promptVersion;
        public Integer latencyMs;
        public Object recommendation;
    }

    private Transport transport;

    public AIOrchestrator() {
        this(new HttpTransport());
    }

    public AIOrchestrator(Transport transport) {
        this.transport = transport;
    }

    public AnalyzeResult analyzeCase(Id caseId, String requestId) {
        Case caseRecord = [
            SELECT Id, CaseNumber, Subject, Description, Status, Priority, Origin
            FROM Case
            WHERE Id = :caseId
            WITH USER_MODE
            LIMIT 1
        ];

        Map<String, Object> payload = new Map<String, Object>{
            'requestId' => requestId,
            'case' => buildCasePayload(caseRecord),
            'knowledge' => KnowledgeRetriever.retrieve(caseRecord),
            'similarCases' => SimilarCaseService.findSimilar(caseRecord)
        };

        HttpRequest request = new HttpRequest();
        request.setEndpoint(NAMED_CREDENTIAL + '/analyze');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(20000);
        request.setBody(JSON.serialize(payload));

        HttpResponse response = transport.send(request);
        if (response.getStatusCode() < 200 || response.getStatusCode() >= 300) {
            throw new CalloutException('AI service returned status ' + response.getStatusCode());
        }

        return (AnalyzeResult) JSON.deserialize(response.getBody(), AnalyzeResult.class);
    }

    public static String hashPayload(Case caseRecord) {
        String raw = String.join(new List<String>{
            String.valueOf(caseRecord.Id),
            String.valueOf(caseRecord.Subject),
            String.valueOf(caseRecord.Description)
        }, '|');
        return EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(raw)));
    }

    private static Map<String, Object> buildCasePayload(Case caseRecord) {
        return new Map<String, Object>{
            'id' => caseRecord.Id,
            'caseNumber' => caseRecord.CaseNumber,
            'subject' => caseRecord.Subject,
            'description' => caseRecord.Description,
            'status' => caseRecord.Status,
            'priority' => caseRecord.Priority,
            'origin' => caseRecord.Origin,
            'product' => 'Credit Card'
        };
    }
}
