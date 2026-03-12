// table_online_provider.dart
import 'package:flutter/material.dart';

import '../core/db/supabase_service.dart';

class TableOnlineProvider extends ChangeNotifier {
  final _supabase = SupabaseService.supabase;

  /// ===============================
  /// 1️⃣ LOAD DANH SÁCH BÀN (ONLINE)
  /// ===============================
  Future<List<Map<String, dynamic>>> loadTables() async {
    return await _supabase.from('tables').select().order('id');
  }

  /// ===============================
  /// 2️⃣ SET TRẠNG THÁI BÀN
  /// ===============================
  Future<void> setTableStatus(int tableId, String status) async {
    await _supabase.from('tables').update({'status': status}).eq('id', tableId);
  }

  /// ===============================
  /// 3️⃣ THÊM BÀN (ADMIN)
  /// 👉 alias để khớp UI
  /// ===============================
  Future<void> addTable({required String name, String? note}) async {
    await _supabase.from('tables').insert({
      'name': name,
      'note': note,
      'status': 'empty',
    });
  }

  /// (Giữ lại nếu chỗ khác đang dùng)
  Future<void> insertTable({required String name, required String note}) async {
    await addTable(name: name, note: note);
  }

  /// ===============================
  /// 4️⃣ XOÁ BÀN (CHỈ KHI TRỐNG)
  /// ===============================
  Future<void> deleteTable(int tableId) async {
    // Lấy trạng thái bàn trước khi xoá
    final table = await _supabase
        .from('tables')
        .select('status')
        .eq('id', tableId)
        .maybeSingle();

    if (table == null) return;

    if (table['status'] != 'empty') {
      throw Exception('Không thể xoá bàn đang sử dụng');
    }

    await _supabase.from('tables').delete().eq('id', tableId);
  }
}
