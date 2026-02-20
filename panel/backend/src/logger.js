const LOG_LEVEL = (process.env.LOG_LEVEL || 'info').toLowerCase();
const LEVELS = { error: 0, warn: 1, info: 2, debug: 3 };

function log(level, message, meta = {}) {
  if (LEVELS[level] == null || LEVELS[level] > LEVELS[LOG_LEVEL]) return;
  const entry = {
    time: new Date().toISOString(),
    level,
    msg: message,
    ...meta,
  };
  console.log(JSON.stringify(entry));
}

module.exports = {
  error: (msg, meta) => log('error', msg, meta),
  warn: (msg, meta) => log('warn', msg, meta),
  info: (msg, meta) => log('info', msg, meta),
  debug: (msg, meta) => log('debug', msg, meta),
};
