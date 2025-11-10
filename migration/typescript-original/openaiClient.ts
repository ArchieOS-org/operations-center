import OpenAI from 'openai';

const apiKey = process.env.OPENAI_API_KEY || '';
if (!apiKey) {
  throw new Error('OPENAI_API_KEY missing');
}

// Optimized timeout: increase from 6s to 20s to reduce timeout failures
// CloudWatch shows 40% timeout rate with 60-120s latency, so 20s is reasonable middle ground
const timeoutMs = Number(process.env.LLM_TIMEOUT_MS || '20000');

// Reduce retries from 2 to 0 - we'll handle retries with exponential backoff in llmClassifier
// This avoids duplicate retry logic and gives us better control
const maxRetries = Number(process.env.LLM_MAX_RETRIES || '0');

const openai = new OpenAI({
  apiKey,
  timeout: timeoutMs,
  maxRetries,
  // Add default headers for better observability
  defaultHeaders: {
    'X-Client-Name': 'archieos-backend',
  },
});

export default openai;


