// lib/modules/order_history/order_history_filter.dart

enum HistoryRange { day, week, month, year }

class OrderHistoryFilter {
  final HistoryRange range;
  final DateTime date;

  OrderHistoryFilter({required this.range, required this.date});

  OrderHistoryFilter copyWith({HistoryRange? range, DateTime? date}) {
    return OrderHistoryFilter(
      range: range ?? this.range,
      date: date ?? this.date,
    );
  }
}
