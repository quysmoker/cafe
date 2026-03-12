// staff_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/printer/last_print_service.dart';
import '../providers/auth_provider.dart';
import 'table_screen.dart';

class StaffHomeScreen extends StatelessWidget {
  const StaffHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('NHÂN VIÊN – Chọn bàn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.replay),
            tooltip: 'In lại bill gần nhất',
            onPressed: () async {
              final ok = await LastPrintService.reprint();
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('⚠ Chưa có bill nào để in lại')),
                );
              }
            },
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: auth.logout),
        ],
      ),

      body: const TableScreen(),
    );
  }
}
