import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/order_online_provider.dart';
import 'providers/product_online_provider.dart';
import 'providers/table_online_provider.dart';
import 'screens/admin_home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/staff_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ BẮT BUỘC: khởi tạo locale VN cho intl
  await initializeDateFormatting('vi_VN', null);

  await Supabase.initialize(
    url: 'https://epptwsimdvhlfrwonvwn.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVwcHR3c2ltZHZobGZyd29udnduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkzMzMzMTIsImV4cCI6MjA4NDkwOTMxMn0.FyuTpBA0SKBhJpPISPDMaCVr8DyquauLN55WHsW7YrI',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        /// AUTH
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        /// ADMIN STATE
        ChangeNotifierProvider(create: (_) => AdminProvider()),

        /// ONLINE DATA
        ChangeNotifierProvider(create: (_) => TableOnlineProvider()),
        ChangeNotifierProvider(create: (_) => OrderOnlineProvider()),
        ChangeNotifierProvider(create: (_) => ProductOnlineProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CafeHeHe POS',
        theme: ThemeData(primarySwatch: Colors.brown),

        // 🔴 PHẦN QUAN TRỌNG NHẤT (FIX LỖI DATEPICKER)
        locale: const Locale('vi', 'VN'),
        supportedLocales: const [Locale('vi', 'VN')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        home: const RootScreen(),
      ),
    );
  }
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isLogin) {
      return const LoginScreen();
    }

    if (auth.isAdmin) {
      return const AdminHomeScreen();
    }

    return const StaffHomeScreen();
  }
}
