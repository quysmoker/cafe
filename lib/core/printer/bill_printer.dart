/// bill_printer.dart
library;

import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

import '../../models/order_item.dart';

class BillPrinter {
  static const String _printerIp = '192.168.100.254';
  static const int _printerPort = 9100;

  // ===============================
  // REMOVE VIETNAMESE ACCENT
  // ===============================
  static String _noAccent(String str) {
    const withAccent =
        'àáạảãâầấậẩẫăằắặẳẵ'
        'èéẹẻẽêềếệểễ'
        'ìíịỉĩ'
        'òóọỏõôồốộổỗơờớợởỡ'
        'ùúụủũưừứựửữ'
        'ỳýỵỷỹ'
        'đ'
        'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ'
        'ÈÉẸẺẼÊỀẾỆỂỄ'
        'ÌÍỊỈĨ'
        'ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ'
        'ÙÚỤỦŨƯỪỨỰỬỮ'
        'ỲÝỴỶỸ'
        'Đ';

    const withoutAccent =
        'aaaaaaaaaaaaaaaaa'
        'eeeeeeeeeee'
        'iiiii'
        'ooooooooooooooooo'
        'uuuuuuuuuuu'
        'yyyyy'
        'd'
        'AAAAAAAAAAAAAAAAA'
        'EEEEEEEEEEE'
        'IIIII'
        'OOOOOOOOOOOOOOOOO'
        'UUUUUUUUUUU'
        'YYYYY'
        'D';

    for (int i = 0; i < withAccent.length; i++) {
      str = str.replaceAll(withAccent[i], withoutAccent[i]);
    }
    return str;
  }

  static String _money(int value) {
    return NumberFormat('#,###', 'vi_VN').format(value);
  }

  // ===============================
  // PRINT MOMO QR
  // ===============================
  static Future<void> _printMomoQr(NetworkPrinter printer) async {
    final data = await rootBundle.load('assets/images/momo_qr.png');
    final bytes = data.buffer.asUint8List();
    final image = img.decodeImage(bytes);
    if (image == null) return;

    final resized = img.copyResize(image, width: 280);
    printer.image(resized, align: PosAlign.center);
  }

  // ===============================
  // CORE PRINT
  // ===============================
  static Future<void> _printEscPos({
    required String title,
    required String tableName,
    required String staffName,
    required List<OrderItem> items,
    required int total,
    int? orderCount,
    bool showQr = false,
    bool isTempBill = false,
    bool isReprint = false,
  }) async {
    if (kIsWeb) return;

    final profile = await CapabilityProfile.load();
    final printer = NetworkPrinter(PaperSize.mm80, profile);

    final res = await printer.connect(
      _printerIp,
      port: _printerPort,
      timeout: const Duration(seconds: 5),
    );

    if (res != PosPrintResult.success) {
      throw Exception('Khong ket noi duoc may in');
    }

    final timeStr = DateFormat('HH:mm dd/MM/yyyy').format(DateTime.now());

    // ===============================
    // REPRINT
    // ===============================
    if (isReprint) {
      printer.text(
        '*** IN LAI BILL ***',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      printer.feed(1);
    }

    // ===============================
    // HEADER
    // ===============================
    printer.text(
      'CAFE HEHE',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size3,
        width: PosTextSize.size3,
      ),
    );

    printer.text(
      '130 NGUYEN XI - HOA MINH - DA NANG',
      styles: const PosStyles(align: PosAlign.center),
    );

    printer.text(
      _noAccent(title),
      styles: const PosStyles(align: PosAlign.center),
    );

    printer.text(
      'BAN - ${_noAccent(tableName)}',
      styles: const PosStyles(align: PosAlign.center),
    );

    if (orderCount != null) {
      printer.text(
        'MA HOA DON: $orderCount',
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    printer.text('Gio: $timeStr');
    printer.text('Thu ngan: ${_noAccent(staffName)}');
    printer.hr();

    // ===============================
    // TABLE HEADER (NO CỘT TỔNG)
    // ===============================
    printer.text(
      'TEN MON                       SL         GIA',
      styles: const PosStyles(bold: true),
    );
    printer.hr();

    // ===============================
    // ITEMS
    // ===============================
    for (final e in items) {
      final name = _noAccent(e.name).padRight(20).substring(0, 20);
      final qty = e.quantity.toString().padLeft(11);
      final price = _money(e.price * e.quantity).padLeft(12);

      printer.text('$name $qty $price');
    }

    printer.hr();

    // ===============================
    // TOTAL (KHÔNG IN CHO BILL TẠM)
    // ===============================
    if (!isTempBill) {
      printer.text(
        'TONG TIEN'.padRight(30) + _money(total).padLeft(15),
        styles: const PosStyles(bold: true),
      );
    }

    // ===============================
    // QR
    // ===============================
    if (showQr && !isTempBill) {
      await _printMomoQr(printer);
    }

    // ===============================
    // FOOTER
    // ===============================
    printer.feed(1);
    printer.text(
      'Quy khach vui long kiem tra hoa don',
      styles: const PosStyles(align: PosAlign.center),
    );
    printer.text(
      'Xin cam on - Hen gap lai!',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );

    printer.cut();
    printer.disconnect();
  }

  // ===============================
  // BILL TẠM
  // ===============================
  static Future<void> printTemp({
    required String tableName,
    required String staffName,
    required List<OrderItem> items,
    required int total,
    required int orderCount,
    bool isReprint = false,
  }) async {
    await _printEscPos(
      title: 'TAM TINH',
      tableName: tableName,
      staffName: staffName,
      items: items,
      total: total,
      orderCount: orderCount,
      isTempBill: true,
      showQr: false,
      isReprint: isReprint,
    );
  }

  // ===============================
  // BILL THANH TOÁN
  // ===============================
  static Future<void> printFinal({
    required String tableName,
    required String staffName,
    required List<OrderItem> items,
    required int total,
    bool isReprint = false,
  }) async {
    await _printEscPos(
      title: 'HOA DON',
      tableName: tableName,
      staffName: staffName,
      items: items,
      total: total,
      showQr: true,
      isTempBill: false,
      isReprint: isReprint,
    );
  }
}
