public with sharing class KnowledgeRetriever {
    public class KnowledgeResult {
        public String id;
        public String title;
        public String summary;
        public Decimal score;
    }

    public static List<KnowledgeResult> retrieve(Case caseRecord) {
        List<KnowledgeResult> results = new List<KnowledgeResult>();

        String text = (String.valueOf(caseRecord.Subject) + ' ' + String.valueOf(caseRecord.Description)).toLowerCase();
        if (text.contains('payment') || text.contains('available credit')) {
            results.add(buildResult(
                'KA-DEMO-001',
                'Credit card payment hold and available credit timing',
                'Payments may post before available credit refreshes when validation or hold checks are pending.',
                0.94
            ));
            results.add(buildResult(
                'KA-DEMO-002',
                'Manual available credit refresh escalation',
                'Operations can refresh available credit after validating settled payment status.',
                0.87
            ));
        }

        return results;
    }

    private static KnowledgeResult buildResult(String id, String title, String summary, Decimal score) {
        KnowledgeResult result = new KnowledgeResult();
        result.id = id;
        result.title = title;
        result.summary = summary;
        result.score = score;
        return result;
    }
}
