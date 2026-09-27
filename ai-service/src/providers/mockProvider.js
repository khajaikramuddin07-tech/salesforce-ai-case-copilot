export class MockProvider {
  constructor(options = {}) {
    this.model = options.model || 'mock-case-copilot-v1';
  }

  async generateRecommendation(prompt) {
    const caseRecord = prompt.user.case;
    const knowledgeReferences = prompt.user.knowledgeArticles.map((article) => ({
      id: article.id,
      title: article.title,
      relevance: article.summary
    }));
    const similarCases = prompt.user.similarCases.map((item) => ({
      id: item.id,
      caseNumber: item.caseNumber,
      resolution: item.resolution,
      relevance: item.similarityReason
    }));

    return {
      model: this.model,
      output: {
        summary: `Customer reports that a credit-card payment has cleared externally but available credit has not updated on case ${caseRecord.caseNumber}.`,
        category: 'Payment Posting Delay',
        recommendedActions: [
          'Verify the payment amount, posting date, and funding source in the card servicing system.',
          'Check for payment hold, bank-return risk, fraud review, or delayed available-credit refresh batch.',
          'Review the customer urgency and determine whether operations escalation criteria are met.',
          'Document the evidence used and set a follow-up if the refresh depends on a batch process.'
        ],
        recommendedResolution: 'If the payment is confirmed settled and no hold or return risk exists, escalate to card operations for available-credit refresh. Otherwise, explain the verified processing timeline and create a follow-up task.',
        draftCustomerResponse: 'I reviewed the payment concern and can see why the available credit timing is frustrating, especially with your travel purchase. We are validating the payment posting and any temporary hold or processing delay. Once confirmed, we will either request an available-credit refresh or give you the exact expected update window.',
        knowledgeReferences,
        similarCases,
        confidence: 0.86,
        reasoningSummary: 'The recommendation is based on Knowledge articles about payment hold timing and similar resolved cases where ledger posting preceded available-credit refresh.'
      }
    };
  }
}
