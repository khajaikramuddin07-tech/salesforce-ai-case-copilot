import { MockProvider } from './mockProvider.js';

export function createProvider(env = process.env) {
  const provider = env.AI_PROVIDER || 'mock';

  if (provider === 'mock') {
    return new MockProvider();
  }

  throw new Error(`Unsupported AI_PROVIDER: ${provider}`);
}
