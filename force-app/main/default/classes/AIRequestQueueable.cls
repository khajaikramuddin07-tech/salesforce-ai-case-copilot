public with sharing class AIRequestQueueable implements Queueable, Database.AllowsCallouts {
    private static final Integer MAX_ATTEMPTS = 2;

    private Id caseId;
    private String requestId;
    private Integer attempt;

    public AIRequestQueueable(Id caseId, String requestId) {
        this(caseId, requestId, 1);
    }

    public AIRequestQueueable(Id caseId, String requestId, Integer attempt) {
        this.caseId = caseId;
        this.requestId = requestId;
        this.attempt = attempt == null ? 1 : attempt;
    }

    public void execute(QueueableContext context) {
        AI_Interaction__c interaction = findInteraction();
        if (interaction == null) {
            return;
        }

        try {
            markProcessing(interaction);
            AIOrchestrator.AnalyzeResult result = new AIOrchestrator().analyzeCase(caseId, requestId);
            AIResponseService.applyResult(result);
        } catch (Exception ex) {
            if (attempt < MAX_ATTEMPTS) {
                System.enqueueJob(new AIRequestQueueable(caseId, requestId, attempt + 1));
                return;
            }
            AIResponseService.markFailed(requestId, ex.getMessage());
        }
    }

    private AI_Interaction__c findInteraction() {
        List<AI_Interaction__c> records = [
            SELECT Id, Status__c, Request_Id__c
            FROM AI_Interaction__c
            WHERE Request_Id__c = :requestId
            LIMIT 1
        ];
        return records.isEmpty() ? null : records[0];
    }

    private static void markProcessing(AI_Interaction__c interaction) {
        interaction.Status__c = 'Processing';
        SObjectAccessDecision accessDecision = Security.stripInaccessible(
            AccessType.UPDATABLE,
            new List<SObject>{ interaction }
        );
        update accessDecision.getRecords();
    }
}
