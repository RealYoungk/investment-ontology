import '../../../app/router.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../client.dart';
import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../../auth/app_auth.dart';

typedef CompanyNewsLoader = Future<CompanyNewsFeed> Function(String corpCode);

class CompanyNewsSection extends StatefulWidget {
  const CompanyNewsSection({
    super.key,
    required this.corpCode,
    this.loader,
    this.compact = false,
  });
  final bool compact;
  final String corpCode;
  final CompanyNewsLoader? loader;
  @override
  State<CompanyNewsSection> createState() => _CompanyNewsSectionState();
}

class _CompanyNewsSectionState extends State<CompanyNewsSection> {
  CompanyNewsFeed? _feed;
  bool _loading = true, _failed = false;
  int _request = 0;
  bool _showAll = false;
  @override
  void initState() {
    super.initState();
    AppAuth.viewer.addListener(_load);
    _load();
  }

  @override
  void didUpdateWidget(covariant CompanyNewsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.corpCode != oldWidget.corpCode ||
        widget.loader != oldWidget.loader) {
      _load();
    }
  }

  @override
  void dispose() {
    _request++;
    AppAuth.viewer.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _failed = false;
      _feed = null;
      _showAll = false;
    });
    if (widget.loader == null && AppAuth.viewer.value == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final feed = await (widget.loader ?? client.companyNews.recent)(
        widget.corpCode,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _feed = feed;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  String _date(DateTime date) {
    final k = date.toUtc().add(const Duration(hours: 9));
    return '${k.year}.${k.month.toString().padLeft(2, '0')}.${k.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = context.typo;
    final feed = _feed;
    final items = feed == null
        ? <CompanyNewsItem>[]
        : widget.compact
        ? [
            ...feed.items.where((item) => item.publisher != 'DART').take(2),
            ...feed.items.where((item) => item.publisher == 'DART').take(1),
          ]
        : _showAll
        ? feed.items
        : [
            ...feed.items.where((item) => item.publisher != 'DART').take(4),
            ...feed.items.where((item) => item.publisher == 'DART').take(3),
          ];
    final notices = <String>[
      if (feed?.newsStatus == 'notConfigured') '뉴스 연결 준비 중',
      if (feed?.newsStatus == 'failed') '뉴스를 불러오지 못했습니다',
      if (feed?.filingStatus == 'notConfigured') '공시 연결 준비 중',
      if (feed?.filingStatus == 'failed') '공시를 불러오지 못했습니다',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CompanySectionHeading('관련 소식'),
        const SizedBox(height: AppSpace.md),
        Material(
          color: c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: context.shape.borderRadius,
            side: BorderSide(color: c.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_loading) ...[
                  Text('최근 소식을 불러오는 중…', style: t.body(13, color: c.textMuted)),
                  const SizedBox(height: AppSpace.sm),
                  const ShadProgress(),
                ] else if (widget.loader == null &&
                    AppAuth.viewer.value == null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ShadButton.ghost(
                      onPressed: () => context.go(
                        AppRoutes.login(
                          next: AppRoutes.company(widget.corpCode),
                        ),
                      ),
                      child: Flexible(child: const Text('로그인하고 최근 소식 보기')),
                    ),
                  )
                else if (_failed)
                  Row(
                    children: [
                      Expanded(
                        child: Text('소식을 불러오지 못했습니다.', style: t.body(13)),
                      ),
                      ShadButton.ghost(
                        onPressed: _load,
                        child: Flexible(child: const Text('다시 시도')),
                      ),
                    ],
                  )
                else if (feed != null) ...[
                  if (notices.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.sm),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            notices.join(' · '),
                            style: t.body(12, color: c.textMuted),
                          ),
                          if (feed.newsStatus == 'failed' ||
                              feed.filingStatus == 'failed')
                            ShadButton.ghost(
                              onPressed: _load,
                              child: Flexible(child: const Text('다시 시도')),
                            ),
                        ],
                      ),
                    ),
                  if (feed.items.isEmpty && notices.isEmpty)
                    Text(
                      '검색된 뉴스와 최근 공시가 없습니다.',
                      style: t.body(13, color: c.textMuted),
                    ),
                  for (final (i, item) in items.indexed) ...[
                    if (i == 0 ||
                        (item.publisher == 'DART' &&
                            items[i - 1].publisher != 'DART'))
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpace.sm,
                        ),
                        child: Text(
                          item.publisher == 'DART' ? '최근 공시' : '뉴스',
                          style: t.body(14, weight: FontWeight.w700),
                        ),
                      ),
                    if (i > 0 &&
                        item.publisher == 'DART' &&
                        items[i - 1].publisher != 'DART')
                      Divider(color: c.border, height: AppSpace.lg)
                    else if (i > 0)
                      const SizedBox(height: AppSpace.sm),
                    if (widget.compact || item.excerpt.isEmpty)
                      HoverBuilder(
                        onTap: () => launchUrl(
                          Uri.parse(item.url),
                          mode: LaunchMode.externalApplication,
                        ),
                        builder: (context, hovered) => Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpace.sm,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: t.body(
                                          14,
                                          weight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${_date(item.publishedAt)} · ${item.publisher}',
                                        style: t.body(12, color: c.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpace.sm),
                                const Icon(Icons.north_east, size: 16),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ShadAccordion<int>(
                        key: ValueKey('${widget.corpCode}:$i:${item.url}'),
                        maintainState: false,
                        children: [
                          ShadAccordionItem<int>(
                            value: 0,
                            separator: const SizedBox.shrink(),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: t
                                      .body(15, weight: FontWeight.w600)
                                      .copyWith(height: 1.45),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Row(
                                    children: [
                                      Text(
                                        _date(item.publishedAt),
                                        style: t.body(12, color: c.textMuted),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: ShadButton.ghost(
                                          onPressed: () => launchUrl(
                                            Uri.parse(item.url),
                                            mode:
                                                LaunchMode.externalApplication,
                                          ),
                                          child: Flexible(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                              child: Text(
                                                '${item.publisher} ↗',
                                                style: t.body(
                                                  12,
                                                  color: c.textMuted,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpace.sm,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    item.excerpt,
                                    style: t
                                        .body(13, color: c.textSecondary)
                                        .copyWith(height: 1.6),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                  if (!widget.compact &&
                      (_showAll || items.length < feed.items.length))
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ShadButton.ghost(
                        onPressed: () => setState(() => _showAll = !_showAll),
                        child: Flexible(
                          child: Text(_showAll ? '간략히 보기' : '소식 더 보기'),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
