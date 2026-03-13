library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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

  /// ===============================
  /// QUEUE PRINT
  /// ===============================
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

  /// ===============================
  /// PRINT TEMP BILL
  /// ===============================
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

  /// ===============================
  /// PRINT FINAL BILL
  /// ===============================
  static Future<PrinterResult> printFinalBill({
    required String tableName,
    required String staffName,
    required List<OrderItem> items,
    required int total,
    bool isReprint = false,
  }) async {
    /// WEB -> GỬI LỆNH IN QUA ANDROID
    if (kIsWeb) {
      final url = Uri.parse('http://192.168.100.200:8080/print');

      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tableName': tableName,
          'staffName': staffName,
          'total': total,
          'items': items.map((e) => e.toJson()).toList(),
        }),
      );

      return PrinterResult(PrinterStatus.connected, 'Đã gửi lệnh in');
    }

    /// ANDROID IN LOCAL
    await BillPrinter.printFinal(
      tableName: tableName,
      staffName: staffName,
      items: items,
      total: total,
      isReprint: isReprint,
    );

    return PrinterResult(PrinterStatus.connected, 'Đã in bill');
  }

  /// ===============================
  /// PRINT SERVER FOR WEB
  /// ===============================
  static Future<void> startPrintServer() async {
    final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);

    print('PRINT SERVER RUNNING');
    print('PORT: 8080');

    await for (HttpRequest request in server) {
      if (request.method == 'POST' && request.uri.path == '/print') {
        final content = await utf8.decoder.bind(request).join();
        final data = jsonDecode(content);

        final List<OrderItem> items = (data['items'] as List)
            .map((e) => OrderItem.fromJson(e))
            .toList();

        await printFinalBill(
          tableName: data['tableName'],
          staffName: data['staffName'],
          items: items,
          total: data['total'],
        );

        request.response
          ..statusCode = 200
          ..write('printed')
          ..close();
      } else {
        request.response
          ..statusCode = 404
          ..close();
      }
    }
  }
}
