// lib/modules/order_history/order_history_provider.dart

import 'package:flutter/material.dart';

import 'order_history_filter.dart';
import 'order_history_repository.dart';

class OrderHistoryProvider extends ChangeNotifier {
  final _repo = OrderHistoryRepository();

  OrderHistoryFilter filter = OrderHistoryFilter(
    range: HistoryRange.day,
    date: DateTime.now(),
  );

  bool loading = false;
  List<Map<String, dynamic>> orders = [];
  int totalRevenue = 0;

  Future<void> load() async {
    loading = true;
    notifyListeners();

    final range = _getRange(filter);

    orders = await _repo.fetchOrders(from: range.$1, to: range.$2);

    totalRevenue = orders.fold<int>(0, (sum, o) => sum + (o['total'] as int));

    loading = false;
    notifyListeners();
  }

  void setFilter(OrderHistoryFilter newFilter) {
    filter = newFilter;
    load();
  }

  (DateTime, DateTime) _getRange(OrderHistoryFilter f) {
    final d = f.date;

    switch (f.range) {
      case HistoryRange.day:
        final from = DateTime(d.year, d.month, d.day);
        return (from, from.add(const Duration(days: 1)));

      case HistoryRange.week:
        final from = d.subtract(Duration(days: d.weekday - 1));
        final start = DateTime(from.year, from.month, from.day);
        return (start, start.add(const Duration(days: 7)));

      case HistoryRange.month:
        final from = DateTime(d.year, d.month);
        return (from, DateTime(d.year, d.month + 1));

      case HistoryRange.year:
        final from = DateTime(d.year);
        return (from, DateTime(d.year + 1));
    }
  }
}
