/**
 * Pure bookkeeping for order alerts (no Chrome APIs, unit-tested).
 *
 * alerts: { [orderId]: { summary, state: 'ringing'|'silenced', receivedAt, ringingSince } }
 *   An order stays here — and rings — while it still waits for the store; it
 *   leaves as soon as it is accepted, cancelled or gone (from any device or
 *   the app). Ringing can't be switched off: 'silenced' only covers the
 *   moment an accept is in flight, and a failed accept rings again.
 * seen:   { [orderId]: firstSeenMs } — one alert per order, ever (kept 3 days).
 */

export const SEEN_KEEP_MS = 3 * 24 * 60 * 60 * 1000;

export function isNew(state, orderId) {
  return !!orderId && !state.seen[orderId] && !state.alerts[orderId];
}

/** Adds a waiting order; it rings until it is handled. */
export function addAlert(state, summary, now = Date.now()) {
  const id = summary.orderId;
  return {
    seen: {...state.seen, [id]: now},
    alerts: {
      ...state.alerts,
      [id]: {summary, state: 'ringing', receivedAt: now, ringingSince: now},
    },
  };
}

/** Refreshes alerts from server summaries; returns ids no longer waiting. */
export function applySummaries(alerts, summaries) {
  const next = {...alerts};
  const resolved = [];
  for (const s of summaries) {
    if (!s || !next[s.orderId]) continue;
    if (!s.found || !s.incoming) {
      delete next[s.orderId];
      resolved.push(s.orderId);
    } else {
      next[s.orderId] = {...next[s.orderId], summary: s};
    }
  }
  return {alerts: next, resolved};
}

export function silence(alerts, orderId) {
  const a = alerts[orderId];
  if (!a || a.state === 'silenced') return alerts;
  return {...alerts, [orderId]: {...a, state: 'silenced', ringingSince: null}};
}

export function resolve(alerts, orderId) {
  if (!alerts[orderId]) return alerts;
  const next = {...alerts};
  delete next[orderId];
  return next;
}

/** Back to ringing (an accept that didn't go through). */
export function ringAgain(alerts, orderId, now = Date.now()) {
  const a = alerts[orderId];
  if (!a || a.state === 'ringing') return alerts;
  return {...alerts, [orderId]: {...a, state: 'ringing', ringingSince: now}};
}

/**
 * Every waiting order rings: also ones left 'silenced' by an older version
 * or by an accept that never reported back.
 */
export function ringAll(alerts, now = Date.now()) {
  let next = alerts;
  for (const id of Object.keys(alerts)) next = ringAgain(next, id, now);
  return next;
}

export function ringingIds(alerts) {
  return Object.entries(alerts)
      .filter(([, a]) => a.state === 'ringing')
      .map(([id]) => id);
}

export function activeIds(alerts) {
  return Object.keys(alerts);
}

export function pruneSeen(seen, now = Date.now(), keepMs = SEEN_KEEP_MS) {
  return Object.fromEntries(
      Object.entries(seen).filter(([, ms]) => now - ms < keepMs),
  );
}

/** Newest first, for the order card window and popup. */
export function sortedAlerts(alerts) {
  return Object.values(alerts).sort(
      (a, b) => (b.summary.createdAtMs || b.receivedAt) - (a.summary.createdAtMs || a.receivedAt),
  );
}
