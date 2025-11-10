/**
 * Slack integration routes.
 *
 * Provides Slack event ingestion and command endpoints. Verifies signatures
 * when SLACK_BYPASS_VERIFY is false. Emits audit events on certain actions.
 */
import type { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';
import { metricsClient, metricsRegister } from '../plugins/metrics';
import { verifySlackSignature } from '../services/slackVerify';
import { createDeduper } from '@services/slackDedup';

function shouldBypass(): boolean {
  // Development mode: skip signature verification entirely (fastest iteration)
  if (process.env.NODE_ENV === 'development') {
    return true;
  }

  // Legacy bypass flag (for backwards compatibility)
  if ((process.env.SLACK_BYPASS_VERIFY || '').toLowerCase() === 'true') {
    return true;
  }

  // Local alias for development
  if (process.env.NODE_ENV === 'local') {
    return true;
  }

  return false;
}

function getSigningSecret(): string {
  // In test mode, use test secret if provided (more realistic testing)
  if (process.env.NODE_ENV === 'test' && process.env.SLACK_SIGNING_SECRET_TEST) {
    return process.env.SLACK_SIGNING_SECRET_TEST;
  }

  // Otherwise use production secret
  return process.env.SLACK_SIGNING_SECRET || '';
}

async function verifyOr401(req: FastifyRequest, reply: FastifyReply, rawBody: string): Promise<boolean> {
  if (shouldBypass()) return true;
  const secret = getSigningSecret();
  const sig = (req.headers['x-slack-signature'] as string) || '';
  const ts = (req.headers['x-slack-request-timestamp'] as string) || '';
  const ok = secret && sig && ts && verifySlackSignature(secret, ts, rawBody, sig);
  if (!ok) {
    await reply.code(401).send({ error: 'invalid signature' });
    return false;
  }
  return true;
}

function normalizeEvent(body: any): { type: string; text?: string; user?: string; channel?: string; event_id?: string | number } | null {
  if (body?.type === 'event_callback' && body.event) {
    const ev = body.event;
    if (ev.type === 'app_mention') return { type: 'app_mention', text: ev.text, user: ev.user, channel: ev.channel, event_id: body.event_id };
    if (ev.type === 'message' && (ev.channel_type === 'channel' || ev.channel_type === 'group')) {
      const typeLabel = ev.channel_type === 'group' ? 'message.groups' : 'message.channels';
      return { type: typeLabel, text: ev.text, user: ev.user, channel: ev.channel, event_id: body.event_id };
    }
  }
  if (body?.type === 'shortcut') return { type: 'shortcut', text: body.callback_id, user: body.user?.id };
  return null;
}

async function ingest(payload: any) {
  // Stub ingestion: write to audit log for visibility
  const { putAuditEvent } = await import('../db/audit_log');
  await putAuditEvent({
    entity_id: 'slack-intake',
    entity_type: 'external',
    action: payload.type || 'unknown',
    content: JSON.stringify(payload),
    performed_by: payload.user || 'slack',
  });
}

export default async function slackRoutes(app: FastifyInstance) {
  const slackCounters = lazyMetrics();
  const deduper = createDeduper({ ttlSeconds: Number(process.env.SLACK_DEDUP_TTL_SECONDS || 900) });

  // Raw body capture
  app.addContentTypeParser('application/json', { parseAs: 'string' }, (req, body: string, done) => {
    try {
      (req as any).rawBody = body;
      done(null, JSON.parse(body || '{}'));
    } catch (err) {
      done(err as Error, undefined as any);
    }
  });

  app.addContentTypeParser('text/plain', { parseAs: 'string' }, (req, body: string, done) => {
    try {
      (req as any).rawBody = body;
      const parsed = body && body.trim().startsWith('{') ? JSON.parse(body) : { text: body };
      done(null, parsed);
    } catch (err) {
      done(err as Error, undefined as any);
    }
  });

  app.addContentTypeParser('application/x-www-form-urlencoded', { parseAs: 'string' }, (req, body: string, done) => {
    try {
      (req as any).rawBody = body;
      let parsed: any = {};
      if (body && body.trim().length > 0) {
        if (body.startsWith('payload=')) {
          const v = body.slice('payload='.length);
          const json = decodeURIComponent(v.replace(/\+/g, '%20'));
          parsed = JSON.parse(json);
        } else {
          const params = new URLSearchParams(body);
          params.forEach((val, key) => {
            parsed[key] = val;
          });
        }
      }
      done(null, parsed);
    } catch (err) {
      done(err as Error, undefined as any);
    }
  });

  app.post('/slack/events', async (req, reply) => {
    const raw = (req as any).rawBody || '';
    const start = process.hrtime.bigint();
    try {
      app.log.info({ event: 'slack.events.received', rawLength: typeof raw === 'string' ? raw.length : 0 }, 'Slack event received');
    } catch {}
    if (!(await verifyOr401(req, reply, raw))) return;
    const body: any = req.body || {};
    const retryNumHeader = req.headers['x-slack-retry-num'];
    const retryReason = req.headers['x-slack-retry-reason'];
    if (body.type === 'url_verification' && body.challenge) {
      slackCounters.eventsTotal.inc({ type: 'url_verification' });
      return reply.send({ challenge: body.challenge });
    }

    if (await deduper.isDuplicate(body, req.headers)) {
      slackCounters.dedupeHits.inc({ endpoint: 'events' });
      reply.header('x-slack-ignored-retry', 'true');
      slackCounters.acksTotal.inc({ endpoint: 'events', result: 'dedup' });
      return reply.send({ ok: true });
    }

    // Ack immediately to avoid Slack retries
    // Persist minimal state before acking
    try {
      const norm = normalizeEvent(body);
      if (norm) {
        await ingest(norm); // ensure we’ve persisted something before acking
        app.log.info({ event: 'slack.events.ingested.preAck', type: norm.type }, 'Ingested minimal event before ack');
      }
    } catch (e) {
      app.log.error({ event: 'slack.events.ingest.error', err: e instanceof Error ? e.message : e }, 'Pre-ack ingest error');
    }

    // Ack quickly after the durable write
    reply.send({ ok: true });
    recordAck(slackCounters, start, 'events', { retryNumHeader, retryReason, body });

    // Fire-and-forget background processing with debounce buffer
    void (async () => {
      try {
        const { messageDebounceBuffer } = await import('../services/debounceBuffer');
        const norm = normalizeEvent(body);
        app.log.info({
          event: 'slack.debounce.enqueue.start',
          eventType: norm?.type,
          user: norm?.user,
          channel: norm?.channel,
          hasText: !!norm?.text
        }, 'Enqueueing to debounce buffer');

        await messageDebounceBuffer.enqueue(body);

        app.log.info({
          event: 'slack.debounce.enqueued',
          eventType: norm?.type
        }, 'Message enqueued to debounce buffer successfully');
      } catch (err) {
        app.log.error({
          event: 'slack.debounce.exception',
          errorType: err?.constructor?.name || typeof err,
          error: err instanceof Error ? err.message : String(err),
          stack: err instanceof Error ? err.stack : undefined
        }, 'Debounce buffer enqueue threw exception');
      }
    })();

    return;
  });

  app.post('/slack/interact', async (req, reply) => {
    const raw = (req as any).rawBody || '';
    const start = process.hrtime.bigint();
    if (!(await verifyOr401(req, reply, raw))) return;
    const body = req.body as any;
    const retryNumHeader = req.headers['x-slack-retry-num'];
    const retryReason = req.headers['x-slack-retry-reason'];

    if (await deduper.isDuplicate(body, req.headers)) {
      slackCounters.dedupeHits.inc({ endpoint: 'interact' });
      reply.header('x-slack-ignored-retry', 'true');
      slackCounters.acksTotal.inc({ endpoint: 'interact', result: 'dedup' });
      return reply.send({ ok: true });
    }

    // Pre-ack ingestion for audit/visibility, but do not block ack on downstream work
    try {
      const norm = normalizeEvent(body);
      if (norm) await ingest(norm);
    } catch (err) {
      app.log.error({ event: 'slack.interact.ingest.error', err: err instanceof Error ? err.message : err }, 'Failed to store slack interactivity payload pre-ack');
    }

    slackCounters.acksTotal.inc({ endpoint: 'interact', result: 'ok' });
    recordAck(slackCounters, start, 'interact', { retryNumHeader, retryReason, body });
    reply.send({ ok: true });

    void processInteract(body, app);
  });
}

async function processInteract(body: any, app: FastifyInstance) {
  try {
    const { messageDebounceBuffer } = await import('../services/debounceBuffer');
    await messageDebounceBuffer.enqueue(body);
    app.log.info({ event: 'slack.interact.debounce.enqueued' }, 'Interactivity message enqueued to debounce buffer');
  } catch (err) {
    app.log.warn({ event: 'slack.interact.debounce.error', err: err instanceof Error ? err.message : err }, 'Interactivity debounce buffer enqueue failed');
  }
}

type SlackMetrics = {
  eventsTotal: import('prom-client').Counter<'type'>;
  acksTotal: import('prom-client').Counter<'endpoint' | 'result'>;
  ackDuration: import('prom-client').Histogram<'endpoint'>;
  dedupeHits: import('prom-client').Counter<'endpoint'>;
  retryTotal: import('prom-client').Counter<'endpoint' | 'reason'>;
};

let metricsCache: SlackMetrics | null = null;

function lazyMetrics(): SlackMetrics {
  if (metricsCache) return metricsCache;
  const eventsTotal = new metricsClient.Counter({
    name: 'slack_events_received_total',
    help: 'Slack events received',
    labelNames: ['type'],
    registers: [metricsRegister],
  });
  const acksTotal = new metricsClient.Counter({
    name: 'slack_ack_total',
    help: 'Slack acknowledgements sent',
    labelNames: ['endpoint', 'result'],
    registers: [metricsRegister],
  });
  const ackDuration = new metricsClient.Histogram({
    name: 'slack_ack_duration_seconds',
    help: 'Slack acknowledgement latency in seconds',
    labelNames: ['endpoint'],
    buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2, 3],
    registers: [metricsRegister],
  });
  const dedupeHits = new metricsClient.Counter({
    name: 'slack_dedup_hits_total',
    help: 'Slack deduplication hits',
    labelNames: ['endpoint'],
    registers: [metricsRegister],
  });
  const retryTotal = new metricsClient.Counter({
    name: 'slack_retries_total',
    help: 'Slack retry headers received',
    labelNames: ['endpoint', 'reason'],
    registers: [metricsRegister],
  });
  metricsCache = { eventsTotal, acksTotal, ackDuration, dedupeHits, retryTotal };
  return metricsCache;
}

function recordAck(metrics: SlackMetrics, start: bigint, endpoint: 'events' | 'interact', context: { retryNumHeader?: any; retryReason?: any; body: any }) {
  const durationSeconds = Number(process.hrtime.bigint() - start) / 1e9;
  metrics.ackDuration.observe({ endpoint }, durationSeconds);
  if (context.retryReason) {
    metrics.retryTotal.inc({ endpoint, reason: String(context.retryReason) });
  }
  const norm = normalizeEvent(context.body);
  if (norm?.type) {
    metrics.eventsTotal.inc({ type: norm.type });
  }
}


