import { ProviderError } from './errors.js';
import { buildPrompt } from './prompts/caseRecommendationPrompt.js';
import { retrieveKnowledge } from './retrieval/knowledgeRepository.js';
import { retrieveSimilarCases } from './retrieval/similarCaseRepository.js';
import { buildSecurityEnvelope } from './security.js';
import { validateAnalyzeRequest, validateRecommendation } from './validation/recommendationSchema.js';

export async function analyzeCase(request, provider, logger) {
  const startedAt = performance.now();
  const normalized = validateAnalyzeRequest(request);
  const caseRecord = normalized.case;
  const security = buildSecurityEnvelope(caseRecord);
  const knowledgeArticles = retrieveKnowledge(caseRecord);
  const similarCases = retrieveSimilarCases(caseRecord);
  const prompt = buildPrompt({ caseRecord, knowledgeArticles, similarCases, security });

  logger.info('Generating case recommendation', {
    requestId: normalized.requestId,
    caseId: caseRecord.id,
    promptVersion: prompt.version,
    promptInjectionSuspected: security.promptInjectionSuspected
  });

  let providerResult;
  try {
    providerResult = await provider.generateRecommendation(prompt);
  } catch (error) {
    throw new ProviderError('AI provider failed to generate a recommendation.', error);
  }

  const recommendation = validateRecommendation(providerResult.output);
  const latencyMs = Math.round(performance.now() - startedAt);

  return {
    requestId: normalized.requestId,
    caseId: caseRecord.id,
    status: 'Completed',
    model: providerResult.model,
    promptVersion: prompt.version,
    latencyMs,
    recommendation,
    safety: security,
    generatedAt: new Date().toISOString()
  };
}
