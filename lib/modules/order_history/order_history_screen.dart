import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../detail/order_history_detail_provider.dart';
import '../detail/order_history_detail_repository.dart';
import '../detail/order_history_detail_screen.dart';
import 'order_history_filter.dart';
import 'order_history_provider.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'vi_VN';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OrderHistoryProvider()..load(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text(
            'Lịch sử đơn hàng',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.lightBlue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        body: Consumer<OrderHistoryProvider>(
          builder: (context, p, _) {
            return Column(
              children: [
                _FilterBar(provider: p),
                _RevenueBox(total: p.totalRevenue),
                const SizedBox(height: 4),
                Expanded(
                  child: RefreshIndicator(
                    color: Colors.lightBlue,
                    onRefresh: () => p.load(),
                    child: p.orders.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 140),
                              Center(
                                child: Text(
                                  'Chưa có đơn hàng',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 12),
                            itemCount: p.orders.length,
                            itemBuilder: (context, i) {
                              final o = p.orders[i];

                              final tableName =
                                  o['table_name']?.toString() ?? '---';
                              final total = o['total'] ?? 0;
                              final staff =
                                  o['staff_name']?.toString() ?? '---';
                              final rawTime = o['paid_at'] ?? o['created_at'];

                              String timeText = '--';
                              if (rawTime != null) {
                                try {
                                  final dt = DateTime.parse(rawTime.toString());
                                  timeText = DateFormat(
                                    'EEEE, dd/MM/yyyy • HH:mm',
                                    'vi_VN',
                                  ).format(dt);
                                } catch (_) {}
                              }

                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: ListTile(
                                  leading: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: Colors.lightBlue.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.table_bar_outlined,
                                      color: Colors.lightBlue,
                                    ),
                                  ),
                                  title: Text(
                                    'Bàn $tableName',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'NV: $staff\n$timeText',
                                      style: const TextStyle(height: 1.35),
                                    ),
                                  ),
                                  trailing: Text(
                                    NumberFormat.currency(
                                      locale: 'vi_VN',
                                      symbol: 'đ',
                                    ).format(total),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.lightBlue,
                                    ),
                                  ),
                                  isThreeLine: true,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChangeNotifierProvider(
                                          create: (_) =>
                                              OrderHistoryDetailProvider(
                                                OrderHistoryDetailRepository(),
                                              ),
                                          child: OrderHistoryDetailScreen(
                                            orderId: o['id'],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/* ===============================
   DOANH THU – DASHBOARD
================================ */
class _RevenueBox extends StatelessWidget {
  final int total;
  const _RevenueBox({required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4FC3F7), Color(0xFF81D4FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DOANH THU',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(total),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ===============================
   FILTER BAR
================================ */
class _FilterBar extends StatelessWidget {
  final OrderHistoryProvider provider;
  const _FilterBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Wrap(
        spacing: 8,
        children: HistoryRange.values.map((r) {
          final selected = provider.filter.range == r;

          final label = switch (r) {
            HistoryRange.day => 'Ngày',
            HistoryRange.week => 'Tuần',
            HistoryRange.month => 'Tháng',
            HistoryRange.year => 'Năm',
          };

          return ChoiceChip(
            label: Text(label),
            selected: selected,
            selectedColor: Colors.lightBlue,
            backgroundColor: Colors.grey.shade200,
            labelStyle: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            onSelected: (_) async {
              DateTime date = provider.filter.date;

              if (r == HistoryRange.day || r == HistoryRange.month) {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  locale: const Locale('vi', 'VN'),
                );
                if (picked == null) return;
                date = picked;
              }

              provider.setFilter(
                provider.filter.copyWith(range: r, date: date),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
