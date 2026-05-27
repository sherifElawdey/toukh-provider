/// Who delivers the order to the customer after store acceptance.
enum ProviderFulfillmentMode {
  store,
  courier;

  String get wireValue => name;

  static ProviderFulfillmentMode fromWire(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'store':
        return ProviderFulfillmentMode.store;
      case 'courier':
        return ProviderFulfillmentMode.courier;
      default:
        return ProviderFulfillmentMode.courier;
    }
  }
}
