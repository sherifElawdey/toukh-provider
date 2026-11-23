/**
 * Order-card window: every order still waiting for the store, newest first,
 * with the full details the OS notification has no room for.
 * Re-renders from chrome.storage whenever the service worker updates alerts.
 */
import {sortedAlerts} from '../lib/alertState.js';
import {agoLabel, addressLine, formatMoney, itemCountLabel, paymentLabel, timeLabel} from '../lib/format.js';
import {applyStaticText, command, h, setupLang} from '../ui/dom.js';

const $ = (id) => document.getElementById(id);
const {t, lang} = await setupLang();
applyStaticText(t);
document.title = `HAVIT · ${t('newOrder')}`;

const params = new URLSearchParams(location.search);
const focusId = params.get('order');
const testMode = params.get('test') === '1';

// Static icon paths (Phosphor-style, 24px grid).
const ICONS = {
  user: 'M12 12a5 5 0 1 0 0-10 5 5 0 0 0 0 10Zm0 2c-4.4 0-8 2.2-8 5v1h16v-1c0-2.8-3.6-5-8-5Z',
  pin: 'M12 2a7 7 0 0 0-7 7c0 5.2 7 13 7 13s7-7.8 7-13a7 7 0 0 0-7-7Zm0 9.5A2.5 2.5 0 1 1 12 6.5a2.5 2.5 0 0 1 0 5Z',
  store: 'M4 4h16l1 5a3 3 0 0 1-5 2.2A3 3 0 0 1 12 12a3 3 0 0 1-4-.8A3 3 0 0 1 3 9l1-5Zm1 9.5V20h14v-6.5a5 5 0 0 1-3-.6 5 5 0 0 1-4 .9 5 5 0 0 1-4-.9 5 5 0 0 1-3 .6Z',
  check: 'M9 16.2 4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2Z',
};

function icon(name) {
  const ns = 'http://www.w3.org/2000/svg';
  const svg = document.createElementNS(ns, 'svg');
  svg.setAttribute('viewBox', '0 0 24 24');
  svg.setAttribute('aria-hidden', 'true');
  const path = document.createElementNS(ns, 'path');
  path.setAttribute('d', ICONS[name]);
  path.setAttribute('fill', 'currentColor');
  svg.append(path);
  return svg;
}

function fact(name, label, ...content) {
  return h('div', {class: 'fact'}, icon(name), h('dt', {}, label), h('dd', {}, ...content));
}

const BLOCK_TEXT = {
  needs_quote: 'needsDashboard',
  system_managed: 'needsDashboard',
  open_in_dashboard: 'needsDashboard',
};

