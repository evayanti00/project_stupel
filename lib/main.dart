import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'theme.dart';
import 'services/auth_provider.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);
  Intl.defaultLocale = 'id';
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const StupelApp(),
    ),
  );
}

class StupelApp extends StatelessWidget {
  const StupelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'STUPEL',
      theme: appTheme(),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
