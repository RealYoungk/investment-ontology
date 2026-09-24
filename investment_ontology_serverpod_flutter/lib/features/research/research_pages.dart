import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/components/research/report_document.dart';
import '../../design/tokens.dart';
import '../auth/app_viewer.dart';

String researchDate(DateTime d) =>
    '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
String researchError(Object e) => switch (e) {
  IngestException(:final message) => message,
  ServerpodClientUnauthorized() => '로그인한 뒤 다시 시도해주세요.',
  ServerpodClientForbidden() => '이 화면을 볼 권한이 없습니다.',
  // Serverpod rejects bodies over maxRequestSize before the endpoint runs.
  ServerpodClientHttpException(statusCode: 413) =>
    '본문이 너무 큽니다. 그림은 파일로 올리고 본문을 줄여주세요.',
  _ => '연결을 확인하고 다시 시도해주세요.',
};

/// Rows per `research.list` call; the server returns at most this many.
const researchPageSize = 30;

class ResearchListPage extends StatefulWidget {
  const ResearchListPage({
    super.key,
    this.manage = false,
    this.ticker,
    this.query = '',
    this.market = '',
    this.research,
  });
  final bool manage;
  final String? ticker;

  /// Search words and market live in the address, so reload and back keep them.
  final String query, market;

  /// Defaults to the app client; tests pass a fake.
  final EndpointResearch? research;
  @override
  State<ResearchListPage> createState() => _ResearchListPageState();
}

