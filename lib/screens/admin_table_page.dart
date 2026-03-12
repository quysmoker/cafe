import 'package:flutter/material.dart';

import '../core/db/supabase_service.dart';
import 'order_screen.dart';

class AdminTablePage extends StatefulWidget {
  const AdminTablePage({super.key});

  @override
  State<AdminTablePage> createState() => _AdminTablePageState();
}

class _AdminTablePageState extends State<AdminTablePage> {
  List<Map<String, dynamic>> tables = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    final res = await SupabaseService.supabase
        .from('tables')
        .select()
        .order('id');

    setState(() {
      tables = List<Map<String, dynamic>>.from(res);
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tables.isEmpty) {
      return const Center(child: Text('Chưa có bàn nào'));
    }

    return RefreshIndicator(
      onRefresh: _loadTables,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.1,
        ),
        itemCount: tables.length,
        itemBuilder: (_, i) {
          final t = tables[i];
          final isUsing = t['status'] == 'using';

          return GestureDetector(
            onTap: () async {
              // 🔥 set bàn đang dùng
              await SupabaseService.supabase
                  .from('tables')
                  .update({'status': 'using'})
                  .eq('id', t['id']);

              if (!mounted) return;

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      OrderScreen(tableId: t['id'], tableName: t['name']),
                ),
              );

              // 🔁 reload khi quay về
              _loadTables();
            },
            child: Card(
              color: isUsing ? Colors.orange[300] : Colors.green[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      t['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(isUsing ? 'Đang dùng' : 'Trống'),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
