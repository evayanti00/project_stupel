import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';  // pastikan file ini ada

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'STUPEL Mobile',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(), // masuk ke LoginScreen
    );
  }
}
