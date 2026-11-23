/** base64url helpers (as the Firebase JS SDK encodes push keys and FIDs). */

export function bytesToBase64Url(bytes) {
  const arr = bytes instanceof ArrayBuffer ? new Uint8Array(bytes) : bytes;
  let bin = '';
  for (const b of arr) bin += String.fromCharCode(b);
  return btoa(bin).replace(/=+$/, '').replace(/\+/g, '-').replace(/\//g, '_');
}

export function base64UrlToBytes(s) {
  const padded = String(s).replace(/-/g, '+').replace(/_/g, '/') +
    '='.repeat((4 - (s.length % 4)) % 4);
  const bin = atob(padded);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

/** Firebase Installation ID: 17 random bytes, first 4 bits 0111, 22 chars. */
export function generateFid(random = (a) => crypto.getRandomValues(a)) {
  const bytes = random(new Uint8Array(17));
  bytes[0] = 0b01110000 + (bytes[0] % 0b00010000);
  return bytesToBase64Url(bytes).slice(0, 22);
}

export function randomId(len = 24) {
  return bytesToBase64Url(crypto.getRandomValues(new Uint8Array(len))).slice(0, len);
}
