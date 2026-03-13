class OrderItem {
  final int productId;
  final String name;
  final int price;

  /// Tổng số lượng hiện tại
  final int quantity;

  /// Số lượng đã ORDER / đã in bếp
  final int printedQuantity;

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.printedQuantity = 0,
  });

  /// ===============================
  /// COPY WITH
  /// ===============================
  OrderItem copyWith({int? quantity, int? printedQuantity}) {
    return OrderItem(
      productId: productId,
      name: name,
      price: price,
      quantity: quantity ?? this.quantity,
      printedQuantity: printedQuantity ?? this.printedQuantity,
    );
  }

  /// ===============================
  /// JSON -> OrderItem
  /// ===============================
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] ?? 0,
      name: json['name'] ?? '',
      price: json['price'] ?? 0,
      quantity: json['quantity'] ?? 0,
      printedQuantity: json['printedQuantity'] ?? 0,
    );
  }

  /// ===============================
  /// OrderItem -> JSON
  /// ===============================
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'printedQuantity': printedQuantity,
    };
  }

  /// ===============================
  /// HELPER
  /// ===============================

  /// Có được xoá / giảm không?
  bool get canEdit => printedQuantity == 0;

  /// Số lượng CHƯA order
  int get unprintedQuantity => quantity - printedQuantity;
}
