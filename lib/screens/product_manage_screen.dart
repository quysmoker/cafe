import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/db/supabase_service.dart';
import '../models/product.dart';
import '../providers/product_online_provider.dart';

class ProductManageScreen extends StatefulWidget {
  const ProductManageScreen({super.key});

  @override
  State<ProductManageScreen> createState() => _ProductManageScreenState();
}

class _ProductManageScreenState extends State<ProductManageScreen> {
  bool loading = true;
  List<Product> products = [];
  List<Map<String, dynamic>> categories = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => loading = true);

    categories = List<Map<String, dynamic>>.from(
      await SupabaseService.supabase.from('categories').select().order('id'),
    );

    products = await context.read<ProductOnlineProvider>().getProducts();

    if (!mounted) return;
    setState(() => loading = false);
  }

  Map<String, List<Product>> _groupByCategory() {
    final Map<String, List<Product>> map = {};
    for (final p in products) {
      map.putIfAbsent(p.categoryName, () => []);
      map[p.categoryName]!.add(p);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByCategory();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Quản lý món',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.lightBlue,
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : grouped.isEmpty
          ? const Center(child: Text('Chưa có món'))
          : ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: grouped.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== CATEGORY HEADER =====
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.lightBlue,
                        ),
                      ),
                    ),

                    // ===== PRODUCTS =====
                    ...entry.value.map(
                      (p) => Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          title: Text(
                            p.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Giá: ${p.price} đ  •  Kho: ${p.stock}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Sửa',
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blueGrey,
                                ),
                                onPressed: () => _showForm(product: p),
                              ),
                              IconButton(
                                tooltip: 'Xóa',
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  await context
                                      .read<ProductOnlineProvider>()
                                      .deleteProduct(p.id);
                                  await _init();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
    );
  }

  // ================= FORM THÊM / SỬA =================
  void _showForm({Product? product}) {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final priceCtrl = TextEditingController(
      text: product?.price.toString() ?? '',
    );
    final stockCtrl = TextEditingController(
      text: product?.stock.toString() ?? '',
    );

    int selectedCategoryId = product?.categoryId ?? categories.first['id'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding: const EdgeInsets.all(16),
              child: ListView(
                controller: controller, // 🔴 QUAN TRỌNG
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Text(
                    product == null ? 'Thêm món mới' : 'Sửa món',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên món',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Giá',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: stockCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Kho',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<int>(
                    initialValue: selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Danh mục',
                      border: OutlineInputBorder(),
                    ),
                    items: categories
                        .map(
                          (c) => DropdownMenuItem<int>(
                            value: c['id'],
                            child: Text(c['name']),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => selectedCategoryId = v!,
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                      ),
                      onPressed: () async {
                        final provider = context.read<ProductOnlineProvider>();

                        if (product == null) {
                          await provider.insertProduct(
                            name: nameCtrl.text.trim(),
                            price: int.parse(priceCtrl.text),
                            stock: int.parse(stockCtrl.text),
                            categoryId: selectedCategoryId,
                          );
                        } else {
                          await provider.updateProduct(
                            id: product.id,
                            name: nameCtrl.text.trim(),
                            price: int.parse(priceCtrl.text),
                            stock: int.parse(stockCtrl.text),
                            categoryId: selectedCategoryId,
                          );
                        }

                        await _init();
                        if (!mounted) return;
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'LƯU',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
