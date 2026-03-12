// lib/screens/order_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/db/supabase_service.dart';
import '../core/printer/printer_service.dart';
import '../models/order_item.dart';
import '../providers/auth_provider.dart';
import '../providers/order_online_provider.dart';
import '../providers/table_online_provider.dart';
import '../widgets/bill_preview_dialog.dart';

class OrderScreen extends StatefulWidget {
  final int tableId;
  final String tableName;

  const OrderScreen({
    super.key,
    required this.tableId,
    required this.tableName,
  });

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  List<Map<String, dynamic>> products = [];
  List<OrderItem> items = [];
  int? orderId;
  List<Map<String, dynamic>> categories = [];
  int? selectedCategoryId; // null = tất cả

  bool loading = true;
  String keyword = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  // ================= INIT =================
  Future<void> _init() async {
    await _loadProducts();
    await _loadExistingOrder();
    await _loadItems();
    await _loadCategories();
  }

  Future<void> _loadCategories() async {
    final res = await SupabaseService.supabase
        .from('categories')
        .select()
        .order('id');

    if (!mounted) return;
    setState(() {
      categories = List<Map<String, dynamic>>.from(res);
    });
  }

  // ================= LOAD ORDER ĐÃ ORDER TRƯỚC =================
  Future<void> _loadExistingOrder() async {
    final res = await SupabaseService.supabase
        .from('orders')
        .select('id')
        .eq('table_id', widget.tableId)
        .eq('status', 'open')
        .order('id', ascending: false)
        .limit(1);

    if (res.isNotEmpty) {
      orderId = res.first['id'];
    }
  }

  // ================= LOAD PRODUCTS =================
  Future<void> _loadProducts() async {
    final res = await SupabaseService.supabase
        .from('products')
        .select()
        .order('id');

    if (!mounted) return;
    setState(() {
      products = List<Map<String, dynamic>>.from(res);
      loading = false;
    });
  }

  // ================= ENSURE ORDER (CHỈ TẠO ORDER) =================
  Future<void> _ensureOrder() async {
    if (orderId != null) return;

    final staffName = context.read<AuthProvider>().username;
    final now = DateTime.now().toIso8601String();

    final order = await SupabaseService.supabase
        .from('orders')
        .insert({
          'table_id': widget.tableId,
          'order_name': 'Order ${widget.tableName}',
          'staff_name': staffName,
          'check_in': now,
          'status': 'open',
          'temp_print_count': 0,
        })
        .select()
        .single();

    orderId = order['id'];
  }

  // ================= LOAD ITEMS =================
  Future<void> _loadItems() async {
    if (orderId == null) return;

    final res = await SupabaseService.supabase
        .from('order_items')
        .select('product_id, quantity, printed_quantity, price, products(name)')
        .eq('order_id', orderId!);

    if (!mounted) return;
    setState(() {
      items = res.map<OrderItem>((e) {
        return OrderItem(
          productId: e['product_id'],
          name: e['products']['name'],
          price: e['price'],
          quantity: e['quantity'],
          printedQuantity: e['printed_quantity'] ?? 0,
        );
      }).toList();
    });
  }

  // ================= ADD PRODUCT =================
  Future<void> _addProduct(Map<String, dynamic> p) async {
    await _ensureOrder();

    final existing = await SupabaseService.supabase
        .from('order_items')
        .select()
        .eq('order_id', orderId!)
        .eq('product_id', p['id'])
        .maybeSingle();

    if (existing != null) {
      await SupabaseService.supabase
          .from('order_items')
          .update({'quantity': existing['quantity'] + 1})
          .eq('id', existing['id']);
    } else {
      await SupabaseService.supabase.from('order_items').insert({
        'order_id': orderId,
        'product_id': p['id'],
        'price': p['price'],
        'quantity': 1,
      });
    }

    await _loadItems();
  }

  // ================= REMOVE ONE =================
  Future<void> _removeOne(OrderItem item) async {
    if (item.printedQuantity > 0 || orderId == null) return;

    final row = await SupabaseService.supabase
        .from('order_items')
        .select()
        .eq('order_id', orderId!)
        .eq('product_id', item.productId)
        .single();

    if (row['quantity'] > 1) {
      await SupabaseService.supabase
          .from('order_items')
          .update({'quantity': row['quantity'] - 1})
          .eq('id', row['id']);
    } else {
      await SupabaseService.supabase
          .from('order_items')
          .delete()
          .eq('id', row['id']);
    }

    await _afterItemChanged();
  }

  // ================= REMOVE ALL =================
  Future<void> _removeAll(OrderItem item) async {
    if (item.printedQuantity > 0 || orderId == null) return;

    await SupabaseService.supabase
        .from('order_items')
        .delete()
        .eq('order_id', orderId!)
        .eq('product_id', item.productId);

    await _afterItemChanged();
  }

