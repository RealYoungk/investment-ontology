import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/tokens.dart';

/// Source API routes and the project's actual storage definitions.
/// Refresh the bundled snapshot with scripts/data/build_catalog.py.
class DataReference extends StatefulWidget {
  const DataReference({
    required this.dataset,
    required this.collectionDetail,
    super.key,
  });

  final String dataset;
  final String collectionDetail;

  @override
  State<DataReference> createState() => _DataReferenceState();
}

class _DataReferenceState extends State<DataReference> {
  static final Future<Map<String, dynamic>> _catalog = rootBundle
      .loadString('assets/data/catalog.json')
      .then((text) => jsonDecode(text) as Map<String, dynamic>);

  @override
  Widget build(BuildContext context) {
    final t = context.typo;
    final c = context.colors;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        'API 엔드포인트 · DB 스키마 · 수집 기준',
        style: t.body(13, weight: FontWeight.w600),
      ),
      children: [
        FutureBuilder<Map<String, dynamic>>(
          future: _catalog,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                '참조 정보를 불러오지 못했습니다. 화면을 새로고침해 주세요.',
                style: t.body(12, color: c.textSecondary),
              );
            }
            if (!snapshot.hasData) return const LinearProgressIndicator();
            final group =
                snapshot.data![widget.dataset] as Map<String, dynamic>;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.collectionDetail,
                  style: t.body(12, color: c.textSecondary),
                ),
                const SizedBox(height: AppSpace.md),
                Text(
                  '원천 API · GET',
                  style: t.body(13, weight: FontWeight.w600),
                ),
                Text(
                  '주소와 파라미터 이름을 선택해 복사할 수 있습니다. 인증키 값은 표시하지 않습니다.',
                  style: t.body(12, color: c.textSecondary),
                ),
                for (final raw in group['endpoints'] as List) ...[
                  const SizedBox(height: AppSpace.md),
                  Text(raw['label'] as String, style: t.body(13)),
                  SelectableText(raw['url'] as String, style: t.body(12)),
                  SelectableText(
                    '요청 파라미터: ${raw['params']}',
                    style: t.body(12, color: c.textSecondary),
                  ),
                ],
                const SizedBox(height: AppSpace.lg),
                Text('앱의 저장 스키마', style: t.body(13, weight: FontWeight.w600)),
                Text(
                  '원천 응답 JSON과 구분되는 Serverpod 모델 정의입니다. '
                  '필드·타입·관계·인덱스와 설명을 원본 그대로 제공합니다. '
                  '?는 null 허용, relation은 연결 테이블, sourceId는 출처 연결입니다. '
                  '저장 테이블에는 Serverpod가 관리하는 id도 포함됩니다. '
                  '이 정보는 앱에 포함된 모델 정의 스냅샷입니다.',
                  style: t.body(12, color: c.textSecondary),
                ),
                for (final raw in group['schemas'] as List)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(raw['file'] as String, style: t.body(12)),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpace.md),
                        decoration: BoxDecoration(
                          border: Border.all(color: c.border),
                        ),
                        child: SelectableText(
                          raw['definition'] as String,
                          style: t.body(12),
                        ),
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
