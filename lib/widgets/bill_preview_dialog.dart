import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/order_item.dart';

class BillPreviewDialog extends StatelessWidget {
  final String tableName;
  final List<OrderItem> items;
  final int total;
  final String staffName;

  const BillPreviewDialog({
    super.key,
    required this.tableName,
    required this.items,
    required this.total,
    required this.staffName,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr = DateFormat('dd/MM/yyyy HH:mm:ss').format(now);

    return AlertDialog(
      title: const Text('XÁC NHẬN THANH TOÁN'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'CAFE HEHE',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 6),

            Text('Bàn: $tableName'),
            Text('Nhân viên: $staffName'),
            Text('Thời gian: $timeStr'),

            const Divider(),

            ...items.map(
              (e) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('${e.name} x${e.quantity}')),
                  Text('${e.price * e.quantity} đ'),
                ],
              ),
            ),

            const Divider(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TỔNG',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$total đ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('HỦY'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('XÁC NHẬN & IN'),
        ),
      ],
    );
  }
}
