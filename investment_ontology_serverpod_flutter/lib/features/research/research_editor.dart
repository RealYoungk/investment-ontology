import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import 'research_pages.dart';

class ResearchEditorPage extends StatefulWidget {
  const ResearchEditorPage({super.key, required this.slug});
  final String slug;
  static bool hasUnsavedChanges = false;
  static Future<bool> confirmExit(BuildContext context) async {
    if (!hasUnsavedChanges) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('저장하지 않은 변경이 있습니다.'),
        content: const Text('변경을 버리고 이동할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('계속 편집'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('변경 버리기'),
          ),
        ],
      ),
    );
    if (leave == true) hasUnsavedChanges = false;
    return leave ?? false;
  }

  @override
  State<ResearchEditorPage> createState() => _ResearchEditorPageState();
}

class _ResearchEditorPageState extends State<ResearchEditorPage> {
  final _slug = TextEditingController(),
      _title = TextEditingController(),
      _summary = TextEditingController(),
      _ticker = TextEditingController(),
      _date = TextEditingController(),
      _body = TextEditingController(),
      _note = TextEditingController();
  String _market = 'KOSPI', _format = 'markdown', _error = '';
  bool _busy = false, _dirty = false, _loaded = false;
  ResearchEntry? _entry;
  List<ResearchRevision> _history = [];
  List<TextEditingController> get _fields => [
    _slug,
    _title,
    _summary,
    _ticker,
    _date,
    _body,
    _note,
  ];
  @override
  void initState() {
    super.initState();
    _date.text = DateTime.now().toIso8601String().split('T').first;
    for (final c in _fields) {
      c.addListener(_changed);
    }
    if (widget.slug == 'new') {
      _loaded = true;
    } else {
      _load();
    }
  }

  void _changed() {
    if (_loaded && mounted) {
      setState(() {
        _dirty = true;
        ResearchEditorPage.hasUnsavedChanges = true;
      });
    }
  }

  @override
  void dispose() {
    for (final c in _fields) {
      c.dispose();
    }
    ResearchEditorPage.hasUnsavedChanges = false;
    super.dispose();
  }

