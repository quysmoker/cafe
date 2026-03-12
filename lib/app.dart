import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/order_online_provider.dart';
import 'providers/product_online_provider.dart';
import 'providers/table_online_provider.dart';
import 'screens/admin_home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/staff_home_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => TableOnlineProvider()),
        ChangeNotifierProvider(create: (_) => OrderOnlineProvider()),
        ChangeNotifierProvider(create: (_) => ProductOnlineProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CafeHeHe POS',
        theme: ThemeData(primarySwatch: Colors.brown),
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
