// lib/core/printer/printer_service.dart
library;

import '../../models/order_item.dart';
import 'bill_printer.dart';
import 'last_print_service.dart';

enum PrinterStatus { connected, disconnected, error }

class PrinterResult {
  final PrinterStatus status;
  final String message;

  PrinterResult(this.status, this.message);
}

class PrinterService {
  static bool _printing = false;
  static final List<Future<void> Function()> _queue = [];

  static void _runQueue() async {
    if (_printing || _queue.isEmpty) return;

    _printing = true;
    final job = _queue.removeAt(0);

    try {
      await job();
    } finally {
      _printing = false;
      _runQueue();
    }
  }

  // ===============================
  // IN BILL TẠM
  // ===============================
  static Future<PrinterResult> printTempBill({
    required String tableName,
    required String staffName,
    required List<OrderItem> items,
    required int total,
    required int orderCount,
    bool isReprint = false,
  }) async {
    _queue.add(() async {
      await BillPrinter.printTemp(
        tableName: tableName,
        staffName: staffName,
        items: items,
        total: total,
        orderCount: orderCount,
        isReprint: isReprint,
      );

      // ✅ CHỈ LƯU KHI KHÔNG PHẢI IN LẠI
      if (!isReprint) {
        LastPrintService.save(
          LastPrintData(
            type: 'temp',
            tableName: tableName,
            staffName: staffName,
            items: items,
            total: total,
            orderCount: orderCount,
          ),
        );
      }
    });

    _runQueue();
    return PrinterResult(
      PrinterStatus.connected,
      isReprint ? 'Đã in lại bill tạm' : 'Đã in bill tạm #$orderCount',
    );
  }

  // ===============================
  // IN BILL THANH TOÁN
  // ===============================
  static Future<PrinterResult> printFinalBill({
    required String tableName,
    required String staffName,
    required List<OrderItem> items,
    required int total,
    bool isReprint = false,
  }) async {
    _queue.add(() async {
      await BillPrinter.printFinal(
        tableName: tableName,
        staffName: staffName,
        items: items,
        total: total,
        isReprint: isReprint,
      );

      if (!isReprint) {
        LastPrintService.save(
          LastPrintData(
            type: 'final',
            tableName: tableName,
            staffName: staffName,
            items: items,
            total: total,
          ),
        );
      }
    });

    _runQueue();
    return PrinterResult(
      PrinterStatus.connected,
      isReprint ? 'Đã in lại bill thanh toán' : 'Đã in bill thanh toán',
    );
  }
}
