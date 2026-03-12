import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'order_history_detail_provider.dart';

class OrderHistoryDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderHistoryDetailScreen({super.key, required this.orderId});

  @override
  State<OrderHistoryDetailScreen> createState() =>
      _OrderHistoryDetailScreenState();
}

class _OrderHistoryDetailScreenState extends State<OrderHistoryDetailScreen> {
  @override
  void initState() {
    super.initState();
    // load dữ liệu chi tiết bill
    Future.microtask(() {
      context.read<OrderHistoryDetailProvider>().load(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OrderHistoryDetailProvider>();

    Intl.defaultLocale = 'vi_VN';

    if (p.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (p.order == null) {
      return const Scaffold(body: Center(child: Text('Không tìm thấy bill')));
    }

    final order = p.order!;

    // ===== SAFE DATA =====
    final staff = order['staff_name']?.toString() ?? '---';
    final total = order['total'] ?? 0;

    String formatTime(dynamic raw) {
      if (raw == null) return '--';
      try {
        final dt = DateTime.parse(raw.toString());
        return DateFormat('HH:mm • dd/MM/yyyy').format(dt);
      } catch (_) {
        return '--';
      }
    }

    final checkIn = formatTime(order['check_in']);
    final checkOut = formatTime(order['check_out']);

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết bill')),
      body: Column(
        children: [
          // ===============================
          // THÔNG TIN CHUNG
          // ===============================
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nhân viên: $staff',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text('Giờ vào: $checkIn'),
                  Text('Giờ ra: $checkOut'),
                  const SizedBox(height: 10),
                  Text(
                    'Tổng tiền: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(total)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // ===============================
          // DANH SÁCH MÓN
          // ===============================
          Expanded(
            child: p.items.isEmpty
                ? const Center(child: Text('Không có món'))
                : ListView.separated(
                    itemCount: p.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final item = p.items[i];

                      final name = item['product_name']?.toString() ?? '---';
                      final qty = item['quantity'] ?? 0;
                      final price = item['price'] ?? 0;
                      final lineTotal = item['line_total'] ?? 0;

                      return ListTile(
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text('$qty × $price đ'),
                        trailing: Text(
                          '$lineTotal đ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
          ),

          // ===============================
          // FOOTER (CHUẨN BỊ IN BILL)
          // ===============================
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('In lại bill'),
                onPressed: () {
                  // TODO: gắn printer service sau
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
