import 'package:flutter/material.dart';

import '../core/db/supabase_service.dart';
import '../models/product.dart';

class ProductOnlineProvider extends ChangeNotifier {
  final _supabase = SupabaseService.supabase;

  // ===============================
  // LẤY DANH SÁCH MÓN + DANH MỤC
  // ===============================
  Future<List<Product>> getProducts() async {
    final res = await _supabase
        .from('products')
        .select('''
          id,
          name,
          price,
          stock,
          category_id,
          categories (
            name
          )
        ''')
        .order('category_id')
        .order('id');

    return (res as List).map<Product>((e) => Product.fromMap(e)).toList();
  }

  Future<void> insertProduct({
    required String name,
    required int price,
    required int stock,
    required int categoryId,
  }) async {
    await _supabase.from('products').insert({
      'name': name,
      'price': price,
      'stock': stock,
      'category_id': categoryId,
    });
  }

  Future<void> updateProduct({
    required int id,
    required String name,
    required int price,
    required int stock,
    required int categoryId,
  }) async {
    await _supabase
        .from('products')
        .update({
          'name': name,
          'price': price,
          'stock': stock,
          'category_id': categoryId,
        })
        .eq('id', id);
  }

  Future<void> deleteProduct(int id) async {
    await _supabase.from('products').delete().eq('id', id);
  }
}
