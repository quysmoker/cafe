// lib/modules/order_history/order_history_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class OrderHistoryRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchOrders({
    required DateTime from,
    required DateTime to,
  }) async {
    // 1️⃣ Lấy danh sách orders đã thanh toán
    final ordersRes = await _client
        .from('orders')
        .select()
        .eq('status', 'paid')
        .gte('paid_at', from.toIso8601String())
        .lt('paid_at', to.toIso8601String())
        .order('paid_at', ascending: false);

    final orders = List<Map<String, dynamic>>.from(ordersRes);

    if (orders.isEmpty) return [];

    // 2️⃣ Lấy toàn bộ tables
    final tablesRes = await _client.from('tables').select('id, name');

    final tables = {for (final t in tablesRes) t['id']: t['name']};

    // 3️⃣ Map table_id -> table_name
    return orders.map((o) {
      return {...o, 'table_name': tables[o['table_id']]};
    }).toList();
  }
}
