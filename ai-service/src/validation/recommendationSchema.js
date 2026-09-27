import { ValidationError } from '../errors.js';

const requiredStringFields = [
  'summary',
  'category',
  'recommendedResolution',
  'draftCustomerResponse',
  'reasoningSummary'
];

export function validateRecommendation(payload) {
  const errors = [];

  if (!payload || typeof payload !== 'object') {
    throw new ValidationError('Recommendation must be an object.');
  }

  for (const field of requiredStringFields) {
    if (typeof payload[field] !== 'string' || payload[field].trim() === '') {
      errors.push(`${field} must be a non-empty string`);
    }
  }

  if (!Array.isArray(payload.recommendedActions)) {
    errors.push('recommendedActions must be an array');
  }

  if (!Array.isArray(payload.knowledgeReferences)) {
    errors.push('knowledgeReferences must be an array');
  }

  if (!Array.isArray(payload.similarCases)) {
    errors.push('similarCases must be an array');
  }

  if (typeof payload.confidence !== 'number' || payload.confidence < 0 || payload.confidence > 1) {
    errors.push('confidence must be a number between 0 and 1');
  }

  if (errors.length > 0) {
    throw new ValidationError('Invalid recommendation payload.', errors);
  }

  return {
    ...payload,
    recommendedActions: payload.recommendedActions.map(String),
    confidence: Number(payload.confidence.toFixed(2))
  };
}

export function validateAnalyzeRequest(body) {
  const caseRecord = body?.case;

  if (!body?.requestId || typeof body.requestId !== 'string') {
    throw new ValidationError('requestId is required.');
  }

  if (!caseRecord || typeof caseRecord !== 'object') {
    throw new ValidationError('case object is required.');
  }

  if (!caseRecord.id || !caseRecord.subject) {
    throw new ValidationError('case.id and case.subject are required.');
  }

  return body;
}
