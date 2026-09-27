# AI Design

## Goals

- Summarize Case context.
- Retrieve relevant Knowledge and similar resolved Cases.
- Generate troubleshooting steps, a proposed resolution, and a draft customer response.
- Preserve a clear evidence trail.
- Keep provider choice replaceable.

## RAG Flow

1. Validate the request.
2. Normalize and sanitize Case fields.
3. Retrieve Knowledge references.
4. Retrieve similar resolved Cases.
5. Build a versioned prompt.
6. Call an LLM provider abstraction.
7. Validate structured JSON.
8. Return model, prompt version, latency, confidence, recommendation, and safety metadata.

## Provider Abstraction

Providers implement:

```js
async generateRecommendation(prompt) {
  return {
    model: 'provider-model-name',
    output: { }
  };
}
```

`MockProvider` makes demos and CI deterministic. A production provider can be introduced in `src/providers` without changing Salesforce.

## Prompt Management

Prompts are versioned with `case-resolution-v1`. The prompt forbids hidden chain-of-thought exposure and requires concise user-facing evidence in `reasoningSummary`.

## Validation

`recommendationSchema.js` validates:

- Required string fields.
- Array fields.
- `confidence` as a number from 0 to 1.
- Request-level `requestId`, `case.id`, and `case.subject`.

## Agentforce Extension

The architecture supports reusable Agentforce actions:

- Summarize Case
- Find Similar Cases
- Search Knowledge
- Recommend Resolution
- Draft Customer Response

These can call the same retrieval and orchestration modules used by the LWC flow.
