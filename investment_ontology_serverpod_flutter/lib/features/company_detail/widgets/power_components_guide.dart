import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../design/tokens.dart';
import 'business_guide_navigation.dart';
import 'optical_assembly_diagram.dart';

/// Shared product-family explanation. Company attribution is checked separately
/// against the current filing. All illustrations are original conceptual drawings.
class PowerComponentsGuide extends StatefulWidget {
  const PowerComponentsGuide({super.key, this.includeOptical = false});
  final bool includeOptical;
  @override
  State<PowerComponentsGuide> createState() => _PowerComponentsGuideState();
}

class _PowerComponentsGuideState extends State<PowerComponentsGuide> {
  int _step = 0;
  static const _titles = ['PSU와 콘덴서', '증착필름', '누가 왜 사나요?'];
  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = context.typo;
    final titles = [if (widget.includeOptical) '광통신 장비', ..._titles];
    final productStep = _step - (widget.includeOptical ? 1 : 0);
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: context.shape.borderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.includeOptical
                ? '광통신 부품을 만드는 장비와\n전자기기에 전기를 공급하는 부품'
                : '전자기기에 맞는 전기를 만들고,\n그 전기를 안정시키는 부품',
            style: t.body(24, weight: FontWeight.w700).copyWith(height: 1.4),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            widget.includeOptical
                ? '광통신 장비는 자회사 ADS테크의 사업입니다. 전원장치·콘덴서·증착필름은 기존 전자부품 사업입니다.'
                : 'PSU는 전기를 바꾸는 장치, 필름콘덴서는 그 안에 쓰이는 부품입니다. 증착필름은 콘덴서를 만드는 재료로, 얇은 플라스틱 필름에 금속을 입힌 것입니다.',
            style: t.body(14, color: c.textSecondary).copyWith(height: 1.7),
          ),
          const SizedBox(height: AppSpace.lg),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (var i = 0; i < titles.length; i++)
                ChoiceChip(
                  label: Text(
                    '${i + 1}. ${widget.includeOptical && i == 3 ? '전자부품 고객' : titles[i]}',
                  ),
                  selected: _step == i,
                  onSelected: (_) => setState(() => _step = i),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          if (widget.includeOptical && _step == 0) ...[
            _heading('빛이 정확히 통하도록, 작은 부품의 위치를 맞춥니다.'),
            _body(
              '광통신 모듈은 전기 신호를 빛으로 바꿔 광섬유로 보내고, 받은 빛을 다시 전기 신호로 바꾸는 부품입니다. 데이터센터의 서버 사이에서 많은 데이터를 주고받는 데 쓰입니다.',
            ),
            const OpticalAssemblyDiagram(),
            _body(
              'ADS테크의 고객은 이런 광통신 모듈·칩을 만드는 업체입니다. 성호전자는 2026년 2월 ADS테크를 인수해 이 장비 사업을 연결 대상에 포함했습니다.',
            ),
          ],
          if (productStep == 0) ...[
            _heading('프린터 → 전원 보드 → 작은 부품 순서로 확대해 보세요.'),
            _body(
              '콘센트의 교류 전기를 기기가 쓰는 직류 전기로 바꾸는 장치가 PSU입니다. SMPS는 전기를 빠르게 켜고 끄는 방식으로 변환하는 전원공급장치를 뜻합니다.',
            ),
            const PowerComponentDiagram(film: false),
            _body(
              '전원 보드 전체가 전원공급장치입니다. 빨간 원 속 부품을 확대한 것이 필름콘덴서입니다. 콘덴서는 전하를 잠깐 저장하고 내보내며, 회로의 전기적 잡음이나 전압 변동을 줄이는 데 쓰입니다.',
            ),
          ],
          if (productStep == 1) ...[
            _heading('증착필름은 필름콘덴서의 핵심 재료입니다.'),
            _body(
              '‘증착’은 표면에 얇은 층을 입히는 것입니다. 플라스틱 필름에 아주 얇은 금속층을 입히면, 전극 역할을 하는 금속과 절연 역할을 하는 필름이 한 장에 결합됩니다.',
            ),
            const PowerComponentDiagram(film: true),
            _body(
              '두 장의 증착필름을 겹쳐 감아 속심을 만들고, 단자와 보호 케이스를 붙이면 필름콘덴서가 됩니다. 증착필름은 재료 단계의 제품이고, 콘덴서는 그 재료를 가공한 부품이라는 차이가 있습니다.',
            ),
          ],
          if (productStep == 2) ...[
            _heading('같은 전자기기 안에서도 판매 단위가 다릅니다.'),
            const _ProductCustomerDiagram(),
          ],
          const SizedBox(height: AppSpace.lg),
          BusinessGuideNavigation(
            step: _step,
            count: titles.length,
            onChanged: (value) => setState(() => _step = value),
          ),
        ],
      ),
    );
  }

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.sm),
    child: Text(
      text,
      style: context.typo
          .body(18, weight: FontWeight.w700)
          .copyWith(height: 1.5),
    ),
  );
  Widget _body(String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.md),
    child: Text(text, style: context.typo.body(14).copyWith(height: 1.8)),
  );
}

