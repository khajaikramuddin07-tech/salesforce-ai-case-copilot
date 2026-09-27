import assert from 'node:assert/strict';
import test from 'node:test';
import { analyzeCase } from '../src/orchestrator.js';
import { MockProvider } from '../src/providers/mockProvider.js';

const logger = {
  info() {},
  error() {}
};

test('analyzeCase returns a structured recommendation', async () => {
  const result = await analyzeCase({
    requestId: 'unit-test-001',
    case: {
      id: '500000000000001AAA',
      caseNumber: '00048291',
      subject: 'Credit card payment posted but available credit not updated',
      description: 'Payment cleared but available credit still has not changed.',
      status: 'Working',
      priority: 'High',
      origin: 'Phone',
      product: 'Credit Card'
    }
  }, new MockProvider(), logger);

  assert.equal(result.status, 'Completed');
  assert.equal(result.recommendation.category, 'Payment Posting Delay');
  assert.ok(result.recommendation.recommendedActions.length >= 3);
  assert.ok(result.recommendation.knowledgeReferences.length >= 1);
  assert.ok(result.recommendation.confidence > 0.8);
});

test('analyzeCase rejects invalid requests', async () => {
  await assert.rejects(
    () => analyzeCase({ requestId: 'bad' }, new MockProvider(), logger),
    /case object is required/
  );
});
