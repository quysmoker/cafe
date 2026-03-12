class Product {
  final int id;
  final String name;
  final int price;
  final int stock;
  final int categoryId;
  final String categoryName;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.categoryId,
    required this.categoryName,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      stock: map['stock'],
      categoryId: map['category_id'] ?? 0,

      // 🔴 CHỐT LỖI Ở ĐÂY
      categoryName: map['categories'] != null
          ? map['categories']['name'] as String
          : 'Khác',
    );
  }
}
