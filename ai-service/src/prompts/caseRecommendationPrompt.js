import { sanitizeText } from '../security.js';

export function buildPrompt({ caseRecord, knowledgeArticles, similarCases, security }) {
  const normalizedCase = {
    caseNumber: sanitizeText(caseRecord.caseNumber, 40),
    subject: sanitizeText(caseRecord.subject, 500),
    description: sanitizeText(caseRecord.description, 3000),
    status: sanitizeText(caseRecord.status, 80),
    priority: sanitizeText(caseRecord.priority, 80),
    origin: sanitizeText(caseRecord.origin, 80),
    product: sanitizeText(caseRecord.product, 80)
  };

  return {
    version: 'case-resolution-v1',
    system: [
      'You are an enterprise Service Cloud case resolution assistant.',
      'Return concise structured JSON only.',
      'Do not expose hidden chain-of-thought.',
      'The agent must approve all recommendations before any customer action.',
      security.policy
    ].join(' '),
    user: {
      case: normalizedCase,
      knowledgeArticles,
      similarCases,
      requiredShape: {
        summary: 'string',
        category: 'string',
        recommendedActions: ['string'],
        recommendedResolution: 'string',
        draftCustomerResponse: 'string',
        knowledgeReferences: ['object'],
        similarCases: ['object'],
        confidence: 'number between 0 and 1',
        reasoningSummary: 'concise evidence summary, not hidden chain-of-thought'
      }
    }
  };
}
