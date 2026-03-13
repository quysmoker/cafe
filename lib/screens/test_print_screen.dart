import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TestPrintScreen extends StatefulWidget {
  const TestPrintScreen({super.key});

  @override
  State<TestPrintScreen> createState() => _TestPrintScreenState();
}

class _TestPrintScreenState extends State<TestPrintScreen> {
  String result = "Chưa test";

  final String serverIp = "192.168.100.200";

  Future<void> testConnection() async {
    try {
      final url = Uri.parse("http://$serverIp:8080/print");

      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "type": "final",
          "tableName": "TEST",
          "staffName": "TEST",
          "total": 0,
          "items": [],
        }),
      );

      setState(() {
        result = "Status: ${res.statusCode} \n${res.body}";
      });
    } catch (e) {
      setState(() {
        result = "Lỗi kết nối:\n$e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("TEST PRINT SERVER")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Test kết nối iPhone → Android",
              style: TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: testConnection,
              child: const Text("TEST KẾT NỐI"),
            ),

            const SizedBox(height: 30),

            Text(result),
          ],
        ),
      ),
    );
  }
}
