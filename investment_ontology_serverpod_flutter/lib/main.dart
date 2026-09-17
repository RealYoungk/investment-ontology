import 'package:flutter/material.dart';

import 'client.dart';
import 'screens/ledger/ledger_screen.dart';
import 'theme/ledger_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeClient();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '투자 온톨로지 · 상장사 원장',
      debugShowCheckedModeBanner: false,
      theme: buildLedgerTheme(),
      home: const LedgerScreen(),
    );
  }
}