  void _fill(ResearchEntry e) {
    _loaded = false;
    _entry = e;
    _slug.text = e.article.slug;
    _title.text = e.revision.title;
    _summary.text = e.revision.summary;
    _ticker.text = e.revision.ticker;
    _market = e.revision.market;
    _format = e.revision.format;
    _date.text = e.revision.dataAsOf.toIso8601String().split('T').first;
    _body.text = e.revision.content;
    _note.text = '';
    _dirty = false;
    ResearchEditorPage.hasUnsavedChanges = false;
    _loaded = true;
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final e = await client.research.get(
        widget.slug,
        draft: true,
        source: true,
      );
      if (!mounted) return;
      if (e == null) throw StateError('not found');
      final h = await client.research.history(widget.slug);
      if (mounted) {
        setState(() {
          _fill(e);
          _history = h;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = researchError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _save() async {
    final date = DateTime.tryParse(_date.text);
    if (date == null ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(_date.text) ||
        date.toIso8601String().split('T').first != _date.text) {
      setState(() => _error = '분석 기준일을 YYYY-MM-DD 형식으로 입력하세요.');
      return false;
    }
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      final e = await client.research.save(
        _slug.text.trim(),
        _title.text,
        _summary.text,
        _ticker.text.trim(),
        _market,
        _body.text,
        _format,
        DateTime.utc(date.year, date.month, date.day),
        _entry?.article.latestVersion ?? 0,
        _note.text,
      );
      final h = await client.research.history(e.article.slug);
      if (!mounted) return false;
      setState(() {
        _fill(e);
        _history = h;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('초안을 저장했습니다. 공개본은 그대로 유지됩니다.')),
      );
      return true;
    } catch (e) {
      if (mounted) setState(() => _error = researchError(e));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _publish({bool withdraw = false}) async {
    if (_entry == null || _dirty) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(withdraw ? '공개를 해제할까요?' : '이 버전을 발행할까요?'),
        content: Text(
          withdraw
              ? '목록과 공유 링크에서 숨겨집니다. 저장된 버전은 유지됩니다.'
              : '저장한 v${_entry!.article.latestVersion}이 모든 독자에게 공개됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(withdraw ? '공개 해제' : '발행'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    setState(() => _busy = true);
    try {
      await client.research.publish(
        _slug.text,
        _entry!.article.latestVersion,
        withdraw: withdraw,
      );
      final e = await client.research.get(
        _slug.text,
        draft: true,
        source: true,
      );
      if (mounted && e != null) {
        setState(() => _fill(e));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(withdraw ? '공개를 해제했습니다.' : '발행했습니다.')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = researchError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore(ResearchRevision revision) async {
    try {
      final e = await client.research.get(
        _slug.text,
        version: revision.version,
        draft: false,
        source: true,
      );
      if (!mounted || e == null) return;
      final latest = _entry;
      setState(() {
        _fill(e);
        _entry = latest;
        _note.text = 'v${revision.version} 내용으로 복원';
        _dirty = true;
      });
    } catch (e) {
      if (mounted) setState(() => _error = researchError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.typo;
    Widget field(
      String label,
      TextEditingController controller, {
      int lines = 1,
      bool enabled = true,
      String? hint,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        key: ValueKey(label),
        controller: controller,
        enabled: enabled && !_busy,
        minLines: lines,
        maxLines: lines == 1 ? 1 : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          alignLabelWithHint: true,
        ),
      ),
    );
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || !_dirty) return;
        final discard = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('저장하지 않은 변경이 있습니다.'),
            content: const Text('변경을 버리고 나갈까요?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('계속 편집'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('변경 버리기'),
              ),
            ],
          ),
        );
        if (discard == true && mounted) {
          setState(() {
            _dirty = false;
            ResearchEditorPage.hasUnsavedChanges = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.pop();
          });
        }
      },
      child: PageFrame(
        maxWidth: 1000,
        children: [
          PageHeading(
            title: _entry == null ? '새 리포트' : '${_entry!.revision.title} 편집',
            subtitle: _entry == null
                ? '핵심 관점과 근거를 함께 담아주세요.'
                : '초안 v${_entry!.article.latestVersion} · ${_entry!.article.publishedVersion == null ? '비공개' : '공개 v${_entry!.article.publishedVersion}'}',
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton(
                label: _busy ? '처리 중…' : '초안 저장',
                onPressed: _busy ? null : _save,
              ),
              AppButton(
                label: '미리보기',
                onPressed: _busy
                    ? null
                    : () async {
                        if (_dirty || _entry == null) {
                          if (!await _save()) return;
                        }
                        if (context.mounted) {
                          context.push('/research/${_slug.text}?draft=true');
                        }
                      },
              ),
              AppButton(
                label: '발행',
                onPressed: _busy || _dirty || _entry == null ? null : _publish,
              ),
              if (_entry?.article.publishedVersion != null)
                TextButton(
                  onPressed: _busy || _dirty
                      ? null
                      : () => _publish(withdraw: true),
                  child: const Text('공개 해제'),
                ),
              if (_entry?.article.publishedVersion != null)
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => context.push('/research/${_slug.text}'),
                  child: const Text('공개본 보기'),
                ),
            ],
          ),
          if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: AppNotice(message: _error),
            ),
          const SizedBox(height: 24),
          field(
            '리포트 주소',
            _slug,
            enabled: _entry == null,
            hint: '예: simmtech-2026-q2',
          ),
          field('제목', _title),
          field('핵심 관점', _summary, lines: 2),
          field('종목코드', _ticker),
          DropdownButtonFormField<String>(
            initialValue: _market,
            decoration: const InputDecoration(labelText: '시장'),
            items: [
              for (final m in ['KOSPI', 'KOSDAQ', 'KONEX'])
                DropdownMenuItem(value: m, child: Text(m)),
            ],
            onChanged: _busy
                ? null
                : (v) => setState(() {
                    _market = v!;
                    _dirty = true;
                  }),
          ),
          const SizedBox(height: 20),
          field('분석 기준일', _date, hint: 'YYYY-MM-DD'),
          Text(
            _format == 'html'
                ? '기존 도표와 출처가 포함된 원문입니다. 수정 후 미리보기에서 확인하세요.'
                : '제목은 ##, 강조는 **문구**, 출처는 [이름](https://주소)로 작성할 수 있습니다.',
            style: t.body(13),
          ),
          const SizedBox(height: 12),
          field(_format == 'html' ? '원문 HTML' : '본문', _body, lines: 14),
          field('이번 수정 내용', _note, lines: 2),
          if (_history.isNotEmpty) ...[
            Text('버전 기록', style: t.display(20)),
            const SizedBox(height: 12),
            for (final r in _history)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'v${r.version} · ${researchDate(r.createdAt.toLocal())}',
                ),
                subtitle: Text(r.note.isEmpty ? '초안 저장' : r.note),
                trailing: TextButton(
                  onPressed: _busy ? null : () => _restore(r),
                  child: const Text('이 내용으로 복원'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