/// Three independent sales relationships: each row pairs a product and buyer.
class _ProductCustomerDiagram extends StatelessWidget {
  const _ProductCustomerDiagram();
  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = context.typo;
    const rows = [
      ('film', '증착필름', '콘덴서 제조사', '필름을 감아 콘덴서를 만듭니다.', Icons.factory_outlined),
      (
        'capacitor',
        '필름콘덴서',
        '전원장치·전자기기 제조사',
        '회로에 넣어 전기를 안정시킵니다.',
        Icons.memory_outlined,
      ),
      (
        'board',
        'PSU · 전원장치',
        '완성 기기 제조사',
        '프린터·조명 등에 전원을 공급합니다.',
        Icons.print_outlined,
      ),
    ];
    return Column(
      children: [
        for (final row in rows)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpace.md),
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: c.background,
              borderRadius: context.shape.borderRadius,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        row.$2,
                        textAlign: TextAlign.center,
                        style: t.body(14, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      SizedBox(
                        height: 88,
                        child: AspectRatio(
                          aspectRatio: 1.35,
                          child: CustomPaint(
                            painter: _ObjectPainter(c, row.$1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                  child: Column(
                    children: [
                      Text('판매', style: t.body(11, color: c.accent)),
                      Icon(Icons.arrow_forward, color: c.accent, size: 24),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Icon(row.$5, size: 32, color: c.accent),
                      const SizedBox(height: AppSpace.sm),
                      Text(
                        row.$3,
                        textAlign: TextAlign.center,
                        style: t.body(14, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        row.$4,
                        textAlign: TextAlign.center,
                        style: t
                            .body(12, color: c.textSecondary)
                            .copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Fixed-aspect illustrations; labels use normal Flutter text and never scale
/// independently of a diagram. Arrows mean zoom/unwrapping, not current flow.
class PowerComponentDiagram extends StatelessWidget {
  const PowerComponentDiagram({super.key, required this.film});
  final bool film;
  @override
  Widget build(BuildContext context) {
    final scenes = film
        ? const [
            ('film', '① 증착필름 · 재료', '금속층과 필름은 실제로 붙어 있습니다. 구분하기 위해 띄워 그렸습니다.'),
            ('roll', '② 겹쳐 감은 속심', '두 장을 겹쳐 감아 작은 부피에 넣습니다.'),
            ('capacitor', '③ 필름콘덴서 · 부품', '속심에 두 단자와 보호 케이스를 붙입니다.'),
          ]
        : const [
            ('printer', '① 완성 기기 · 프린터', '전기를 받아 인쇄하는 완제품'),
            ('board', '② 내부의 전원 보드', '기기에 필요한 전기를 만드는 PSU'),
            ('capacitor', '③ 보드 위 필름콘덴서', '전하를 저장하고 내보내는 작은 부품'),
          ];
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.sm, bottom: AppSpace.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 580;
          Widget arrow(int i) => Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpace.sm,
              horizontal: AppSpace.xs,
            ),
            child: Icon(
              wide ? Icons.arrow_forward : Icons.arrow_downward,
              color: context.colors.marketUp,
              size: 20,
            ),
          );
          final cards = [
            for (final scene in scenes)
              _Scene(kind: scene.$1, title: scene.$2, caption: scene.$3),
          ];
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 84),
                      child: arrow(i),
                    ),
                  Expanded(child: cards[i]),
                ],
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) arrow(i),
                cards[i],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Scene extends StatelessWidget {
  const _Scene({
    required this.kind,
    required this.title,
    required this.caption,
  });
  final String kind, title, caption;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpace.md),
    decoration: BoxDecoration(
      color: context.colors.background,
      border: Border.all(color: context.colors.border),
      borderRadius: context.shape.borderRadius,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.typo.body(14, weight: FontWeight.w700)),
        const SizedBox(height: AppSpace.sm),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: AspectRatio(
              aspectRatio: 1.35,
              child: CustomPaint(painter: _ObjectPainter(context.colors, kind)),
            ),
          ),
        ),
        if (kind == 'film') ...[
          _legend(context, context.colors.chartSeries2, '금속층 · 전극 역할'),
          _legend(context, context.colors.chartSeries1, '플라스틱 필름 · 절연 역할'),
          const SizedBox(height: AppSpace.sm),
        ],
        Text(
          caption,
          style: context.typo
              .body(13, color: context.colors.textSecondary)
              .copyWith(height: 1.6),
        ),
      ],
    ),
  );
  Widget _legend(BuildContext context, Color color, String text) => Padding(
    padding: const EdgeInsets.only(top: AppSpace.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 3),
          color: color,
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(child: Text(text, style: context.typo.body(12))),
      ],
    ),
  );
}

