/// How fulfillment is handled for a provider order.
enum FulfillmentMode {
  store,
  courier,
  pickup;

  String get wireValue => name;

  static FulfillmentMode fromWire(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'store':
      case 'internal':
        return FulfillmentMode.store;
      case 'pickup':
      case 'explore':
        return FulfillmentMode.pickup;
      case 'courier':
      case 'external':
      default:
        return FulfillmentMode.courier;
    }
  }
}
