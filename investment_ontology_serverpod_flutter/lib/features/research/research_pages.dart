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
String researchError(Object e) =>
    e is IngestException ? e.message : '연결을 확인하고 다시 시도해주세요.';

class ResearchListPage extends StatefulWidget {
  const ResearchListPage({
    super.key,
    this.manage = false,
    this.ticker,
    this.query = '',
  });
  final bool manage;
  final String? ticker;
  final String query;
  @override
  State<ResearchListPage> createState() => _ResearchListPageState();
}

class _ResearchListPageState extends State<ResearchListPage> {
  late final TextEditingController _query = TextEditingController(
    text: widget.query,
  );
  List<ResearchEntry> _items = [];
  String _market = '', _error = '';
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
    if (widget.query != oldWidget.query || widget.ticker != oldWidget.ticker) {
      _query.text = widget.query;
      _market = '';
      _load();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _load({bool append = false}) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final rows = await client.research.list(
        query: _query.text,
        market: _market,
        manage: widget.manage,
        savedOnly: _saved,
        ticker: widget.ticker,
        offset: append ? _items.length : 0,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _items = append ? [..._items, ...rows] : rows;
        _more = rows.length == 30;
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
      final n = await client.research.importLegacy();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$n개 리포트를 이관했습니다.')));
      await _load();
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
                    _load();
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
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: '기업명, 종목코드, 본문에서 검색',
          ),
          onChanged: (_) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 300), _load);
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
                selected: _market == m,
                onSelected: (_) {
                  _market = m;
                  _load();
                },
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
              TextButton(onPressed: _load, child: const Text('다시 시도')),
            ],
          ),
        if (!_loading && _items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 64),
            child: Text(
              _saved
                  ? '저장한 리포트가 없습니다. 읽고 싶은 글에서 저장을 눌러보세요.'
                  : '조건에 맞는 리포트가 없습니다.',
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
                          if (mounted) _load();
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
        if (_more && !_loading)
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
  const ResearchReaderPage({super.key, required this.slug, this.draft = false});
  final String slug;
  final bool draft;
  @override
  State<ResearchReaderPage> createState() => _ResearchReaderPageState();
}

class _ResearchReaderPageState extends State<ResearchReaderPage> {
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
      _loading = true;
      _load();
    }
  }

  int _request = 0;
  Future<void> _load() async {
    final request = ++_request;
    _error = "";
    try {
      final entry = await client.research.get(
        widget.slug,
        draft: widget.draft,
        source: false,
        version: _version,
      );
      final editions = widget.draft
          ? <ResearchRevision>[]
          : await client.research.editions(widget.slug);
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
    setState(() => _saving = true);
    try {
      final saved = await client.research.bookmark(widget.slug, !_entry!.saved);
      if (mounted) setState(() => _entry!.saved = saved);
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
          PageHeading(title: _error.isEmpty ? '공개된 리포트가 없습니다.' : _error),
          TextButton(
            onPressed: () => context.go('/research'),
            child: const Text('리포트 둘러보기'),
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
                onPressed: () => context.go('/research'),
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
                    _load();
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
