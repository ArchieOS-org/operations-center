/**
 * Lightweight in-memory deduplication for Slack deliveries.
 *
 * Slack retries Events API and Interactivity requests when an ack is not
 * received within ~3 seconds or when a non-2xx response is returned. The
 * retry payloads are identical and include headers identifying the retry
 * attempt (`x-slack-retry-num`, `x-slack-retry-reason`). Slack also provides
 * stable identifiers within the payload (`event_id` for Events API and a
 * combination of team/channel/timestamps for interactivity).
 *
 * This deduper stores recently seen identifiers with a TTL (default 15
 * minutes) to avoid double-processing when Slack retries a request due to a
 * transient failure.
 */

type DeduperOptions = {
  ttlSeconds?: number;
  maxEntries?: number;
};

type SlackHeaders = Record<string, unknown> | undefined;

export type SlackDeduper = {
  isDuplicate(body: unknown, headers?: SlackHeaders): Promise<boolean>;
  size(): number;
};

const DEFAULT_TTL_SECONDS = 15 * 60; // 15 minutes
const DEFAULT_MAX_ENTRIES = 5000;

const IGNORED_EVENT_TYPES = new Set(['url_verification']);

export function createDeduper(options: DeduperOptions = {}): SlackDeduper {
  const ttlMillis = Math.max(1, Math.floor((options.ttlSeconds ?? DEFAULT_TTL_SECONDS) * 1000));
  const maxEntries = Math.max(1, options.maxEntries ?? DEFAULT_MAX_ENTRIES);

  const store = new Map<string, number>();

  function prune(now: number) {
    for (const [key, expiresAt] of store) {
      if (expiresAt <= now) {
        store.delete(key);
      }
    }
  }

  function ensureCapacity() {
    while (store.size > maxEntries) {
      const oldest = store.keys().next().value as string | undefined;
      if (!oldest) break;
      store.delete(oldest);
    }
  }

  async function isDuplicate(body: unknown, headers?: SlackHeaders): Promise<boolean> {
    const key = dedupeKeyFromPayload(body);
    if (!key) return false;

    const now = Date.now();
    prune(now);

    const existing = store.get(key);
    if (existing && existing > now) {
      return true;
    }

    store.set(key, now + ttlMillis);
    ensureCapacity();
    return false;
  }

  return {
    isDuplicate,
    size() {
      return store.size;
    },
  };
}

function dedupeKeyFromPayload(body: unknown): string | undefined {
  if (!body || typeof body !== 'object') return undefined;
  const payload = body as Record<string, any>;

  if (typeof payload.type === 'string' && IGNORED_EVENT_TYPES.has(payload.type)) {
    return undefined;
  }

  if (payload.type === 'event_callback') {
    if (typeof payload.event_id === 'string' && payload.event_id.length > 0) {
      return `event:${payload.event_id}`;
    }
    const event = payload.event as Record<string, any> | undefined;
    if (event) {
      const teamId = payload.team_id || event.team;
      const channel = event.channel;
      const clientMsgId = event.client_msg_id;
      const ts = event.event_ts || event.ts || payload.event_ts;
      const fallbackParts = [teamId, event.type, channel, clientMsgId, ts].filter(Boolean);
      if (fallbackParts.length) {
        return `event:${fallbackParts.join(':')}`;
      }
    }
    return undefined;
  }

  // Interactivity / shortcuts payloads
  const type = typeof payload.type === 'string' ? payload.type : undefined;
  if (!type) return undefined;

  const teamId = extractTeamId(payload);
  const channelId = payload.channel?.id || payload.channel?.name || payload.container?.channel_id;
  const messageTs = payload.message?.ts || payload.container?.message_ts;
  const actionTs = payload.action_ts || payload.actions?.[0]?.action_ts;
  const viewId = payload.view?.id || payload.view?.external_id;
  const callbackId = payload.callback_id || payload.view?.callback_id;
  const triggerId = payload.trigger_id;
  const userId = payload.user?.id;

  const parts = [type, teamId, channelId, messageTs, actionTs, viewId, callbackId, triggerId, userId].filter(Boolean);
  if (!parts.length) return undefined;
  return `interact:${parts.join(':')}`;
}

function extractTeamId(payload: Record<string, any>): string | undefined {
  return (
    payload.team?.id ||
    payload.team?.domain ||
    payload.team_id ||
    payload.user?.team_id ||
    payload.authorizations?.[0]?.team_id ||
    undefined
  );
}

