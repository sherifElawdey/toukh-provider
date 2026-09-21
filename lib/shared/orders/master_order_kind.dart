/// Discriminant for master order placement flow.
enum MasterOrderKind {
  standard,
  pharmacyRequest;

  String get wireValue => switch (this) {
        MasterOrderKind.standard => 'standard',
        MasterOrderKind.pharmacyRequest => 'pharmacy_request',
      };

  static MasterOrderKind fromWire(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'pharmacy_request':
        return MasterOrderKind.pharmacyRequest;
      default:
        return MasterOrderKind.standard;
    }
  }
}
