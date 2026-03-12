// lib/core/printer/test_printer.dart

import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/foundation.dart';

class TestPrinter {
  static Future<String> testLanPrinter({
    required String ip,
    int port = 9100,
  }) async {
    // Emulator: không in thật
    if (kDebugMode) {
      return '⚠️ Đang chạy Emulator – không test in thật';
    }

    try {
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(PaperSize.mm80, profile);

      final res = await printer.connect(ip, port: port);
      if (res != PosPrintResult.success) {
        return '❌ Không kết nối được máy in ($res)';
      }

      printer.text(
        '=== TEST MAY IN ===',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );

      printer.text('Cafe HeHe');
      printer.text('Test LAN Printer');
      printer.feed(2);
      printer.cut();
      printer.disconnect();

      return '✅ In test thành công';
    } catch (e) {
      return '❌ Lỗi: $e';
    }
  }
}