class _ResearchListPageState extends State<ResearchListPage> {
  late final TextEditingController _query = TextEditingController(
    text: widget.query,
  );
  late final _research = widget.research ?? client.research;
  final _queryFocus = FocusNode();
  List<ResearchEntry> _items = [];
  String _error = '';
  bool _saved = false, _loading = true, _more = true;
  int _request = 0;
  Timer? _debounce;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ResearchListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != oldWidget.query ||
        widget.market != oldWidget.market ||
        widget.ticker != oldWidget.ticker) {
      // Back/forward changed the address: follow it, unless the person is
      // typing (rewriting the field would break Hangul composition).
      if (!_queryFocus.hasFocus && _query.text.trim() != widget.query) {
        _query.text = widget.query;
      }
      _load();
    }
  }

  /// Puts the filters in the address without adding a history entry.
  void _apply({String? query, String? market}) {
    final params = {
      'ticker': widget.ticker ?? '',
      'q': query ?? widget.query,
      'market': market ?? widget.market,
    }..removeWhere((_, v) => v.isEmpty);
    final next = Uri(
      path: widget.manage ? '/admin/research' : '/research',
      queryParameters: params.isEmpty ? null : params,
    ).toString();
    Router.neglect(context, () => context.go(next));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _queryFocus.dispose();
    super.dispose();
  }

  /// [append] adds the next page. [keep] reloads as many rows as are shown,
  /// so coming back from an article keeps the list and its scroll position.
  Future<void> _load({bool append = false, bool keep = false}) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final want = keep ? _items.length : 1;
      final rows = <ResearchEntry>[];
      List<ResearchEntry> page;
      do {
        page = await _research.list(
          query: widget.query,
          market: widget.market,
          manage: widget.manage,
          savedOnly: _saved,
          ticker: widget.ticker,
          offset: (append ? _items.length : 0) + rows.length,
        );
        if (!mounted || request != _request) return;
        rows.addAll(page);
      } while (page.length == researchPageSize && rows.length < want);
      setState(() {
        _items = append ? [..._items, ...rows] : rows;
        _more = page.length == researchPageSize;
        _loading = false;
      });
    } catch (e) {
      if (mounted && request == _request) {
        setState(() {
          _error = researchError(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _import() async {
    setState(() => _loading = true);
    try {
      final n = await _research.importLegacy();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$n개 리포트를 이관했습니다.')));
      await _load(keep: true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = researchError(e);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.typo;
    return PageFrame(
      children: [
        PageHeading(
          title: widget.manage ? '리포트 관리' : '리포트',
          subtitle: widget.manage
              ? '초안을 다듬고, 독자에게 보여줄 버전을 발행하세요.'
              : '기업의 숫자 뒤에 있는 이야기를 읽어보세요.',
        ),
        const SizedBox(height: AppSpace.xl),
        if (widget.manage)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.lg),
            child: Wrap(
              spacing: AppSpace.md,
              runSpacing: AppSpace.sm,
              children: [
                AppButton(
                  label: '새 리포트',
                  onPressed: () async {
                    await context.push('/admin/research/new');
                    if (mounted) _load(keep: true);
                  },
                ),
                AppButton(
                  label: '기존 리포트 가져오기',
                  onPressed: _loading ? null : _import,
                ),
              ],
            ),
          ),
        TextField(
          controller: _query,
          focusNode: _queryFocus,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: '기업명, 종목코드, 본문에서 검색',
          ),
          onChanged: (value) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 300), () {
              if (mounted && value.trim() != widget.query) {
                _apply(query: value.trim());
              }
            });
          },
        ),
        const SizedBox(height: AppSpace.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in ['', 'KOSPI', 'KOSDAQ', 'KONEX'])
              ChoiceChip(
                label: Text(m.isEmpty ? '전체' : m),
                selected: widget.market == m,
                onSelected: (_) => _apply(market: m),
              ),
            FilterChip(
              label: const Text('저장한 리포트'),
              selected: _saved,
              onSelected: (v) {
                if (AppViewerScope.maybeOf(context) == null) {
                  context.push('/login?next=/research');
                  return;
                }
                _saved = v;
                _load();
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpace.xl),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        if (_error.isNotEmpty)
          Column(
            children: [
              AppNotice(message: _error),
              TextButton(
                onPressed: () => _load(keep: true),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        if (!_loading && _error.isEmpty && _items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 64),
            child: Text(
              _saved
                  ? '저장한 리포트가 없습니다. 읽고 싶은 글에서 저장을 눌러보세요.'
                  : widget.query.isEmpty && widget.market.isEmpty
                  ? widget.manage
                        ? '아직 리포트가 없습니다. 새 리포트를 작성하세요.'
                        : '아직 공개된 리포트가 없습니다.'
                  : '조건에 맞는 리포트가 없습니다. 다른 단어나 시장으로 찾아보세요.',
              style: t.body(16, color: c.textSecondary),
            ),
          ),
        LayoutBuilder(
          builder: (context, box) {
            final columns = box.maxWidth >= 1050
                ? 3
                : box.maxWidth >= 620
                ? 2
                : 1;
            final width = (box.maxWidth - 20 * (columns - 1)) / columns;
            return Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                for (final entry in _items)
                  SizedBox(
                    width: width,
                    child: Material(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          await context.push(
                            widget.manage
                                ? '/admin/research/${entry.article.slug}'
                                : '/research/${entry.article.slug}',
                          );
                          if (mounted) _load(keep: true);
                        },
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 220),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            border: Border.all(color: c.border),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${entry.revision.market} · ${entry.revision.ticker}',
                                    style: t.body(12, color: c.textMuted),
                                  ),
                                  const Spacer(),
                                  if (entry.saved)
                                    Icon(
                                      Icons.bookmark,
                                      size: 17,
                                      color: c.accent,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Text(entry.revision.title, style: t.display(22)),
                              const SizedBox(height: 12),
                              Text(
                                entry.revision.summary,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: t.body(15, color: c.textSecondary),
                              ),
                              const SizedBox(height: 22),
                              Text(
                                '${researchDate(entry.revision.dataAsOf)}${widget.manage
                                    ? ' · ${entry.article.publishedVersion == null ? '비공개' : '공개 v${entry.article.publishedVersion}'} · 초안 v${entry.article.latestVersion}'
                                    : entry.revision.legacy
                                    ? ' · 아카이브'
                                    : ''}',
                                style: t.body(12, color: c.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        if (_more && !_loading && _error.isEmpty && _items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Center(
              child: TextButton(
                onPressed: () => _load(append: true),
                child: const Text('리포트 더 보기'),
              ),
            ),
          ),
      ],
    );
  }
}

class ResearchReaderPage extends StatefulWidget {
  const ResearchReaderPage({
    super.key,
    required this.slug,
    this.draft = false,
    this.research,
  });
  final String slug;
  final bool draft;

  /// Defaults to the app client; tests pass a fake.
  final EndpointResearch? research;
  @override
  State<ResearchReaderPage> createState() => _ResearchReaderPageState();
}

class _ResearchReaderPageState extends State<ResearchReaderPage> {
  late final _research = widget.research ?? client.research;
  ResearchEntry? _entry;
  List<ResearchRevision> _editions = [];
  int? _version;
  String _error = '';
  bool _loading = true, _saving = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ResearchReaderPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slug != widget.slug || oldWidget.draft != widget.draft) {
      _version = null;
      _entry = null;
      _editions = [];
      _loading = true;
      _load();
    }
  }

  int _request = 0;
  Future<void> _load() async {
    final request = ++_request;
    _error = '';
    try {
      final entry = await _research.get(
        widget.slug,
        draft: widget.draft,
        source: false,
        version: _version,
      );
      // The edition menu is optional; failing to list it must not hide the
      // article that did load.
      var editions = <ResearchRevision>[];
      if (!widget.draft && entry != null) {
        try {
          editions = await _research.editions(widget.slug);
        } catch (_) {}
      }
      if (mounted && request == _request) {
        setState(() {
          _entry = entry;
          _editions = editions;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted && request == _request) {
        setState(() {
          _error = researchError(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _bookmark() async {
    if (AppViewerScope.maybeOf(context) == null) {
      context.push('/login?next=/research/${widget.slug}');
      return;
    }
    final entry = _entry!;
    setState(() => _saving = true);
    try {
      final saved = await _research.bookmark(widget.slug, !entry.saved);
      // Another article may have opened meanwhile; mark only the one saved.
      if (mounted) setState(() => entry.saved = saved);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(researchError(e))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final e = _entry;
    if (e == null || _error.isNotEmpty) {
      return PageFrame(
        children: [
          PageHeading(
            title: _error.isNotEmpty
                ? _error
                : widget.draft
                ? '초안을 찾을 수 없습니다.'
                : '공개된 리포트가 없습니다.',
            subtitle: _error.isNotEmpty
                ? null
                : '주소를 확인하거나, 공개가 해제된 글인지 확인해주세요.',
          ),
          Wrap(
            spacing: AppSpace.sm,
            children: [
              if (_error.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() => _loading = true);
                    _load();
                  },
                  child: const Text('다시 시도'),
                ),
              TextButton(
                onPressed: () => context.go('/research'),
                child: const Text('리포트 둘러보기'),
              ),
            ],
          ),
        ],
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(
                // Back to the list that opened this, with its filters and
                // scroll; a shared link has no list underneath.
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/research'),
                child: const Text('리포트 목록'),
              ),
              if (widget.draft) const Text('관리자 초안 미리보기'),
              if (_editions.length > 1)
                DropdownButton<int>(
                  value: e.revision.version,
                  items: [
                    for (final r in _editions)
                      DropdownMenuItem(
                        value: r.version,
                        child: Text(
                          'v${r.version} · ${researchDate(r.dataAsOf)}',
                        ),
                      ),
                  ],
                  onChanged: (v) {
                    _version = v;
                    setState(() => _loading = true);
                    _load();
                  },
                ),
              if (e.corpCode != null)
                TextButton.icon(
                  onPressed: () => context.push('/company/${e.corpCode}'),
                  icon: const Icon(Icons.query_stats, size: 18),
                  label: const Text('기업 데이터'),
                ),
              if (!widget.draft)
                TextButton.icon(
                  onPressed: _saving ? null : _bookmark,
                  icon: Icon(
                    e.saved ? Icons.bookmark : Icons.bookmark_border,
                    size: 18,
                  ),
                  label: Text(e.saved ? '저장됨' : '저장'),
                ),
              if (!widget.draft)
                IconButton(
                  tooltip: '링크 공유',
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text: 'https://alfinder.kr/research/${widget.slug}',
                      ),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('리포트 링크를 복사했습니다.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.link, size: 18),
                ),
              if (context.isAdmin)
                TextButton(
                  onPressed: () async {
                    await context.push('/admin/research/${widget.slug}');
                    if (mounted) _load();
                  },
                  child: const Text('수정'),
                ),
            ],
          ),
        ),
        Expanded(
          child: ReportDocument(
            title: e.revision.title,
            summary: e.revision.summary,
            date: researchDate(e.revision.dataAsOf),
            content: e.revision.content,
            legacy: e.revision.legacy,
          ),
        ),
      ],
    );
  }
}
