/**
 * Alert sound via an offscreen document (MV3 service workers can't play
 * audio). Sound is mandatory: it repeats every `repeatEverySec` (5 s) while
 * any order waits. Chrome closes an AUDIO_PLAYBACK document after ~30 s of
 * silence, so the document is recreated on demand.
 */
import {SOUNDS} from './storage.js';

const OFFSCREEN_URL = 'src/offscreen/offscreen.html';
let creating = null;

async function hasOffscreen() {
  const contexts = await chrome.runtime.getContexts({
    contextTypes: ['OFFSCREEN_DOCUMENT'],
    documentUrls: [chrome.runtime.getURL(OFFSCREEN_URL)],
  });
  return contexts.length > 0;
}

async function ensureOffscreen() {
  if (await hasOffscreen()) return;
  creating ??= chrome.offscreen.createDocument({
    url: OFFSCREEN_URL,
    reasons: ['AUDIO_PLAYBACK'],
    justification: 'Plays the HAVIT new-order alert sound.',
  }).catch((e) => {
    if (!/single offscreen/i.test(String(e?.message))) throw e;
  }).finally(() => {
    creating = null;
  });
  await creating;
}

async function send(message) {
  await ensureOffscreen();
  try {
    await chrome.runtime.sendMessage({target: 'offscreen', ...message});
  } catch (_) {
    // Document still loading: one retry.
    await new Promise((r) => setTimeout(r, 150));
    await chrome.runtime.sendMessage({target: 'offscreen', ...message});
  }
}

/** Rings, repeating, while orders wait; idempotent (picks up tone/volume changes). */
export async function startRinging(settings) {
  await send({
    type: 'start',
    src: chrome.runtime.getURL(SOUNDS[settings.sound] || SOUNDS.ring),
    volume: settings.volume,
    repeat: true,
    periodMs: (settings.repeatEverySec || 5) * 1000,
  });
}

export async function stopRinging() {
  if (!(await hasOffscreen())) return;
  await chrome.runtime.sendMessage({target: 'offscreen', type: 'stop'}).catch(() => {});
}

/** One play, for tests and secondary alerts. */
export async function playOnce(settings, sound = settings.sound) {
  await send({
    type: 'once',
    src: chrome.runtime.getURL(SOUNDS[sound] || SOUNDS.notify),
    volume: settings.volume,
  });
}
