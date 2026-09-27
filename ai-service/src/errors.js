export class ValidationError extends Error {
  constructor(message, details = []) {
    super(message);
    this.name = 'ValidationError';
    this.details = details;
    this.statusCode = 400;
  }
}

export class ProviderError extends Error {
  constructor(message, cause) {
    super(message);
    this.name = 'ProviderError';
    this.cause = cause;
    this.statusCode = 502;
  }
}
