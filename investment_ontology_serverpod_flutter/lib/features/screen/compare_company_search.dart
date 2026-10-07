import '../../design/components/company_logo.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';

/// Comparison-specific selection and query state; basic controls belong to shad.
class CompareCompanySearch extends StatefulWidget {
  const CompareCompanySearch({
    super.key,
    required this.selectedCodes,
    required this.onAdd,
    required this.onRemove,
    this.search,
  });
  final List<String> selectedCodes;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final Future<List<CompanyListItem>> Function(String)? search;
  @override
  State<CompareCompanySearch> createState() => _CompareCompanySearchState();
}

class _CompareCompanySearchState extends State<CompareCompanySearch> {
  final _controller = TextEditingController();
  Timer? _debounce;
  int _request = 0;
  bool _searching = false;
  bool _failed = false;
  List<CompanyListItem> _results = const [];
  bool get _full => widget.selectedCodes.length >= 4;

  @override
  void dispose() {
    _debounce?.cancel();
    ++_request;
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _debounce?.cancel();
    ++_request;
    _controller.clear();
    setState(() {
      _results = const [];
      _failed = false;
      _searching = false;
    });
  }

  void _search(String text) {
    _debounce?.cancel();
    final request = ++_request;
    final query = text.trim();
    setState(() {
      _results = const [];
      _failed = false;
      _searching = query.isNotEmpty;
    });
    if (!_searching) return;
    _debounce = Timer(
      const Duration(milliseconds: 250),
      () => _fetch(query, request),
    );
  }

  Future<void> _fetch(String query, int request) async {
    try {
      final items = widget.search != null
          ? await widget.search!(query)
          : (await client.company.list(
              query: query,
              sort: CompanySort.marketCap,
              limit: 6,
            )).items;
      if (mounted && request == _request) setState(() => _results = items);
    } catch (_) {
      if (mounted && request == _request) setState(() => _failed = true);
    } finally {
      if (mounted && request == _request) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: double.infinity),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('비교 기업 추가', style: t.body(14, weight: FontWeight.w600)),
                const Spacer(),
                Text(
                  '${widget.selectedCodes.length}/4',
                  style: t.numeric(12, color: c.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            SizedBox(
              height: 48,
              child: ShadInput(
                controller: _controller,
                enabled: true,
                placeholder: const Text('회사명 · 종목코드'),
                leading: Icon(
                  LucideIcons.search,
                  size: 18,
                  color: c.textSecondary,
                ),
                onChanged: _search,
                trailing: _controller.text.isEmpty
                    ? const SizedBox(width: 28, height: 28)
                    : Semantics(
                        container: true,
                        label: '검색어 지우기',
                        button: true,
                        onTap: _clear,
                        child: ExcludeSemantics(
                          child: ShadIconButton.ghost(
                            width: 28,
                            height: 28,
                            padding: EdgeInsets.zero,
                            onPressed: _clear,
                            icon: const Icon(LucideIcons.x, size: 14),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            if (_full)
              Text(
                '최대 4개까지 비교할 수 있습니다. 체크를 해제하면 다른 기업을 선택할 수 있습니다.',
                style: t.body(12, color: c.textSecondary),
              ),
            if (_searching)
              Semantics(
                liveRegion: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ShadProgress(minHeight: 2),
                    const SizedBox(height: AppSpace.sm),
                    Text('검색 중…', style: t.body(13, color: c.textSecondary)),
                  ],
                ),
              )
            else if (_failed)
              ReadFailureNotice(
                subject: '기업 검색',
                retry: () async {
                  _debounce?.cancel();
                  final request = ++_request;
                  setState(() {
                    _failed = false;
                    _searching = true;
                  });
                  await _fetch(_controller.text.trim(), request);
                },
              )
            else if (_controller.text.trim().isNotEmpty && _results.isEmpty)
              Semantics(
                liveRegion: true,
                child: Text(
                  '검색 결과가 없습니다.',
                  style: t.body(13, color: c.textMuted),
                ),
              )
            else if (_controller.text.trim().isEmpty)
              Text(
                '회사명이나 종목코드로 검색해 추가하세요.',
                style: t.body(12, color: c.textSecondary),
              ),
            if (_results.isNotEmpty) ...[
              const SizedBox(height: AppSpace.sm),
              Text(
                '체크하면 비교에 추가되고, 해제하면 빠집니다.',
                style: t.body(12, color: c.textSecondary),
              ),
              const SizedBox(height: AppSpace.sm),
              _resultTable(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _resultTable(BuildContext context) {
    final t = context.typo;
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, box) {
        final narrow = box.maxWidth < 360;
        final headers = narrow ? ['선택', '기업'] : ['선택', '기업', '종목코드'];
        const checkWidth = 56.0;
        const codeWidth = 88.0;
        return SizedBox(
          height: 48 * (_results.length + 1).toDouble(),
          child: ShadTable(
            primary: false,
            columnCount: headers.length,
            rowCount: _results.length,
            verticalScrollPhysics: const NeverScrollableScrollPhysics(),
            columnSpanExtent: (column) => FixedTableSpanExtent(
              column == 0
                  ? checkWidth
                  : column == 2
                  ? codeWidth
                  : box.maxWidth - checkWidth - (narrow ? 0 : codeWidth),
            ),
            rowSpanExtent: (_) => const FixedTableSpanExtent(48),
            header: (context, column) => ShadTableCell.header(
              height: 48,
              child: Text(headers[column], style: t.label()),
            ),
            builder: (context, vicinity) {
              final item = _results[vicinity.row];
              final selected = widget.selectedCodes.contains(item.corpCode);
              final enabled = selected || !_full;
              return ShadTableCell(
                height: 48,
                child: vicinity.column == 0
                    ? Semantics(
                        label: '${item.name} 비교 선택',
                        child: ShadCheckbox(
                          value: selected,
                          enabled: enabled,
                          onChanged: enabled
                              ? (value) {
                                  value
                                      ? widget.onAdd(item.corpCode)
                                      : widget.onRemove(item.corpCode);
                                }
                              : null,
                        ),
                      )
                    : vicinity.column == 2
                    ? Text(
                        item.stockCode ?? '—',
                        style: t.numeric(12, color: c.textSecondary),
                      )
                    : ShadTooltip(
                        builder: (_) => Text(item.name),
                        child: Row(
                          children: [
                            CompanyLogo(
                              name: item.name,
                              stockCode: item.stockCode,
                              corpCode: item.corpCode,
                              size: 28,
                            ),
                            const SizedBox(width: AppSpace.sm),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: t.body(14),
                                  ),
                                  if (narrow)
                                    Text(
                                      item.stockCode ?? '종목코드 없음',
                                      style: t.numeric(
                                        12,
                                        color: c.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              );
            },
          ),
        );
      },
    );
  }
}
