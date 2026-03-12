import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/table_online_provider.dart';
import 'order_screen.dart';

class TableScreen extends StatefulWidget {
  const TableScreen({super.key});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  late Future<List<Map<String, dynamic>>> _tablesFuture;

  @override
  void initState() {
    super.initState();
    _tablesFuture = context.read<TableOnlineProvider>().loadTables();
  }

  // =========================
  // 🔁 SORT BÀN: A1 B1 C1 | A2 B2 C2
  // =========================
  List<Map<String, dynamic>?> buildTableGrid(
    List<Map<String, dynamic>> tables,
  ) {
    final Map<int, Map<String, Map<String, dynamic>>> rows = {};

    for (final t in tables) {
      final name = t['name'] as String;
      final letter = name[0];
      final number = int.tryParse(name.substring(1)) ?? 0;

      rows.putIfAbsent(number, () => {});
      rows[number]![letter] = t;
    }

    final sortedNumbers = rows.keys.toList()..sort();

    final List<Map<String, dynamic>?> result = [];

    for (final n in sortedNumbers) {
      final row = rows[n]!;
      result.add(row['A']);
      result.add(row['B']);
      result.add(row['C']);
    }

    return result;
  }

  // =========================
  // ➕ THÊM BÀN (ADMIN)
  // =========================
  void _showAddTableDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thêm bàn mới'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Tên bàn (vd: A1, B2)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              await context.read<TableOnlineProvider>().insertTable(
                name: name,
                note: '',
              );

              if (!mounted) return;
              Navigator.pop(context);

              setState(() {
                _tablesFuture = context
                    .read<TableOnlineProvider>()
                    .loadTables();
              });
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  // =========================
  // ❌ XÓA BÀN (ADMIN)
  // =========================
  void _confirmDeleteTable(Map<String, dynamic> table) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa bàn'),
        content: Text('Bạn có chắc muốn xóa bàn "${table['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await context.read<TableOnlineProvider>().deleteTable(
                table['id'],
              );

              if (!mounted) return;
              Navigator.pop(context);

              setState(() {
                _tablesFuture = context
                    .read<TableOnlineProvider>()
                    .loadTables();
              });
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Danh sách bàn',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        actions: [
          if (auth.isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Thêm bàn',
              onPressed: _showAddTableDialog,
            ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _tablesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tables = buildTableGrid(snapshot.data!);

          if (tables.isEmpty) {
            return const Center(child: Text('Chưa có bàn nào'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(14),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.05,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: tables.length,
            itemBuilder: (_, i) {
              final t = tables[i];
              if (t == null) return const SizedBox();

              final isUsing = t['status'] == 'occupied';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          OrderScreen(tableId: t['id'], tableName: t['name']),
                    ),
                  ).then((_) {
                    setState(() {
                      _tablesFuture = context
                          .read<TableOnlineProvider>()
                          .loadTables();
                    });
                  });
                },
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isUsing
                              ? [Colors.orange.shade300, Colors.orange.shade400]
                              : [
                                  const Color.fromARGB(255, 114, 191, 226),
                                  const Color.fromARGB(255, 154, 179, 191),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              t['name'],
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isUsing ? 'ĐANG DÙNG' : 'TRỐNG',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ❌ NÚT XÓA – ADMIN & BÀN TRỐNG
                    if (auth.isAdmin && !isUsing)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () => _confirmDeleteTable(t),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