  // ================= SAU KHI XOÁ =================
  Future<void> _afterItemChanged() async {
    await _loadItems();

    final hasPrinted = items.any((e) => e.printedQuantity > 0);

    // ❌ CHƯA ORDER MÀ XOÁ HẾT → HUỶ ORDER + TRẢ BÀN
    if (!hasPrinted && items.isEmpty && orderId != null) {
      await SupabaseService.supabase.from('orders').delete().eq('id', orderId!);

      await context.read<TableOnlineProvider>().setTableStatus(
        widget.tableId,
        'empty',
      );

      orderId = null;
    }
  }

  int get total => items.fold(0, (s, e) => s + e.price * e.quantity);

  // ================= ORDER – IN BILL TẠM =================
  Future<void> _orderTemp() async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('⚠️ Chưa có món để order')));
      return;
    }

    await _ensureOrder();

    final res = await SupabaseService.supabase
        .from('order_items')
        .select(
          'id, product_id, quantity, printed_quantity, price, products(name)',
        )
        .eq('order_id', orderId!);

    final List<OrderItem> newItems = [];

    for (final e in res) {
      final qty = e['quantity'];
      final printed = e['printed_quantity'] ?? 0;

      if (qty > printed) {
        final diff = qty - printed;

        newItems.add(
          OrderItem(
            productId: e['product_id'],
            name: e['products']['name'],
            price: e['price'],
            quantity: diff,
          ),
        );

        await SupabaseService.supabase
            .from('order_items')
            .update({'printed_quantity': qty})
            .eq('id', e['id']);
      }
    }

    if (newItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('⚠️ Không có món mới')));
      return;
    }

    await PrinterService.printTempBill(
      tableName: widget.tableName,
      staffName: context.read<AuthProvider>().username,
      items: newItems,
      total: newItems.fold(0, (s, e) => s + e.price * e.quantity),
      orderCount: 1,
    );

    // ✅ CHỈ LÚC ORDER MỚI GIỮ BÀN
    await context.read<TableOnlineProvider>().setTableStatus(
      widget.tableId,
      'occupied',
    );

    await _loadItems();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final filtered = products.where((p) {
      final matchKeyword =
          keyword.isEmpty ||
          p['name'].toLowerCase().contains(keyword.toLowerCase());

      final matchCategory =
          selectedCategoryId == null || p['category_id'] == selectedCategoryId;

      return matchKeyword && matchCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ORDER – ${widget.tableName}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                  child: SizedBox(
                    height: 42,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Tìm món...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (v) => setState(() => keyword = v.trim()),
                    ),
                  ),
                ),

                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      ChoiceChip(
                        label: const Text('Tất cả'),
                        selected: selectedCategoryId == null,
                        onSelected: (_) =>
                            setState(() => selectedCategoryId = null),
                      ),
                      const SizedBox(width: 6),
                      ...categories.map((c) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(c['name']),
                            selected: selectedCategoryId == c['id'],
                            onSelected: (_) =>
                                setState(() => selectedCategoryId = c['id']),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, // ✅ 3 cột
                          childAspectRatio: 1, // vuông, dễ bấm
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),

                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final p = filtered[i];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _addProduct(p),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    p['name'],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${p['price']} đ',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _buildBill(),
              ],
            ),
    );
  }

  Widget _buildBill() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ===== THANH KÉO NHẸ (NHÌN SANG) =====
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ================= DANH SÁCH MÓN =================
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Chưa có món nào',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            SizedBox(
              height: 120,
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final e = items[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${e.name}  x${e.quantity}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${e.price * e.quantity} đ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            size: 20,
                          ),
                          onPressed: () => _removeOne(e),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.delete,
                            size: 20,
                            color: Colors.red,
                          ),
                          onPressed: () => _removeAll(e),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 8),

          // ================= TỔNG =================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TỔNG CỘNG',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              Text(
                '$total đ',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ================= ACTION =================
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: items.isEmpty ? null : _orderTemp,
                  child: const Text(
                    'ORDER',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 83, 173, 233),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: items.isEmpty
                      ? null
                      : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => BillPreviewDialog(
                              tableName: widget.tableName,
                              items: items,
                              total: total,
                              staffName: context.read<AuthProvider>().username,
                            ),
                          );
                          if (confirm != true) return;

                          await PrinterService.printFinalBill(
                            tableName: widget.tableName,
                            staffName: context.read<AuthProvider>().username,
                            items: items,
                            total: total,
                          );

                          await context
                              .read<OrderOnlineProvider>()
                              .checkoutTable(orderId: orderId!, total: total);

                          await context
                              .read<TableOnlineProvider>()
                              .setTableStatus(widget.tableId, 'empty');

                          if (!mounted) return;
                          Navigator.pop(context);
                        },
                  child: const Text(
                    'THANH TOÁN',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
