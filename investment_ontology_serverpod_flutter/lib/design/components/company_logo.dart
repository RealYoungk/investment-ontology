import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'company_icon_catalog.dart';
import '../tokens.dart';

/// Compact bundled identity artwork, with company originals as a fallback.
/// No third-party logo service is called while rendering.
class CompanyLogo extends StatelessWidget {
  const CompanyLogo({
    super.key,
    required this.name,
    this.stockCode,
    this.corpCode,
    this.size = 32,
  });

  final String name;
  final String? stockCode, corpCode;
  final double size;

  static const _codes = {
    '00164779': '000660',
    '00126380': '005930',
    '00164742': '005380',
    '00266961': '035420',
    '00366942': '059090',
    '01829819': '0007C0',
  };
  static const _logos = {
    '000660',
    '005930',
    '005380',
    '035420',
    '059090',
    '0007C0',
  };

  static String? assetFor({String? stockCode, String? corpCode}) {
    final code =
        companyVectorIcons.containsKey(stockCode) || _logos.contains(stockCode)
        ? stockCode
        : companyVectorCodesByCorp[corpCode] ?? _codes[corpCode] ?? stockCode;
    return code != '0007C0' && _logos.contains(code)
        ? 'assets/company_logos/$code.webp'
        : null;
  }

  static String initials(String name) {
    final cleaned = name
        .trim()
        .replaceFirst(RegExp(r'^(?:주식회사\s*|\(주\)\s*|㈜\s*)'), '')
        .replaceFirst(RegExp(r'(?:\s*주식회사|\s*\(주\)|\s*㈜)$'), '')
        .trim();
    if (cleaned.isEmpty) return '?';
    final latin = RegExp(r'^[A-Za-z]{1,2}').firstMatch(cleaned);
    return latin?.group(0)?.toUpperCase() ??
        String.fromCharCode(cleaned.runes.first);
  }

  @override
  Widget build(BuildContext context) {
    final code =
        companyVectorIcons.containsKey(stockCode) || _logos.contains(stockCode)
        ? stockCode
        : companyVectorCodesByCorp[corpCode] ?? _codes[corpCode] ?? stockCode;
    final vector = companyVectorIcons[code];
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * .22),
        child: SizedBox.square(
          dimension: size,
          child: code == '005380'
              ? _HyundaiOriginalMark(size: size)
              : vector == null
              ? CustomPaint(painter: _CompanyIconPainter(code, name))
              : Container(
                  color: companyVectorDarkBackground.contains(code)
                      ? context.colors.inverse
                      : context.colors.surface,
                  padding: companyServiceVectorCodes.contains(code)
                      ? EdgeInsets.zero
                      : EdgeInsets.all(size * .08),
                  child: companyServiceVectorCodes.contains(code)
                      ? SvgPicture.asset(
                          vector,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => CustomPaint(
                            painter: _CompanyIconPainter(code, name),
                          ),
                        )
                      : Image.asset(
                          vector.replaceAll('.svg', '.png'),
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => CustomPaint(
                            painter: _CompanyIconPainter(code, name),
                          ),
                        ),
                ),
        ),
      ),
    );
  }
}

