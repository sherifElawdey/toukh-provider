import 'package:toukh_provider/domain/entities/provider_dashboard_order.dart';
import 'package:toukh_ui/toukh_ui.dart';

extension ProviderMasterOrderRowDashboardX on ProviderMasterOrderRow {
  ProviderOrderDashboard toDashboard() {
    final s = slice;
    return ProviderOrderDashboard(
      id: id,
      status: _mapOrderStatus(s.statusWire),
      statusWire: s.statusWire,
      createdAt: s.createdAt,
      acceptedAt: s.acceptedAt,
      deliveredAt: s.deliveredAt,
      totalEgp: s.totalEgp,
      customerName: s.customerName,
      items: [
        for (final item in s.items)
          ProviderOrderLineItem(
            itemId: item.itemId,
            name: item.name,
            quantity: item.quantity,
            lineTotalEgp: item.lineTotalEgp,
          ),
      ],
    );
  }
}

OrderStatus _mapOrderStatus(String wire) {
  switch (wire) {
    case 'preparing':
    case 'ready':
    case 'ready_for_pickup':
      return OrderStatus.accepted;
    default:
      return OrderStatus.fromWire(wire);
  }
}
