const levels = ['debug', 'info', 'warn', 'error'];

export function createLogger(level = process.env.LOG_LEVEL || 'info') {
  const minIndex = levels.indexOf(level);

  function write(targetLevel, message, context = {}) {
    if (levels.indexOf(targetLevel) < minIndex) {
      return;
    }

    const entry = {
      level: targetLevel,
      message,
      timestamp: new Date().toISOString(),
      ...context
    };
    console.log(JSON.stringify(entry));
  }

  return {
    debug: (message, context) => write('debug', message, context),
    info: (message, context) => write('info', message, context),
    warn: (message, context) => write('warn', message, context),
    error: (message, context) => write('error', message, context)
  };
}
