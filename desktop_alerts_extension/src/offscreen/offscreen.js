/**
 * Plays the alert sound for the service worker. `start` repeats it every
 * `periodMs` (start to start; a tone longer than that replays as soon as it
 * ends) until `stop`; `once` plays a single time without touching the loop.
 */
const ringer = new Audio();
const oneShot = new Audio();
let looping = false;
let repeat = false;
let periodMs = 5000;
let gapTimer = null;
let startedAt = 0;

function playRinger() {
  clearTimeout(gapTimer);
  ringer.currentTime = 0;
  startedAt = Date.now();
  ringer.play().catch(() => {});
}

ringer.addEventListener('ended', () => {
  if (looping && repeat) {
    gapTimer = setTimeout(playRinger, Math.max(0, periodMs - (Date.now() - startedAt)));
  } else {
    looping = false;
  }
});

chrome.runtime.onMessage.addListener((msg, _sender, reply) => {
  if (msg?.target !== 'offscreen') return false;
  switch (msg.type) {
    case 'start': {
      const changed = ringer.src !== msg.src;
      ringer.volume = clamp(msg.volume);
      repeat = msg.repeat !== false;
      periodMs = Math.max(1000, Number(msg.periodMs) || 5000);
      if (changed) ringer.src = msg.src;
      // Already ringing the same sound: just keep the new settings.
      if (!looping || changed) {
        looping = true;
        playRinger();
      }
      break;
    }
    case 'stop':
      looping = false;
      clearTimeout(gapTimer);
      ringer.pause();
      ringer.currentTime = 0;
      oneShot.pause();
      break;
    case 'once':
      oneShot.src = msg.src;
      oneShot.volume = clamp(msg.volume);
      oneShot.currentTime = 0;
      oneShot.play().catch(() => {});
      break;
  }
  reply({ok: true});
  return false;
});

/** Read-only snapshot for diagnostics and the end-to-end test. */
globalThis.havitSoundState = () => ({
  looping,
  repeat,
  periodMs,
  src: ringer.src,
  volume: ringer.volume,
  playing: !ringer.paused,
});

function clamp(v) {
  const n = Number(v);
  return Number.isFinite(n) ? Math.min(1, Math.max(0, n)) : 0.8;
}
