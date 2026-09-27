import http from 'node:http';
import { createLogger } from './logger.js';
import { analyzeCase } from './orchestrator.js';
import { createProvider } from './providers/providerFactory.js';

const logger = createLogger();
const provider = createProvider();

async function readJson(request) {
  const chunks = [];
  for await (const chunk of request) {
    chunks.push(chunk);
  }

  const rawBody = Buffer.concat(chunks).toString('utf8');
  return rawBody ? JSON.parse(rawBody) : {};
}

function sendJson(response, statusCode, payload) {
  response.writeHead(statusCode, { 'content-type': 'application/json' });
  response.end(JSON.stringify(payload));
}

export function createServer() {
  return http.createServer(async (request, response) => {
    if (request.method === 'GET' && request.url === '/health') {
      sendJson(response, 200, { status: 'ok' });
      return;
    }

    if (request.method !== 'POST' || request.url !== '/analyze') {
      sendJson(response, 404, { error: 'Not found' });
      return;
    }

    try {
      const body = await readJson(request);
      const result = await analyzeCase(body, provider, logger);
      sendJson(response, 200, result);
    } catch (error) {
      logger.error('Request failed', {
        name: error.name,
        message: error.message,
        details: error.details
      });

      sendJson(response, error.statusCode || 500, {
        error: error.name || 'Error',
        message: error.message,
        details: error.details || []
      });
    }
  });
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const port = Number(process.env.PORT || 3000);
  createServer().listen(port, () => {
    logger.info('AI Case Copilot service listening', { port });
  });
}