function orderCard(alert, {accepting, test}) {
  const s = alert.summary;
  const ringing = alert.state === 'ringing';
  const pay = paymentLabel(s, t);
  const card = h('article', {
    class: `card order${ringing ? ' ringing' : ''}${s.orderId === focusId ? ' focus' : ''}`,
    'aria-label': `${t('newOrder')} ${s.ref}`,
  });

  if (test) card.append(h('div', {class: 'test-ribbon'}, `${t('testTitle')} — ${t('testBody')}`));

  card.append(h('div', {class: 'order-head'},
      h('span', {class: 'badge-new'}, h('span', {class: 'live'}), t('newOrder')),
      h('span', {class: 'ref'}, s.ref),
      h('span', {class: 'when', title: timeLabel(s.createdAtMs, lang)},
          `${timeLabel(s.createdAtMs, lang)} · ${agoLabel(s.createdAtMs, t)}`),
  ));

  const body = h('div', {class: 'order-body'});
  if (s.businessName || s.branch) {
    body.append(h('div', {class: 'biz'},
        s.businessName ? h('strong', {}, h('bdi', {}, s.businessName)) : null,
        s.businessName && s.branch ? h('span', {'aria-hidden': 'true'}, '·') : null,
        s.branch ? h('span', {}, h('bdi', {}, s.branch)) : null));
  }

  body.append(h('div', {class: 'amount-row'},
      h('span', {class: 'amount'}, formatMoney(s.totalEgp, s.currency, lang)),
      pay ? h('span', {class: `chip ${s.paymentMethod === 'cash' ? 'warn' : 'ok'}`}, pay) : null,
      h('span', {class: 'count'}, itemCountLabel(s.itemCount || 0, t)),
  ));

  const facts = h('dl', {class: 'facts'});
  if (s.customerName || s.customerPhone) {
    const phone = s.customerPhone ?
      h('span', {class: 'phone-row'},
          h('span', {class: 'phone'}, s.customerPhone),
          h('button', {
            class: 'btn btn-ghost copy',
            type: 'button',
            onclick: async (e) => {
              await navigator.clipboard.writeText(s.customerPhone).catch(() => {});
              e.target.textContent = t('copied');
            },
          }, t('copy'))) :
      null;
    facts.append(fact('user', t('customer'),
        h('div', {}, h('bdi', {}, s.customerName || '')), phone));
  }
  if (s.fulfillmentMode === 'pickup') {
    facts.append(fact('store', t('address'), t('pickup')));
  } else if (s.address) {
    facts.append(fact('pin', t('address'), h('bdi', {}, addressLine(s))));
  }
  if (facts.childElementCount) body.append(facts);

  const items = Array.isArray(s.items) ? s.items : [];
  if (items.length) {
    const list = h('ul', {class: 'items'});
    for (const i of items) list.append(h('li', {}, h('span', {class: 'qty'}, `${i.quantity}×`), h('span', {}, h('bdi', {}, i.name))));
    const rest = (s.lineCount ?? items.length) - items.length;
    if (rest > 0) list.append(h('li', {class: 'more'}, t('more', {n: rest})));
    body.append(list);
  }
  if (s.note) body.append(h('div', {class: 'note'}, h('strong', {}, `${t('note')}: `), h('bdi', {}, s.note)));
  card.append(body);

  const actions = h('div', {class: 'order-actions'});
  if (!test && s.canAccept) {
    actions.append(h('button', {
      class: 'btn btn-success btn-lg',
      type: 'button',
      disabled: accepting,
      onclick: () => command('accept', {orderId: s.orderId}).catch(() => {}),
    }, accepting ? t('accepting') : t('accept')));
  } else if (!test && s.acceptBlockReason && BLOCK_TEXT[s.acceptBlockReason]) {
    actions.append(h('p', {class: 'block-note'}, t(BLOCK_TEXT[s.acceptBlockReason], {ref: s.ref})));
  }
  actions.append(h('button', {
    class: 'btn btn-primary',
    type: 'button',
    disabled: test,
    onclick: () => command('view', {orderId: s.orderId}).catch(() => {}),
  }, t('viewOrder')));
  card.append(actions);
  return card;
}

function testAlert() {
  return {
    state: 'ringing',
    summary: {
      orderId: 'test',
      ref: '#TEST01',
      createdAtMs: Date.now(),
      businessName: null,
      customerName: lang === 'ar' ? 'أحمد محمود' : 'Ahmed Mahmoud',
      totalEgp: 185,
      currency: 'EGP',
      paymentMethod: 'cash',
      itemCount: 3,
      lineCount: 2,
      items: lang === 'ar' ?
        [{name: 'كشري كبير', quantity: 2}, {name: 'عصير مانجو', quantity: 1}] :
        [{name: 'Large koshari', quantity: 2}, {name: 'Mango juice', quantity: 1}],
      address: {title: lang === 'ar' ? 'البيت' : 'Home', formattedAddress: lang === 'ar' ? 'شارع ٩، المعادي' : '9 Street, Maadi'},
      note: null,
    },
  };
}

async function render() {
  const {alerts = {}, accepting = {}, store} = await chrome.storage.local.get(['alerts', 'accepting', 'store']);
  const list = sortedAlerts(alerts);
  $('subtitle').textContent = list.length === 0 ?
    store?.name || t('tagline') :
    list.length === 1 ? t('oneActiveOrder') : t('activeOrders', {n: list.length});

  const root = $('list');
  root.replaceChildren();
  if (testMode) {
    const sample = testAlert();
    sample.summary.businessName = store?.name || null;
    root.append(orderCard(sample, {accepting: false, test: true}));
  }
  for (const a of list) root.append(orderCard(a, {accepting: !!accepting[a.summary.orderId], test: false}));
  if (!testMode && list.length === 0) {
    root.append(h('div', {class: 'empty'}, icon('check'), h('p', {}, t('pendingNone'))));
  }
  document.querySelector('.order.focus')?.scrollIntoView({block: 'nearest'});
}

$('open-dashboard').addEventListener('click', () => command('openDashboard').catch(() => {}));

let pending = null;
chrome.storage.onChanged.addListener((changes, area) => {
  if (area !== 'local' || !('alerts' in changes || 'accepting' in changes || 'store' in changes)) return;
  clearTimeout(pending);
  pending = setTimeout(render, 30);
});
// Keep "x min ago" current.
setInterval(render, 30000);

await render();
