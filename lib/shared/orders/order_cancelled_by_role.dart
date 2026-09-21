/// Who initiated cancellation on a master order or provider slice.
enum OrderCancelledByRole {
  provider,
  customer;

  String get wireValue => switch (this) {
        OrderCancelledByRole.provider => 'provider',
        OrderCancelledByRole.customer => 'customer',
      };

  static OrderCancelledByRole? fromWire(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'provider':
        return OrderCancelledByRole.provider;
      case 'customer':
      case 'client':
        return OrderCancelledByRole.customer;
      default:
        return null;
    }
  }
}
