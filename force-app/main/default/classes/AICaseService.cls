public with sharing class AICaseService {
    public class CaseAnalysisException extends Exception {}

    public class InteractionDTO {
        @AuraEnabled public Id id;
        @AuraEnabled public String requestId;
        @AuraEnabled public String status;
        @AuraEnabled public String recommendationJson;
        @AuraEnabled public Decimal confidence;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String agentDecision;
        @AuraEnabled public String agentFeedback;
    }

    @AuraEnabled
    public static Id analyzeCase(Id caseId) {
        if (caseId == null) {
            throw new AuraHandledException('Case ID is required.');
        }

        Case caseRecord = [
            SELECT Id, CaseNumber, Subject, Description, Status, Priority, Origin
            FROM Case
            WHERE Id = :caseId
            WITH USER_MODE
            LIMIT 1
        ];

        String requestId = generateRequestId(caseRecord.Id);
        AI_Interaction__c interaction = new AI_Interaction__c(
            Case__c = caseRecord.Id,
            Request_Id__c = requestId,
            Status__c = 'Queued',
            Requested_At__c = System.now()
        );

        SObjectAccessDecision accessDecision = Security.stripInaccessible(
            AccessType.CREATABLE,
            new List<SObject>{ interaction }
        );
        insert accessDecision.getRecords();

        Case_AI_Request__e eventRecord = new Case_AI_Request__e(
            Case_Id__c = String.valueOf(caseRecord.Id),
            Request_Id__c = requestId,
            Action__c = 'Analyze',
            Requested_By__c = String.valueOf(UserInfo.getUserId()),
            Payload_Hash__c = AIOrchestrator.hashPayload(caseRecord)
        );

        Database.SaveResult publishResult = EventBus.publish(eventRecord);
        if (!publishResult.isSuccess()) {
            throw new AuraHandledException('Unable to publish AI analysis request.');
        }

        return (Id) accessDecision.getRecords()[0].get('Id');
    }

    @AuraEnabled(cacheable=true)
    public static InteractionDTO getLatestInteraction(Id caseId) {
        if (caseId == null) {
            throw new AuraHandledException('Case ID is required.');
        }

        List<AI_Interaction__c> records = [
            SELECT Id, Request_Id__c, Status__c, Recommendation_JSON__c, Confidence__c,
                Error_Message__c, Agent_Decision__c, Agent_Feedback__c
            FROM AI_Interaction__c
            WHERE Case__c = :caseId
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (records.isEmpty()) {
            return null;
        }

        return toDto(records[0]);
    }

    @AuraEnabled
    public static InteractionDTO saveAgentDecision(Id interactionId, String decision, String feedback) {
        if (interactionId == null) {
            throw new AuraHandledException('AI Interaction ID is required.');
        }
        if (!new Set<String>{ 'Accepted', 'Edited', 'Rejected' }.contains(decision)) {
            throw new AuraHandledException('Unsupported decision.');
        }

        AI_Interaction__c interaction = [
            SELECT Id, Status__c, Agent_Decision__c, Agent_Feedback__c
            FROM AI_Interaction__c
            WHERE Id = :interactionId
            WITH USER_MODE
            LIMIT 1
        ];
        interaction.Agent_Decision__c = decision;
        interaction.Agent_Feedback__c = String.isBlank(feedback) ? null : feedback.left(32000);
        interaction.Status__c = decision;

        SObjectAccessDecision accessDecision = Security.stripInaccessible(
            AccessType.UPDATABLE,
            new List<SObject>{ interaction }
        );
        update accessDecision.getRecords();

        return getInteraction(interactionId);
    }

    @AuraEnabled(cacheable=true)
    public static InteractionDTO getInteraction(Id interactionId) {
        AI_Interaction__c interaction = [
            SELECT Id, Request_Id__c, Status__c, Recommendation_JSON__c, Confidence__c,
                Error_Message__c, Agent_Decision__c, Agent_Feedback__c
            FROM AI_Interaction__c
            WHERE Id = :interactionId
            WITH USER_MODE
            LIMIT 1
        ];
        return toDto(interaction);
    }

    private static InteractionDTO toDto(AI_Interaction__c interaction) {
        InteractionDTO dto = new InteractionDTO();
        dto.id = interaction.Id;
        dto.requestId = interaction.Request_Id__c;
        dto.status = interaction.Status__c;
        dto.recommendationJson = interaction.Recommendation_JSON__c;
        dto.confidence = interaction.Confidence__c;
        dto.errorMessage = interaction.Error_Message__c;
        dto.agentDecision = interaction.Agent_Decision__c;
        dto.agentFeedback = interaction.Agent_Feedback__c;
        return dto;
    }

    private static String generateRequestId(Id caseId) {
        Blob seed = Blob.valueOf(String.valueOf(caseId) + ':' + String.valueOf(Crypto.getRandomLong()));
        return EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', seed)).left(32);
    }
}
