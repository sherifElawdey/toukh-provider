/// Stable Firestore document id for a menu category from its display name.
String categoryKeyFromDisplayName(String displayName) {
  final trimmed = displayName.trim();
  if (trimmed.isEmpty) return 'general';

  final lower = trimmed.toLowerCase();
  final buf = StringBuffer();
  for (final rune in lower.runes) {
    final c = String.fromCharCode(rune);
    if (_isAllowedCategoryChar(rune)) {
      buf.write(c);
    } else if (buf.isNotEmpty && !buf.toString().endsWith('_')) {
      buf.write('_');
    }
  }
  var slug = buf.toString().replaceAll(RegExp(r'_+'), '_');
  slug = slug.replaceAll(RegExp(r'^_|_$'), '');
  if (slug.isEmpty) slug = 'general';
  if (slug.length > 120) slug = slug.substring(0, 120);
  return slug;
}

bool _isAllowedCategoryChar(int rune) {
  if (rune >= 0x30 && rune <= 0x39) return true; // 0-9
  if (rune >= 0x41 && rune <= 0x5a) return true; // A-Z (lower input)
  if (rune >= 0x61 && rune <= 0x7a) return true; // a-z
  if (rune >= 0x0600 && rune <= 0x06FF) return true; // Arabic
  return rune == 0x5f; // _
}

/// Picks a unique category doc id among [existingIds].
String uniqueCategoryKey(String displayName, Iterable<String> existingIds) {
  final base = categoryKeyFromDisplayName(displayName);
  final set = existingIds.toSet();
  if (!set.contains(base)) return base;
  var n = 2;
  while (set.contains('${base}_$n')) {
    n++;
  }
  return '${base}_$n';
}
