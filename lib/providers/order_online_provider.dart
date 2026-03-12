// order_online_provider.dart
import 'package:flutter/material.dart';

import '../core/db/supabase_service.dart';

class OrderOnlineProvider extends ChangeNotifier {
  final _supabase = SupabaseService.supabase;

  /// ===============================
  /// THANH TOÁN ORDER ĐANG MỞ
  /// ===============================
  Future<void> checkoutTable({required int orderId, required int total}) async {
    final now = DateTime.now().toIso8601String();

    await _supabase
        .from('orders')
        .update({
          'total': total,
          'status': 'paid',
          'paid_at': now,
          'check_out': now,
          'payment_method': 'cash',
        })
        .eq('id', orderId);
  }
}
