import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';

class PrinterTestService {
  // Sau này đưa vào setting
  static const String printerIp = '192.168.1.100';
  static const int printerPort = 9100;

  /// ===============================
  /// IN BILL TEST (CHUẨN POS)
  /// ===============================
  static Future<void> testPrint(BuildContext context) async {
    NetworkPrinter? printer;

    try {
      final profile = await CapabilityProfile.load();
      printer = NetworkPrinter(PaperSize.mm58, profile);

      final res = await printer.connect(
        printerIp,
        port: printerPort,
        timeout: const Duration(seconds: 3),
      );

      // ❌ KHÔNG GỬI ĐƯỢC LỆNH → THẤT BẠI
      if (res != PosPrintResult.success) {
        _showSnack(
          context,
          '❌ Không gửi được lệnh in.\nKiểm tra nguồn hoặc mạng máy in.',
        );
        return;
      }

      // ===============================
      // BILL TEST – NHÌN LÀ BIẾT NGAY
      // ===============================
      printer.text(
        '*** BILL TEST ***',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );

      printer.feed(1);

      printer.text(
        'CAFE HEHE',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );

      printer.feed(1);

      printer.text(
        'Day la BILL TEST',
        styles: const PosStyles(align: PosAlign.center),
      );
      printer.text(
        'Khong co gia tri thanh toan',
        styles: const PosStyles(align: PosAlign.center),
      );
      printer.text(
        'Vui long kiem tra giay',
        styles: const PosStyles(align: PosAlign.center),
      );

      printer.feed(2);
      printer.cut();
    } catch (_) {
      _showSnack(context, '❌ Không gửi được lệnh in.\nKiểm tra máy in.');
      return;
    } finally {
      try {
        printer?.disconnect();
      } catch (_) {}
    }

    // 🔴 CHỈ HỎI NGƯỜI DÙNG – KHÔNG KẾT LUẬN
    _askConfirm(context);
  }

  /// ===============================
  /// XÁC NHẬN THỦ CÔNG (QUAN TRỌNG)
  /// ===============================
  static void _askConfirm(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận bill test'),
        content: const Text('Bill test có in ra giấy không?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnack(context, '⚠ Kiểm tra giấy / nắp / nguồn máy in');
            },
            child: const Text('Không in'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnack(context, '✅ Máy in hoạt động bình thường');
            },
            child: const Text('Đã in'),
          ),
        ],
      ),
    );
  }

  /// ===============================
  /// SNACKBAR
  /// ===============================
  static void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }
}
