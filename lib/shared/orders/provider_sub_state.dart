/// Per-provider state inside a master order (aggregated or standalone).
enum ProviderSubState {
  pending,
  quoted,
  accepted,
  rejected,
  preparing,
  readyForPickup,
  pickedUp;

  String get wireValue => switch (this) {
        ProviderSubState.pending => 'pending',
        ProviderSubState.quoted => 'quoted',
        ProviderSubState.accepted => 'accepted',
        ProviderSubState.rejected => 'rejected',
        ProviderSubState.preparing => 'preparing',
        ProviderSubState.readyForPickup => 'ready_for_pickup',
        ProviderSubState.pickedUp => 'picked_up',
      };

  static ProviderSubState fromWire(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'accepted':
        return ProviderSubState.accepted;
      case 'quoted':
        return ProviderSubState.quoted;
      case 'rejected':
        return ProviderSubState.rejected;
      case 'preparing':
        return ProviderSubState.preparing;
      case 'ready_for_pickup':
        return ProviderSubState.readyForPickup;
      case 'picked_up':
      case 'out_for_delivery':
        return ProviderSubState.pickedUp;
      case 'pending':
      case 'placed':
      default:
        return ProviderSubState.pending;
    }
  }

  bool get isResponded =>
      this == ProviderSubState.quoted ||
      this == ProviderSubState.accepted ||
      this == ProviderSubState.rejected ||
      this == ProviderSubState.preparing ||
      this == ProviderSubState.readyForPickup ||
      this == ProviderSubState.pickedUp;

  bool get countsForPickup =>
      this == ProviderSubState.accepted ||
      this == ProviderSubState.preparing ||
      this == ProviderSubState.readyForPickup ||
      this == ProviderSubState.pickedUp;
}
