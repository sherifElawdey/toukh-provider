enum ProviderAccountStatus {
  unverified,
  pending,
  active,
  blocked,
  deleted;

  String get wireValue => name;

  static ProviderAccountStatus? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final v in ProviderAccountStatus.values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}
