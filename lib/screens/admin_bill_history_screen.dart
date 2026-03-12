// admin_bill_history_screen.dart

import 'package:flutter/material.dart';

import '../modules/order_history/order_history_screen.dart';

class AdminBillHistoryScreen extends StatelessWidget {
  const AdminBillHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Toàn bộ logic lịch sử đã được tách sang module order_history
    // Screen này chỉ còn nhiệm vụ "host" để giữ navigation cũ
    return const OrderHistoryScreen();
  }
}
