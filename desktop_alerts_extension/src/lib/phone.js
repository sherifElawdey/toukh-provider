/**
 * Same login the HAVIT Partner app uses: the login screen turns the typed
 * number into E.164 with `egyptMobileE164` (lib/core/utils/phone_e164.dart),
 * then `syntheticEmailFromPhone` makes `provider{digits}@toukh.com`.
 */

/** `01012345678`, `1012345678`, `+201012345678` → `+201012345678`, else ''. */
export function egyptMobileE164(input) {
  let d = String(input ?? '').replace(/\D/g, '');
  // Also accept a pasted international number (the app's field takes national).
  if (d.length === 12 && d.startsWith('20')) d = d.slice(2);
  if (d.length === 11 && d.startsWith('0')) d = d.slice(1);
  // Egyptian mobiles are 1X XXXX XXXX; anything else can't be a store login.
  if (!/^1\d{9}$/.test(d)) return '';
  return `+20${d}`;
}

export function syntheticEmail(e164, domain = 'toukh.com') {
  const digits = String(e164).replace(/\D/g, '');
  if (!digits) throw new Error('Phone must contain digits');
  return `provider${digits}@${domain}`;
}

/** `+201012345678` → `01012345678` for display. */
export function localPhone(e164) {
  const d = String(e164 ?? '').replace(/\D/g, '');
  if (d.length === 12 && d.startsWith('20')) return `0${d.slice(2)}`;
  return d;
}