/// Original object illustrations, drawn in a single coordinate space so narrow
/// layouts cannot stretch components, disconnect their leads or clip labels.
class _ObjectPainter extends CustomPainter {
  _ObjectPainter(this.c, this.kind);
  final AppColors c;
  final String kind;
  void box(Canvas canvas, Rect rect, Color color, {double radius = 5}) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()..color = color,
    );
  }

  void line(
    Canvas canvas,
    List<Offset> points,
    Color color, {
    double width = 2,
  }) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  void polygon(Canvas canvas, List<Offset> points, Color color) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  void highlight(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = c.marketUp
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final scale = math.min(size.width / 216, size.height / 160);
    canvas.translate(
      (size.width - 216 * scale) / 2,
      (size.height - 160 * scale) / 2,
    );
    canvas.scale(scale);
    switch (kind) {
      case 'printer':
        // Paper feeder, body, output slot and printed sheet.
        box(canvas, const Rect.fromLTWH(58, 13, 100, 66), c.borderStrong);
        box(canvas, const Rect.fromLTWH(64, 17, 88, 57), c.surface);
        box(
          canvas,
          const Rect.fromLTWH(23, 52, 170, 78),
          c.textSecondary,
          radius: 10,
        );
        box(canvas, const Rect.fromLTWH(30, 62, 156, 59), c.border);
        box(canvas, const Rect.fromLTWH(52, 83, 112, 15), c.inverse);
        polygon(canvas, [
          const Offset(61, 91),
          const Offset(155, 91),
          const Offset(163, 146),
          const Offset(53, 146),
        ], c.surface);
        for (var i = 0; i < 3; i++) {
          line(canvas, [
            Offset(74, 107.0 + i * 10),
            Offset(142, 107.0 + i * 10),
          ], c.borderStrong);
        }
        canvas.drawCircle(const Offset(175, 74), 4, Paint()..color = c.accent);
        highlight(canvas, const Offset(39, 107), 21);
        break;
      case 'board':
        polygon(canvas, [
          const Offset(20, 38),
          const Offset(194, 38),
          const Offset(204, 128),
          const Offset(12, 128),
        ], c.accentSubtle);
        line(canvas, [
          const Offset(20, 38),
          const Offset(194, 38),
          const Offset(204, 128),
          const Offset(12, 128),
          const Offset(20, 38),
        ], c.accent);
        // PCB traces turn and terminate at components, rather than crossing them.
        line(canvas, [
          const Offset(20, 66),
          const Offset(48, 66),
          const Offset(48, 104),
          const Offset(86, 104),
        ], c.chartSeries1);
        line(canvas, [
          const Offset(124, 78),
          const Offset(147, 78),
          const Offset(147, 106),
          const Offset(193, 106),
        ], c.chartSeries1);
        line(canvas, [
          const Offset(34, 115),
          const Offset(57, 115),
          const Offset(57, 56),
          const Offset(158, 56),
        ], c.chartSeries1);
        box(canvas, const Rect.fromLTWH(75, 69, 48, 42), c.chartSeries2);
        box(canvas, const Rect.fromLTWH(84, 65, 30, 43), c.borderStrong);
        for (var i = 0; i < 5; i++) {
          line(
            canvas,
            [Offset(87.0 + i * 5, 72), Offset(87.0 + i * 5, 100)],
            c.chartSeries2,
            width: 3,
          );
        }
        box(canvas, const Rect.fromLTWH(23, 72, 15, 27), c.surface);
        box(canvas, const Rect.fromLTWH(181, 81, 13, 35), c.surface);
        canvas.drawOval(
          const Rect.fromLTWH(47, 72, 17, 8),
          Paint()..color = c.textPrimary,
        );
        box(
          canvas,
          const Rect.fromLTWH(47, 76, 17, 20),
          c.textSecondary,
          radius: 1,
        );
        // Same blue two-lead package as the enlarged next panel.
        line(canvas, [
          const Offset(153, 65),
          const Offset(153, 73),
        ], c.textPrimary);
        line(canvas, [
          const Offset(174, 65),
          const Offset(174, 73),
        ], c.textPrimary);
        box(
          canvas,
          const Rect.fromLTWH(145, 43, 36, 23),
          c.chartSeries1,
          radius: 3,
        );
        highlight(canvas, const Offset(163, 56), 29);
        break;
      case 'capacitor':
        line(
          canvas,
          [const Offset(78, 94), const Offset(78, 140)],
          c.borderStrong,
          width: 5,
        );
        line(
          canvas,
          [const Offset(146, 94), const Offset(146, 140)],
          c.borderStrong,
          width: 5,
        );
        polygon(canvas, [
          const Offset(43, 42),
          const Offset(58, 30),
          const Offset(181, 30),
          const Offset(166, 42),
        ], c.accent);
        polygon(canvas, [
          const Offset(166, 42),
          const Offset(181, 30),
          const Offset(181, 95),
          const Offset(166, 108),
        ], c.textSecondary);
        box(canvas, const Rect.fromLTWH(43, 42, 123, 67), c.chartSeries1);
        // Lead lines visibly join the case; no implied electrical circuit.
        break;
      case 'roll':
        box(
          canvas,
          const Rect.fromLTWH(48, 45, 120, 67),
          c.chartSeries2,
          radius: 1,
        );
        canvas.drawOval(
          const Rect.fromLTWH(28, 45, 43, 67),
          Paint()..color = c.accentSubtle,
        );
        canvas.drawOval(
          const Rect.fromLTWH(146, 45, 43, 67),
          Paint()..color = c.accentSubtle,
        );
        for (var i = 0; i < 7; i++) {
          canvas.drawOval(
            Rect.fromLTWH(
              149.0 + i * 2,
              48.0 + i * 4,
              37.0 - i * 4,
              61.0 - i * 8,
            ),
            Paint()
              ..color = i.isEven ? c.chartSeries1 : c.chartSeries2
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
        line(
          canvas,
          [const Offset(28, 79), const Offset(16, 79), const Offset(16, 128)],
          c.borderStrong,
          width: 4,
        );
        line(
          canvas,
          [
            const Offset(188, 79),
            const Offset(201, 79),
            const Offset(201, 128),
          ],
          c.borderStrong,
          width: 4,
        );
        break;
      case 'film':
        // Exploded view of ONE metallized film: metal coating directly above
        // its dielectric backing. Two such sheets are used in the wound part.
        polygon(canvas, [
          const Offset(27, 60),
          const Offset(148, 35),
          const Offset(191, 68),
          const Offset(70, 94),
        ], c.chartSeries2);
        polygon(canvas, [
          const Offset(27, 92),
          const Offset(148, 67),
          const Offset(191, 100),
          const Offset(70, 126),
        ], c.chartSeries1);
        line(canvas, [const Offset(27, 61), const Offset(27, 91)], c.marketUp);
        line(canvas, [
          const Offset(191, 69),
          const Offset(191, 99),
        ], c.marketUp);
        break;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ObjectPainter old) => old.c != c || old.kind != kind;
}
