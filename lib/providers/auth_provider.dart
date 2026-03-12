// auth_provider.dart

import 'package:flutter/material.dart';

import '../core/db/supabase_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;

  User? get user => _user;
  bool get isLogin => _user != null;
  bool get isAdmin => _user?.role == 'admin';
  String get username => _user?.username ?? '';

  Future<bool> login(String username, String password) async {
    try {
      final res = await SupabaseService.supabase
          .from('users')
          .select()
          .eq('username', username)
          .eq('password', password)
          .maybeSingle(); // 👈 an toàn hơn single()

      if (res == null) return false;

      _user = User.fromMap(res);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ LOGIN ERROR: $e');
      return false;
    }
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
