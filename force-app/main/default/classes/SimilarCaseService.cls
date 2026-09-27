public with sharing class SimilarCaseService {
    public class SimilarCaseResult {
        public String id;
        public String caseNumber;
        public String subject;
        public String resolution;
        public Decimal score;
    }

    public static List<SimilarCaseResult> findSimilar(Case caseRecord) {
        List<SimilarCaseResult> results = new List<SimilarCaseResult>();
        String text = (String.valueOf(caseRecord.Subject) + ' ' + String.valueOf(caseRecord.Description)).toLowerCase();

        if (text.contains('payment') && text.contains('credit')) {
            results.add(buildResult(
                '500-DEMO-101',
                '00047112',
                'Payment cleared but card credit not restored',
                'Validated payment settlement, checked hold status, and escalated available-credit refresh.',
                0.91
            ));
            results.add(buildResult(
                '500-DEMO-102',
                '00046844',
                'Travel booking blocked after large payment',
                'Prioritized operations review due to time-sensitive customer purchase.',
                0.84
            ));
        }

        return results;
    }

    private static SimilarCaseResult buildResult(String id, String caseNumber, String subject, String resolution, Decimal score) {
        SimilarCaseResult result = new SimilarCaseResult();
        result.id = id;
        result.caseNumber = caseNumber;
        result.subject = subject;
        result.resolution = resolution;
        result.score = score;
        return result;
    }
}
