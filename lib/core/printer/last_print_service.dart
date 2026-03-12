import '../../models/order_item.dart';
import 'printer_service.dart';

class LastPrintData {
  final String type; // 'temp' | 'final'
  final String tableName;
  final String staffName;
  final List<OrderItem> items;
  final int total;
  final int? orderCount;

  LastPrintData({
    required this.type,
    required this.tableName,
    required this.staffName,
    required this.items,
    required this.total,
    this.orderCount,
  });
}

class LastPrintService {
  static LastPrintData? _last;

  /// LƯU LẦN IN CUỐI
  static void save(LastPrintData data) {
    _last = data;
  }

  /// CÓ BILL ĐỂ IN LẠI KHÔNG
  static bool get hasLast => _last != null;

  /// IN LẠI BILL CUỐI
  static Future<bool> reprint() async {
    if (_last == null) return false;

    final d = _last!;

    if (d.type == 'temp') {
      await PrinterService.printTempBill(
        tableName: d.tableName,
        staffName: d.staffName,
        items: d.items,
        total: d.total,
        orderCount: d.orderCount ?? 1,
        isReprint: true,
      );
    } else {
      await PrinterService.printFinalBill(
        tableName: d.tableName,
        staffName: d.staffName,
        items: d.items,
        total: d.total,
        isReprint: true,
      );
    }

    return true;
  }
}
