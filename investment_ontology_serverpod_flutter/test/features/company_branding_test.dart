import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:investment_ontology_serverpod_flutter/design/components/company_icon_catalog.dart';
import 'package:investment_ontology_serverpod_flutter/design/components/company_logo.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/research_desk_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/common/company_display_name.dart';

void main() {
  test('client/server presentation rules agree', () {
    expect(
      File('lib/features/common/company_display_name.dart').readAsStringSync(),
      File(
        '../investment_ontology_serverpod_server/lib/src/ontology/presentation/company_display_name.dart',
      ).readAsStringSync(),
    );
    expect(companyDisplayName(name: '에스케이하이닉스', stockCode: '000660'), 'SK하이닉스');
    expect(companyDisplayName(name: '주식회사 테스트', stockName: '테스트브랜드'), '테스트브랜드');
  });
  test('bundled logos have source records and known issuer mapping', () {
    final records = jsonDecode(
      File('assets/company_logos/PROVENANCE.json').readAsStringSync(),
    ) as List;
    for (final record in records) {
      final path = CompanyLogo.assetFor(
        stockCode: record['stockCode'] as String,
      );
      expect(path, isNotNull);
      expect(File(path!).lengthSync(), record['bytes']);
      expect(Uri.parse(record['pageUrl'] as String).scheme, 'https');
    }
    expect(
      CompanyLogo.assetFor(corpCode: '00164779'),
      CompanyLogo.assetFor(stockCode: '000660'),
    );
    expect(CompanyLogo.assetFor(stockCode: '999999'), isNull);
  });
  test('original letter marks handle names safely', () {
    expect(CompanyLogo.initials('(주)아크릴'), '아');
    expect(CompanyLogo.initials('ABC테스트'), 'AB');
    expect(CompanyLogo.initials(''), '?');
  });
  testWidgets(
    'compact logos render successfully at search and detail sizes',
    (tester) async {
      for (final size in [24.0, 36.0, 48.0]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(researchDeskBrand),
            home: Scaffold(
              body: Row(
                children: [
                  for (final code in [
                    '005930',
                    '000660',
                    '005380',
                    '035420',
                    '059090',
                    '0007C0',
                  ])
                    CompanyLogo(name: '회사', stockCode: code, size: size),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(CompanyLogo), findsNWidgets(6));
        final vectorCount = [
          '005930',
          '000660',
          '035420',
          '059090',
          '0007C0',
        ].where(companyServiceVectorCodes.contains).length;
        expect(find.byType(SvgPicture), findsNWidgets(vectorCount));
        expect(find.byType(Image), findsNWidgets(6 - vectorCount));
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets('secondary ticker resolves the issuer logo through corp code', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(researchDeskBrand),
        home: const Scaffold(
          body: CompanyLogo(
            name: '삼성전자우',
            stockCode: '005935',
            corpCode: '00126380',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(
      (svg.bytesLoader as SvgAssetLoader).assetName,
      'assets/company_icons/005930.svg',
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'missing issuer uses local letter mark without an image request',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(researchDeskBrand),
          home: const Scaffold(
            body: CompanyLogo(name: '테스트', stockCode: '999999'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(CompanyLogo),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
