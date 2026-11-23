/**
 * The smaller prompt shown when the order card is closed while orders still
 * wait: accept, decline (confirmed once), or open the order's details.
 * The service worker closes it once nothing waits.
 */
import {sortedAlerts} from '../lib/alertState.js';
import {formatMoney, itemCountLabel} from '../lib/format.js';
import {applyStaticText, command, h, setupLang} from '../ui/dom.js';

const $ = (id) => document.getElementById(id);
const {t, lang} = await setupLang();
applyStaticText(t);

const MAX_SHOWN = 3;
let confirming = null; // orderId whose decline is being confirmed

function orderRow(alert, busy) {
  const s = alert.summary;
  const row = h('section', {class: 'row-order', 'aria-label': s.ref});
  row.append(h('div', {class: 'summary'},
      h('span', {class: 'ref'}, s.ref),
      h('span', {class: 'amount'}, formatMoney(s.totalEgp, s.currency, lang)),
      h('span', {class: 'meta'},
          s.customerName ? h('bdi', {}, s.customerName) : null,
          s.customerName ? ' · ' : null,
          itemCountLabel(s.itemCount || 0, t)),
  ));

  const details = h('button', {
    class: 'btn btn-secondary btn-details',
    type: 'button',
    onclick: () => command('view', {orderId: s.orderId}).catch(() => {}),
  }, t('orderDetails'));

  if (!s.canAccept) {
    // Pharmacy quotes and other app-only orders are handled in the dashboard.
    row.append(h('p', {class: 'note'}, t('needsDashboard', {ref: s.ref})), details);
    return row;
  }

  if (confirming === s.orderId) {
    row.append(h('div', {class: 'confirm', role: 'alertdialog'},
        h('span', {}, t('declineConfirm', {ref: s.ref})),
        h('div', {class: 'actions'},
            h('button', {
              class: 'btn btn-danger',
              type: 'button',
              disabled: !!busy,
              onclick: async () => {
                confirming = null;
                await command('decline', {orderId: s.orderId}).catch(() => {});
              },
            }, busy === 'decline' ? t('declining') : t('declineYes')),
            h('button', {
              class: 'btn btn-secondary',
              type: 'button',
              onclick: () => {
                confirming = null;
                render();
              },
            }, t('back')))));
    return row;
  }

  row.append(h('div', {class: 'actions'},
      h('button', {
        class: 'btn btn-success',
        type: 'button',
        disabled: !!busy,
        onclick: () => command('accept', {orderId: s.orderId}).catch(() => {}),
      }, busy === 'accept' ? t('accepting') : t('accept')),
      h('button', {
        class: 'btn btn-decline',
        type: 'button',
        disabled: !!busy,
        onclick: () => {
          confirming = s.orderId;
          render();
        },
      }, busy === 'decline' ? t('declining') : t('decline')),
      details));
  return row;
}

/** Sizes the window to its content (within the screen). */
async function fitWindow() {
  try {
    const win = await chrome.windows.getCurrent();
    const chrome_ = window.outerHeight - window.innerHeight;
    const want = Math.min(screen.availHeight - 40, document.body.scrollHeight + chrome_);
    if (Math.abs(win.height - want) > 4) await chrome.windows.update(win.id, {height: want});
  } catch (_) {
    // not fatal
  }
}

async function render() {
  const {alerts = {}, accepting = {}} = await chrome.storage.local.get(['alerts', 'accepting']);
  const list = sortedAlerts(alerts);
  if (list.length === 0) {
    window.close();
    return;
  }
  $('title').textContent = list.length === 1 ? t('reminderTitle') : t('reminderTitleMany', {n: list.length});
  document.title = `HAVIT · ${$('title').textContent}`;
  if (confirming && !alerts[confirming]) confirming = null;
  $('list').replaceChildren(...list.slice(0, MAX_SHOWN).map((a) => orderRow(a, accepting[a.summary.orderId])));
  $('footer').hidden = list.length <= 1;
  await fitWindow();
}

$('show-all').addEventListener('click', () => command('openOrders').catch(() => {}));

let pending = null;
chrome.storage.onChanged.addListener((changes, area) => {
  if (area !== 'local' || !('alerts' in changes || 'accepting' in changes)) return;
  clearTimeout(pending);
  pending = setTimeout(render, 30);
});

await render();
