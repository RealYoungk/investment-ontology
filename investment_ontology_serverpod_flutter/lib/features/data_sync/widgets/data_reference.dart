import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/tokens.dart';
import 'schedule_board.dart';

/// Reference snapshot refreshed by scripts/data/build_catalog.py.
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
  int _panel = 0;
  int _endpoint = 0;
  int _schema = 0;

  @override
  Widget build(BuildContext context) {
    final t = context.typo;
    final c = context.colors;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text('API · DB 스키마', style: t.body(13, weight: FontWeight.w600)),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.lg),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _catalog,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('참조 정보를 불러오지 못했습니다. 새로고침해 주세요.', style: t.body(12));
              }
              if (!snapshot.hasData) return const LinearProgressIndicator();
              final group =
                  snapshot.data![widget.dataset] as Map<String, dynamic>;
              final endpoints = group['endpoints'] as List;
              final schemas = group['schemas'] as List;
              final api = endpoints[_endpoint] as Map;
              final schema = schemas[_schema] as Map;
              final fields = schema['fields'] as List? ?? [];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: AppSpace.sm,
                    runSpacing: AppSpace.sm,
                    children: [
                      for (final (i, label) in [
                        (0, '원천 API'),
                        (1, 'DB 구조'),
                        (2, '수집 방식'),
                      ])
                        ChoiceChip(
                          label: Text(label),
                          selected: _panel == i,
                          onSelected: (_) => setState(() => _panel = i),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.lg),
                  if (_panel == 0) ...[
                    DropdownButtonFormField<int>(
                      initialValue: _endpoint,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: '수집 API · ${endpoints.length}개',
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (var i = 0; i < endpoints.length; i++)
                          DropdownMenuItem(
                            value: i,
                            child: Text(
                              endpoints[i]['label'] as String,
                              style: t.body(13),
                            ),
                          ),
                      ],
                      onChanged: (i) {
                        if (i != null) setState(() => _endpoint = i);
                      },
                    ),
                    const SizedBox(height: AppSpace.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpace.md),
                      decoration: BoxDecoration(
                        color: c.accent.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GET',
                            style: t.body(
                              12,
                              weight: FontWeight.w600,
                              color: c.accent,
                            ),
                          ),
                          const SizedBox(height: AppSpace.xs),
                          SelectableText(
                            api['url'] as String,
                            style: t.body(13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                    Text('요청 파라미터', style: t.body(13, weight: FontWeight.w600)),
                    const SizedBox(height: AppSpace.sm),
                    Wrap(
                      spacing: AppSpace.sm,
                      runSpacing: AppSpace.sm,
                      children: [
                        for (final param in (api['params'] as String).split(
                          ', ',
                        ))
                          Chip(label: SelectableText(param, style: t.body(12))),
                      ],
                    ),
                    Text(
                      '주소·파라미터는 복사 가능 · 인증키 값은 표시하지 않음',
                      style: t.body(11, color: c.textMuted),
                    ),
                  ] else if (_panel == 1) ...[
                    DropdownButtonFormField<int>(
                      initialValue: _schema,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: '저장 모델',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (var i = 0; i < schemas.length; i++)
                          DropdownMenuItem(
                            value: i,
                            child: Text(
                              (schemas[i]['file'] as String).replaceAll(
                                '.spy.yaml',
                                '',
                              ),
                              style: t.body(13),
                            ),
                          ),
                      ],
                      onChanged: (i) {
                        if (i != null) setState(() => _schema = i);
                      },
                    ),
                    const SizedBox(height: AppSpace.md),
                    Text(
                      '저장 모델 정의 · ? = null 허용 · relation = 테이블 연결',
                      style: t.body(11, color: c.textMuted),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    if (fields.isNotEmpty)
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(3),
                        },
                        border: TableBorder(
                          horizontalInside: BorderSide(color: c.border),
                        ),
                        children: [
                          TableRow(
                            children: [
                              for (final title in ['필드', '타입 · 설명'])
                                Padding(
                                  padding: const EdgeInsets.all(AppSpace.sm),
                                  child: Text(
                                    title,
                                    style: t.body(12, weight: FontWeight.w600),
                                  ),
                                ),
                            ],
                          ),
                          for (final field in fields)
                            TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(AppSpace.sm),
                                  child: SelectableText(
                                    field['name'] as String,
                                    style: t.body(12),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(AppSpace.sm),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SelectableText(
                                        field['type'] as String,
                                        style: t.body(12),
                                      ),
                                      if ((field['description'] as String)
                                          .isNotEmpty)
                                        Text(
                                          field['description'] as String,
                                          style: t.body(
                                            11,
                                            color: c.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text('원본 정의 · 인덱스 보기', style: t.body(12)),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SelectableText(
                            schema['definition'] as String,
                            style: t.body(12),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '모델 파일에서 생성한 스냅샷 · 원천 API 응답과 별개 · 테이블 id는 Serverpod가 관리',
                      style: t.body(11, color: c.textMuted),
                    ),
                  ] else ...[
                    DatasetRunHistory(dataset: widget.dataset),
                    for (final paragraph in widget.collectionDetail.split(
                      '\n\n',
                    ))
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.md),
                        child: Text(
                          paragraph,
                          style: t.body(13, color: c.textSecondary),
                        ),
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
