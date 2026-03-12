import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/printer/last_print_service.dart';
import '../providers/auth_provider.dart';
import '../services/printer_test_service.dart';
import 'admin_bill_history_screen.dart';
import 'product_manage_screen.dart';
import 'table_screen.dart';
import 'user_management_screen.dart'; // ✅ MỚI

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int index = 0;

  /// ⚠️ CHỈ CÓ 3 TAB THẬT
  final List<Widget> screens = const [
    TableScreen(), // 0 - Bàn
    ProductManageScreen(), // 1 - Món
    AdminBillHistoryScreen(), // 2 - Lịch sử bill
  ];

  static const int moreIndex = 3;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // ===============================
    // 🔒 CHẶN CỨNG STAFF
    // ===============================
    if (!auth.isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text(
            '❌ Không có quyền truy cập',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ADMIN – Quản lý'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: auth.logout,
          ),
        ],
      ),

      /// ✅ KHÔNG MẤT STATE KHI ĐỔI TAB
      body: IndexedStack(index: index, children: screens),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          if (i == moreIndex) {
            _showMoreMenu(context);
            return;
          }
          setState(() => index = i);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.table_bar), label: 'Bàn'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Món'),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Lịch sử',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Thêm'),
        ],
      ),
    );
  }

  // ===============================
  // MENU 3 GẠCH (≡)
  // ===============================
  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),

            // ===============================
            // QUẢN LÝ USER
            // ===============================
            ListTile(
              leading: const Icon(Icons.manage_accounts),
              title: const Text('Quản lý nhân viên'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UserManagementScreen(),
                  ),
                );
              },
            ),

            // ===============================
            // TEST MÁY IN
            // ===============================
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('In bill test'),
              onTap: () {
                Navigator.pop(context);

                // 🔴 đợi BottomSheet đóng hẳn
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  PrinterTestService.testPrint(context);
                });
              },
            ),

            // ===============================
            // IN LẠI BILL
            // ===============================
            ListTile(
              leading: const Icon(Icons.replay),
              title: const Text('In lại bill gần nhất'),
              onTap: () async {
                Navigator.pop(context);

                final ok = await LastPrintService.reprint();
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠ Chưa có bill nào để in lại'),
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
