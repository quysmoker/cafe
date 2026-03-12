import 'package:supabase_flutter/supabase_flutter.dart';

class OrderHistoryDetailRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>> fetchOrderDetail(int orderId) async {
    // 1️⃣ Lấy order
    final orderRes = await _client
        .from('orders')
        .select()
        .eq('id', orderId)
        .single();

    // 2️⃣ Lấy order_items
    final itemsRes = await _client
        .from('order_items')
        .select()
        .eq('order_id', orderId);

    // 3️⃣ Lấy products
    final productsRes = await _client.from('products').select('id, name');

    final productMap = {for (final p in productsRes) p['id']: p['name']};

    // 4️⃣ Map tên sản phẩm
    final items = itemsRes.map((i) {
      return {
        ...i,
        'product_name': productMap[i['product_id']],
        'line_total': (i['quantity'] ?? 0) * (i['price'] ?? 0),
      };
    }).toList();

    return {'order': orderRes, 'items': items};
  }
}
