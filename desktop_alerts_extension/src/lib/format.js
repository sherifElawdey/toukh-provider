/** Text for notifications and order cards, from a `getDesktopOrderAlerts` summary. */

export function formatMoney(amount, currency = 'EGP', lang = 'en') {
  const n = Number(amount) || 0;
  const num = new Intl.NumberFormat(lang === 'ar' ? 'ar-EG-u-nu-latn' : 'en-EG', {
    maximumFractionDigits: Number.isInteger(n) ? 0 : 2,
  }).format(n);
  const unit = currency === 'EGP' ? (lang === 'ar' ? 'ج.م' : 'EGP') : currency;
  return `${num} ${unit}`;
}

export function paymentKey(summary) {
  const m = String(summary?.paymentMethod || '').toLowerCase();
  return ['cash', 'wallet', 'wallets', 'card'].includes(m) ? `pay_${m}` : null;
}

/** "Cash on delivery" / "Paid · HAVIT Pay". */
export function paymentLabel(summary, t) {
  const key = paymentKey(summary);
  const method = key ? t(key) : '';
  if (summary?.paymentMethod === 'cash' || !summary?.isPaid) return method;
  return method ? `${t('paid')} · ${method}` : t('paid');
}

export function itemCountLabel(n, t) {
  return n === 1 ? t('item') : t('items', {n});
}

export function timeLabel(ms, lang = 'en') {
  if (!ms) return '';
  return new Intl.DateTimeFormat(lang === 'ar' ? 'ar-EG-u-nu-latn' : 'en-GB', {
    hour: 'numeric',
    minute: '2-digit',
  }).format(new Date(ms));
}

export function agoLabel(ms, t, now = Date.now()) {
  if (!ms) return '';
  const min = Math.floor((now - ms) / 60000);
  return min < 1 ? t('justNow') : t('minutesAgo', {n: min});
}

/** "2× Koshari, 1× Juice, +1 more" (Arabic comma in Arabic). */
export function itemsLine(summary, t, max = 3, lang = 'en') {
  const items = Array.isArray(summary?.items) ? summary.items : [];
  const shown = items.slice(0, max).map((i) => `${i.quantity}× ${i.name}`);
  const rest = (summary?.lineCount ?? items.length) - shown.length;
  if (rest > 0) shown.push(t('more', {n: rest}));
  return shown.join(lang === 'ar' ? '، ' : ', ');
}

export function addressLine(summary) {
  const a = summary?.address;
  if (!a) return '';
  return [a.title, a.formattedAddress, a.buildingNumber, a.landmark]
      .filter(Boolean)
      .join(' · ');
}

/**
 * Native notification text. Chrome shows title + message + contextMessage on
 * every OS; buttons sit under "Options" on macOS. The phone number stays off
 * the OS notification (it can show on a lock screen); the order card has it.
 */
export function orderNotificationText(summary, t, lang) {
  const total = formatMoney(summary.totalEgp, summary.currency, lang);
  const pay = paymentLabel(summary, t);
  const first = [
    summary.customerName,
    itemCountLabel(summary.itemCount || 0, t),
    pay ? `${total} · ${pay}` : total,
  ].filter(Boolean).join(' · ');
  const lines = [first, itemsLine(summary, t, 3, lang)];
  if (summary.fulfillmentMode === 'pickup') lines.push(t('pickup'));
  else if (summary.address?.formattedAddress) lines.push(summary.address.formattedAddress);
  return {
    title: `${t('newOrder')} · ${summary.ref}`,
    message: lines.filter(Boolean).join('\n'),
    contextMessage: [summary.businessName, timeLabel(summary.createdAtMs, lang)]
        .filter(Boolean).join(' · '),
  };
}

/**
 * When the live summary can't be fetched, build one from the push itself
 * (`payloadJson` from buildProviderNewOrderTemplate).
 */
export function summaryFromPush(data) {
  let p = {};
  try {
    p = JSON.parse(data?.payloadJson || '{}') || {};
  } catch (_) {
    p = {};
  }
  const orderId = String(data?.orderId || p.orderId || '');
  const items = Array.isArray(p.items) ? p.items : [];
  const id = orderId.trim();
  return {
    orderId,
    found: true,
    partial: true,
    ref: `#${(id.length > 6 ? id.slice(-6) : id).toUpperCase()}`,
    status: 'placed',
    incoming: true,
    canAccept: p.orderKind !== 'pharmacy_request',
    acceptBlockReason: p.orderKind === 'pharmacy_request' ? 'needs_quote' : null,
    orderKind: p.orderKind || 'standard',
    createdAtMs: Date.now(),
    businessName: null,
    totalEgp: Number(p.totalEgp) || 0,
    currency: 'EGP',
    paymentMethod: null,
    customerName: p.customerName || null,
    itemCount: items.reduce((n, i) => n + (Number(i.quantity) || 1), 0),
    lineCount: items.length,
    items: items.slice(0, 6).map((i) => ({name: String(i.name || ''), quantity: Number(i.quantity) || 1})),
  };
}
