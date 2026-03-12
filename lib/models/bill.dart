//model/bill
class Bill {
  final int id;
  final String orderName;
  final String staffName;
  final String checkIn;
  final String checkOut;
  final int total;

  Bill({
    required this.id,
    required this.orderName,
    required this.staffName,
    required this.checkIn,
    required this.checkOut,
    required this.total,
  });

  factory Bill.fromMap(Map<String, dynamic> map) {
    return Bill(
      id: map['id'],
      orderName: map['order_name'],
      staffName: map['staff_name'],
      checkIn: map['check_in'],
      checkOut: map['check_out'],
      total: map['total'],
    );
  }
}
