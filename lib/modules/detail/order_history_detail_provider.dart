import 'package:flutter/material.dart';

import 'order_history_detail_repository.dart';

class OrderHistoryDetailProvider extends ChangeNotifier {
  final OrderHistoryDetailRepository repo;

  bool loading = false;
  Map<String, dynamic>? order;
  List<Map<String, dynamic>> items = [];

  OrderHistoryDetailProvider(this.repo);

  Future<void> load(int orderId) async {
    loading = true;
    notifyListeners();

    final res = await repo.fetchOrderDetail(orderId);
    order = res['order'];
    items = List<Map<String, dynamic>>.from(res['items']);

    loading = false;
    notifyListeners();
  }

  int get total {
    return items.fold(0, (sum, i) => sum + ((i['line_total'] ?? 0) as int));
  }
}
