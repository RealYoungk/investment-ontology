import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 리브랜딩이 브랜드 파일 교체만으로 끝나도록, 화면 코드가 색·글꼴을 직접 정하지 않는지 확인한다.
void main() {
  final featureFiles = [Directory('lib/features'), Directory('lib/app')]
      .expand((d) => d.listSync(recursive: true))
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  test('화면 코드는 색 값을 직접 쓰지 않는다 (디자인 토큰 사용)', () {
    final offenders = [
      for (final f in featureFiles)
        if (RegExp(
          r'Color\(0x|Colors\.(?!transparent)',
        ).hasMatch(f.readAsStringSync()))
          f.path,
    ];
    expect(offenders, isEmpty);
  });

  test('화면 코드는 글꼴이나 브랜드를 직접 참조하지 않는다', () {
    final offenders = [
      for (final f in featureFiles)
        if (RegExp(
          r'google_fonts|GoogleFonts|design/brands/',
        ).hasMatch(f.readAsStringSync()))
          f.path,
    ];
    expect(offenders, isEmpty);
  });
}
