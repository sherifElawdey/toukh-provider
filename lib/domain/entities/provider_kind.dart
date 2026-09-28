enum ServiceType {
  homeService,
  supermarket,
  grocery,
  restaurant,
  homeBrands,
  pharmacy,
  otherShops;

  /// Client Other Shops list matches the literal `other_shops`, not `otherShops`.
  String get wireValue =>
      this == ServiceType.otherShops ? 'other_shops' : name;

  static ServiceType? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final value = raw.trim();
    if (value == 'other_shops' || value == 'otherShops') {
      return ServiceType.otherShops;
    }
    for (final v in ServiceType.values) {
      if (v.name == value || v.wireValue == value) return v;
    }
    return null;
  }
}
