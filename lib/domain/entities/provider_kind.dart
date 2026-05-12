enum ServiceType {
  homeService,
  supermarket,
  grocery,
  restaurant,
  homeBrands,
  pharmacy;

  String get wireValue => name;

  static ServiceType? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final v in ServiceType.values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}
