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
  /// HELPER
  /// ===============================

  /// Có được xoá / giảm không?
  bool get canEdit => printedQuantity == 0;

  /// Số lượng CHƯA order
  int get unprintedQuantity => quantity - printedQuantity;
}
