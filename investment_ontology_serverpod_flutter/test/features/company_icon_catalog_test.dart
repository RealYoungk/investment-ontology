import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/components/company_icon_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('authored SVG foreground survives the Flutter renderer', () async {
    final picture = await vg.loadPicture(
      SvgStringLoader(
        File('assets/company_icons/415640.svg').readAsStringSync(),
      ),
      null,
    );
    final rendered = await picture.picture.toImage(96, 96);
    final pixels = await rendered.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    var goldPixels = 0;
    for (var i = 0; i < pixels!.lengthInBytes; i += 4) {
      if (pixels.getUint8(i) == 255 &&
          pixels.getUint8(i + 1) == 203 &&
          pixels.getUint8(i + 2) == 54) {
        goldPixels++;
      }
    }
    expect(
      goldPixels,
      greaterThan(100),
      reason: 'Brand foreground must not become a black silhouette',
    );
    rendered.dispose();
    picture.picture.dispose();
  });
  test(
    'every issuer has inspectable artwork and authored marks are classified',
    () {
      final records = jsonDecode(
        File('assets/company_icons/PROVENANCE.json').readAsStringSync(),
      ) as List;
      expect(records.length, companyVectorIcons.length);
      for (final record in records) {
        final code = record['stockCode'] as String;
        expect(companyVectorIcons.containsKey(code), isTrue, reason: code);
        expect(
          File('assets/company_icons/${record['asset']}').existsSync(),
          isTrue,
          reason: code,
        );
        if (record['method'] == 'service-authored-vector-identity') {
          expect(record['officialArtwork'], isFalse, reason: code);
          expect(record['designConcept'], isNotEmpty, reason: code);
          expect(
            companyServiceVectorCodes.contains(code),
            isTrue,
            reason: code,
          );
          expect(record.containsKey('imageUrl'), isFalse, reason: code);
        }
      }
      expect(companyVectorIcons.containsKey('415640'), isTrue);
      expect(companyVectorIcons.containsKey('0197V0'), isTrue);
    },
  );

  test(
    'every catalog asset decodes with the Flutter PNG or SVG renderer',
    () async {
      for (final entry in companyVectorIcons.entries) {
        if (companyServiceVectorCodes.contains(entry.key)) {
          final picture = await vg.loadPicture(
            SvgStringLoader(File(entry.value).readAsStringSync()),
            null,
          );
          expect(picture.size.width, greaterThan(0), reason: entry.key);
          picture.picture.dispose();
          continue;
        }
        final bytes = File(entry.value.replaceAll('.svg', '.png'))
            .readAsBytesSync();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, greaterThan(0), reason: entry.key);
        expect(frame.image.height, greaterThan(0), reason: entry.key);
        frame.image.dispose();
        codec.dispose();
      }
      expect(companyVectorCodesByCorp['00765569'], '420770');
      expect(companyVectorCodesByCorp['01829819'], '0007C0');
    },
  );
}
