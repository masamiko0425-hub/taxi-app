import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/booking_screen.dart';
// flutterfire configure で生成される firebase_options.dart を用意してください
// import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TaxiApp());
}

class TaxiApp extends StatelessWidget {
  const TaxiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'タクシー配車MVP',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      // customerId は本来ログイン後に取得する
      home: const BookingScreen(customerId: 'demo-customer-001'),
    );
  }
}
