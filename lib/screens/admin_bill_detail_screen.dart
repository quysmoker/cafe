import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/db/supabase_service.dart';

class AdminBillDetailScreen extends StatefulWidget {
  final Map<String, dynamic> bill;

  const AdminBillDetailScreen({super.key, required this.bill});

  @override
  State<AdminBillDetailScreen> createState() => _AdminBillDetailScreenState();
}

class _AdminBillDetailScreenState extends State<AdminBillDetailScreen> {
  List<Map<String, dynamic>> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final res = await SupabaseService.supabase
          .from('order_items')
          .select('''
            quantity,
            price,
            products (
              name
            )
          ''')
          .eq('order_id', widget.bill['id']);

      setState(() {
        items = res
            .map<Map<String, dynamic>>(
              (e) => {
                'name': e['products']['name'],
                'quantity': e['quantity'],
                'price': e['price'],
              },
            )
            .toList();
        loading = false;
      });
    } catch (e) {
      debugPrint('❌ LỖI LOAD BILL ITEMS: $e');
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;

    final time = DateFormat(
      'dd/MM/yyyy HH:mm',
      'vi_VN',
    ).format(DateTime.parse(bill['check_out']));

    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      appBar: AppBar(
        title: const Text(
          'Chi tiết bill',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // ================= INFO CARD =================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
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
                  Text(
                    bill['order_name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 18),
                      const SizedBox(width: 6),
                      Text('Nhân viên: ${bill['staff_name']}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 18),
                      const SizedBox(width: 6),
                      Text(time),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ================= ITEMS =================
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : items.isEmpty
                    ? const Center(
                        child: Text(
                          'Không có món',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 8),
                        itemBuilder: (_, i) {
                          final e = items[i];
                          final total = e['price'] * e['quantity'];

                          return Row(
                            children: [
                              Expanded(
                                child: Text(
                                  e['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                'x${e['quantity']}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '$total đ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ),

            const SizedBox(height: 12),

            // ================= TOTAL =================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TỔNG CỘNG',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '${bill['total']} đ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 70, 196, 238),
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
