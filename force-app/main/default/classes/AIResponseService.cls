@RestResource(urlMapping='/ai/case-recommendations/*')
global with sharing class AIResponseService {
    global class ResponsePayload {
        public String requestId;
        public String caseId;
        public String status;
        public String model;
        public String promptVersion;
        public Integer latencyMs;
        public Decimal confidence;
        public Object recommendation;
    }

    @HttpPost
    global static void receive() {
        RestRequest request = RestContext.request;
        ResponsePayload payload = (ResponsePayload) JSON.deserialize(request.requestBody.toString(), ResponsePayload.class);
        applyInboundPayload(payload);
    }

    public static void applyResult(AIOrchestrator.AnalyzeResult result) {
        ResponsePayload payload = new ResponsePayload();
        payload.requestId = result.requestId;
        payload.caseId = result.caseId;
        payload.status = result.status;
        payload.model = result.model;
        payload.promptVersion = result.promptVersion;
        payload.latencyMs = result.latencyMs;
        payload.recommendation = result.recommendation;
        applyInboundPayload(payload);
    }

    public static void applyInboundPayload(ResponsePayload payload) {
        if (payload == null || String.isBlank(payload.requestId)) {
            throw new AuraHandledException('requestId is required.');
        }

        AI_Interaction__c interaction = [
            SELECT Id, Request_Id__c, Status__c, Model__c, Prompt_Template_Version__c,
                Latency_Ms__c, Recommendation_JSON__c, Confidence__c, Completed_At__c
            FROM AI_Interaction__c
            WHERE Request_Id__c = :payload.requestId
            LIMIT 1
        ];

        Map<String, Object> recommendation = payload.recommendation == null
            ? new Map<String, Object>()
            : (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(payload.recommendation));

        interaction.Status__c = String.isBlank(payload.status) ? 'Completed' : payload.status;
        interaction.Model__c = payload.model;
        interaction.Prompt_Template_Version__c = payload.promptVersion;
        interaction.Latency_Ms__c = payload.latencyMs;
        interaction.Recommendation_JSON__c = JSON.serializePretty(recommendation);
        interaction.Confidence__c = extractConfidence(recommendation, payload.confidence);
        interaction.Completed_At__c = System.now();

        SObjectAccessDecision accessDecision = Security.stripInaccessible(
            AccessType.UPDATABLE,
            new List<SObject>{ interaction }
        );
        update accessDecision.getRecords();
    }

    public static void markFailed(String requestId, String message) {
        List<AI_Interaction__c> records = [
            SELECT Id, Status__c, Error_Message__c, Completed_At__c
            FROM AI_Interaction__c
            WHERE Request_Id__c = :requestId
            LIMIT 1
        ];
        if (records.isEmpty()) {
            return;
        }

        AI_Interaction__c interaction = records[0];
        interaction.Status__c = 'Failed';
        interaction.Error_Message__c = String.isBlank(message) ? 'Unknown AI processing error.' : message.left(32000);
        interaction.Completed_At__c = System.now();
        update Security.stripInaccessible(AccessType.UPDATABLE, new List<SObject>{ interaction }).getRecords();
    }

    private static Decimal extractConfidence(Map<String, Object> recommendation, Decimal fallback) {
        if (recommendation != null && recommendation.containsKey('confidence')) {
            Object value = recommendation.get('confidence');
            if (value instanceof Decimal) {
                return (Decimal) value;
            }
            if (value instanceof Double) {
                return Decimal.valueOf(String.valueOf(value));
            }
        }
        return fallback;
    }
}
