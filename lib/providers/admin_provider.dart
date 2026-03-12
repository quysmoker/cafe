import 'package:flutter/material.dart';

import '../core/db/supabase_service.dart';

class AdminProvider extends ChangeNotifier {
  bool loading = false;
  List<Map<String, dynamic>> users = [];

  // ===============================
  // LOAD USERS
  // ===============================
  Future<void> loadUsers() async {
    loading = true;
    notifyListeners();

    try {
      final res = await SupabaseService.supabase
          .from('users')
          .select()
          .order('id');

      users = List<Map<String, dynamic>>.from(res);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ===============================
  // CREATE USER (GIỮ NGUYÊN)
  // ===============================
  Future<void> createUser({
    required String username,
    required String password,
    required String role,
  }) async {
    loading = true;
    notifyListeners();

    try {
      await SupabaseService.supabase.from('users').insert({
        'username': username,
        'password': password,
        'role': role,
      });

      await loadUsers();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ===============================
  // UPDATE USER
  // ===============================
  Future<void> updateUser({
    required int id,
    required String username,
    required String role,
  }) async {
    loading = true;
    notifyListeners();

    try {
      await SupabaseService.supabase
          .from('users')
          .update({'username': username, 'role': role})
          .eq('id', id);

      await loadUsers();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ===============================
  // DELETE USER
  // ===============================
  Future<void> deleteUser(int id) async {
    loading = true;
    notifyListeners();

    try {
      await SupabaseService.supabase.from('users').delete().eq('id', id);
      await loadUsers();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
