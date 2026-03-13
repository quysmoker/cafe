library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/order_item.dart';
import 'bill_printer.dart';

enum PrinterStatus { connected, disconnected, error }

class PrinterResult {
  final PrinterStatus status;
  final String message;

  PrinterResult(this.status, this.message);
}

class PrinterService {
  /// IP ANDROID PRINT SERVER
  static const String _serverIp = "192.168.100.188";
  static const int _serverPort = 8080;

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
    /// WEB -> gửi request sang Android
    if (kIsWeb) {
      final url = Uri.parse("http://$_serverIp:$_serverPort/print");

      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "type": "temp",
          "tableName": tableName,
          "staffName": staffName,
          "orderCount": orderCount,
          "total": total,
          "items": items.map((e) => e.toJson()).toList(),
        }),
      );

      return PrinterResult(PrinterStatus.connected, "Đã gửi lệnh in bill tạm");
    }

    /// ANDROID IN LOCAL
    await BillPrinter.printTemp(
      tableName: tableName,
      staffName: staffName,
      items: items,
      total: total,
      orderCount: orderCount,
      isReprint: isReprint,
    );

    return PrinterResult(PrinterStatus.connected, "Đã in bill tạm");
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
    /// WEB -> gửi request sang Android
    if (kIsWeb) {
      final url = Uri.parse("http://$_serverIp:$_serverPort/print");

      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "type": "final",
          "tableName": tableName,
          "staffName": staffName,
          "total": total,
          "items": items.map((e) => e.toJson()).toList(),
        }),
      );

      return PrinterResult(PrinterStatus.connected, "Đã gửi lệnh in bill");
    }

    /// ANDROID IN LOCAL
    await BillPrinter.printFinal(
      tableName: tableName,
      staffName: staffName,
      items: items,
      total: total,
      isReprint: isReprint,
    );

    return PrinterResult(PrinterStatus.connected, "Đã in bill");
  }

  /// ===============================
  /// ANDROID PRINT SERVER
  /// ===============================
  static Future<void> startPrintServer() async {
    if (kIsWeb) return;

    final server = await HttpServer.bind(InternetAddress.anyIPv4, _serverPort);

    print("PRINT SERVER RUNNING");
    print("PORT: $_serverPort");

    await for (HttpRequest request in server) {
      if (request.method == "POST" && request.uri.path == "/print") {
        try {
          final content = await utf8.decoder.bind(request).join();
          final data = jsonDecode(content);

          final List<OrderItem> items = (data["items"] as List)
              .map((e) => OrderItem.fromJson(e))
              .toList();

          final type = data["type"];

          if (type == "temp") {
            await BillPrinter.printTemp(
              tableName: data["tableName"],
              staffName: data["staffName"],
              items: items,
              total: data["total"],
              orderCount: data["orderCount"] ?? 1,
            );
          } else {
            await BillPrinter.printFinal(
              tableName: data["tableName"],
              staffName: data["staffName"],
              items: items,
              total: data["total"],
            );
          }

          request.response.headers.add("Access-Control-Allow-Origin", "*");

          request.response
            ..statusCode = 200
            ..write("printed")
            ..close();
        } catch (e) {
          print("PRINT ERROR: $e");

          request.response
            ..statusCode = 500
            ..write("error")
            ..close();
        }
      } else {
        request.response
          ..statusCode = 404
          ..close();
      }
    }
  }
}
