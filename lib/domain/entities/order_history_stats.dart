import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:toukh_ui/toukh_ui.dart';

class OrderHistoryStats extends Equatable {
  const OrderHistoryStats({
    required this.totalOrders,
    required this.completedOrders,
    required this.canceledOrders,
  });

  const OrderHistoryStats.zero()
      : totalOrders = 0,
        completedOrders = 0,
        canceledOrders = 0;

  final int totalOrders;
  final int completedOrders;
  final int canceledOrders;

  @override
  List<Object?> get props => [totalOrders, completedOrders, canceledOrders];
}

class OrderHistoryPage extends Equatable {
  const OrderHistoryPage({
    required this.rows,
    required this.lastDoc,
  });

  final List<ProviderMasterOrderRow> rows;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;

  @override
  List<Object?> get props => [rows, lastDoc];
}
