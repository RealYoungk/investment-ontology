import 'package:flutter/material.dart';

import 'client.dart';
import 'design/app_theme.dart';
import 'design/brands/ledger_brand.dart';
import 'features/company_ledger/company_ledger_page.dart';

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
      title: '투자 온톨로지',
      debugShowCheckedModeBanner: false,
      // 리브랜딩: 새 AppBrand를 만들어 여기만 바꾼다.
      theme: buildAppTheme(ledgerBrand),
      home: const CompanyLedgerPage(),
    );
  }
}