/// Preserve the official emblem pixels; the adjacent wordmark is outside
/// the viewport. No vector approximation or distortion of the H symbol.
class _HyundaiOriginalMark extends StatelessWidget {
  const _HyundaiOriginalMark({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.colors.surface,
    child: Padding(
      padding: EdgeInsets.all(size * .08),
      child: Center(
        child: AspectRatio(
          aspectRatio: 84 / 43,
          child: ClipRect(
            child: LayoutBuilder(
              builder: (context, box) {
                final imageWidth = box.maxHeight * 310 / 43;
                return OverflowBox(
                  alignment: Alignment.centerLeft,
                  minWidth: imageWidth,
                  maxWidth: imageWidth,
                  child: Image.asset(
                    'assets/company_icons/005380.png',
                    width: imageWidth,
                    height: box.maxHeight,
                    fit: BoxFit.fill,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}

/// Service-authored vector identifiers, inspired by issuer wordmarks/symbols.
/// They are never presented as downloaded official artwork.
class _CompanyIconPainter extends CustomPainter {
  const _CompanyIconPainter(this.code, this.name);
  final String? code;
  final String name;

  void label(
    Canvas canvas,
    String value,
    Color color,
    Rect box, {
    bool italic = false,
    double weight = 1,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          fontFamily: 'Arial',
          letterSpacing: weight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final scale = (box.width / painter.width).clamp(
      0.0,
      box.height / painter.height,
    );
    canvas.save();
    canvas.translate(
      box.left + (box.width - painter.width * scale) / 2,
      box.top + (box.height - painter.height * scale) / 2,
    );
    canvas.scale(scale);
    painter.paint(canvas, Offset.zero);
    canvas.restore();
    painter.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final paint = Paint();
    Color background = const Color(0xffeef2f7);
    Color foreground = const Color(0xff355d84);
    String text = CompanyLogo.initials(name);
    switch (code) {
      case '005930':
        background = const Color(0xff1428a0);
        foreground = const Color(0xffffffff);
        text = 'SAMSUNG';
      case '059090':
        foreground = const Color(0xff153477);
        text = 'MiCo';
      case '035420':
        background = const Color(0xff03c75a);
        foreground = const Color(0xffffffff);
        text = 'N';
      case '005380':
        foreground = const Color(0xff003d7b);
        text = 'H';
      case '000660':
        foreground = const Color(0xffdc1728);
        text = 'SK';
      case '0007C0':
        background = const Color(0xffe9f8fa);
      default:
        final palette = [
          const Color(0xff355d84),
          const Color(0xff2d6b62),
          const Color(0xff745384),
          const Color(0xff966129),
        ];
        if (code == null || !CompanyLogo._logos.contains(code)) {
          final key = code ?? name;
          foreground =
              palette[key.codeUnits.fold<int>(0, (a, b) => a + b) %
                  palette.length];
          final cleaned = name.replaceAll(RegExp(r'주식회사|\(주\)|㈜|\s'), '');
          if (cleaned.isNotEmpty && !RegExp(r'^[A-Za-z]').hasMatch(cleaned)) {
            text = String.fromCharCodes(cleaned.runes.take(2));
          }
        }
    }
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 100, 100),
      paint..color = background,
    );
    if (code == '0007C0') {
      const vertices = [
        Offset(26, 14),
        Offset(16, 84),
        Offset(85, 67),
        Offset(45, 47),
      ];
      final shades = [
        const Color(0xff0474bb),
        const Color(0xff11a6bb),
        const Color(0xff46dec5),
      ];
      for (var i = 0; i < 3; i++) {
        final path = Path()
          ..moveTo(vertices[i].dx, vertices[i].dy)
          ..lineTo(vertices[(i + 1) % 3].dx, vertices[(i + 1) % 3].dy)
          ..lineTo(vertices[3].dx, vertices[3].dy)
          ..close();
        canvas.drawPath(path, paint..color = shades[i]);
      }
    } else if (code == '005380') {
      canvas.drawOval(
        const Rect.fromLTWH(12, 27, 76, 46),
        Paint()
          ..color = foreground
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
      label(
        canvas,
        text,
        foreground,
        const Rect.fromLTWH(30, 27, 40, 46),
        italic: true,
      );
    } else if (code == '000660') {
      final wing = Path()
        ..moveTo(54, 15)
        ..lineTo(82, 28)
        ..lineTo(61, 37)
        ..lineTo(55, 49)
        ..lineTo(44, 34)
        ..close();
      canvas.drawPath(wing, paint..color = const Color(0xfff36d21));
      label(canvas, 'SK', foreground, const Rect.fromLTWH(13, 43, 37, 26));
      label(
        canvas,
        'hynix',
        const Color(0xffec6924),
        const Rect.fromLTWH(53, 43, 37, 26),
      );
    } else {
      label(
        canvas,
        text,
        foreground,
        Rect.fromLTWH(10, 20, 80, 60),
        italic: code == '059090',
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CompanyIconPainter oldDelegate) =>
      oldDelegate.code != code || oldDelegate.name != name;
}
