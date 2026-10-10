import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../auth/app_auth.dart';
import 'investment_notes_api.dart';

typedef NotesLoad = Future<List<Map<String, dynamic>>> Function(
  String? corpCode,
  int offset,
);

class InvestmentNotesPage extends StatefulWidget {
  const InvestmentNotesPage({super.key, this.corpCode, this.load});
  final String? corpCode;
  final NotesLoad? load;
  @override
  State<InvestmentNotesPage> createState() => _InvestmentNotesPageState();
}

class _InvestmentNotesPageState extends State<InvestmentNotesPage> {
  List<Map<String, dynamic>> _notes = [];
  bool _loading = true, _failed = false, _more = false;
  int _epoch = 0;
  @override
  void initState() {
    super.initState();
    AppAuth.viewer.addListener(_reset);
    _load();
  }

  @override
  void didUpdateWidget(covariant InvestmentNotesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.corpCode != widget.corpCode) _reset();
  }

  @override
  void dispose() {
    AppAuth.viewer.removeListener(_reset);
    _epoch++;
    super.dispose();
  }

  void _reset() {
    _notes = [];
    _load();
  }

  Future<void> _load({bool append = false}) async {
    final request = ++_epoch;
    final offset = append ? _notes.length : 0;
    setState(() {
      _loading = true;
      _failed = false;
      if (!append) _notes = [];
    });
    try {
      final rows =
          await (widget.load?.call(widget.corpCode, offset) ??
              InvestmentNotesApi.list(
                corpCode: widget.corpCode,
                offset: offset,
              ));
      if (!mounted || request != _epoch) return;
      setState(() {
        _notes = [..._notes, ...rows];
        _more = rows.length == 30;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || request != _epoch) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.typo;
    return PageFrame(
      maxWidth: 960,
      children: [
        Text('투자 관점', style: t.display(28)),
        const SizedBox(height: AppSpace.md),
        Text(
          '관심종목을 발견하고, 투자 근거와 이후의 변화를 읽어보세요.',
          style: t.body(15, color: context.colors.textSecondary),
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          '관심종목 소개는 무료로, 탑픽과 상세 관점은 하나의 멤버십으로 제공합니다. 공개된 관점의 변화는 날짜별 후속 글로 남깁니다.',
          style: t
              .body(13, color: context.colors.textSecondary)
              .copyWith(height: 1.7),
        ),
        const SizedBox(height: AppSpace.lg),
        if (widget.corpCode != null)
          ShadButton.ghost(
            onPressed: () => context.go('/insights'),
            child: const Text('모든 투자 관점 보기'),
          ),
        if (_loading && _notes.isEmpty) const Text('투자 관점을 불러오는 중…'),
        if (_failed) ...[
          const Text('투자 관점을 불러오지 못했습니다.'),
          ShadButton.outline(
            onPressed: () => _load(append: _notes.isNotEmpty),
            child: const Text('다시 시도'),
          ),
        ],
        if (!_loading && !_failed && _notes.isEmpty)
          DataPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '아직 공개된 투자 관점이 없습니다.',
                  style: t.body(16, weight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  '작성자가 확인한 글부터 공개합니다. 기업 정보와 재무 분석은 지금 탐색할 수 있습니다.',
                  style: t.body(14, color: context.colors.textSecondary),
                ),
                const SizedBox(height: AppSpace.md),
                ShadButton.outline(
                  onPressed: () => context.go('/companies'),
                  child: const Text('기업 분석 시작하기'),
                ),
              ],
            ),
          ),
        for (final note in _notes) ...[
          DataPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${note['tier'] == 'topPick' ? '탑픽' : '관심종목'} · ${_date(note['publishedAt'])}',
                  style: t.body(12, color: context.colors.textSecondary),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(note['title'] as String, style: t.display(21)),
                const SizedBox(height: AppSpace.sm),
                Text(
                  note['introduction'] as String,
                  style: t.body(14).copyWith(height: 1.8),
                ),
                const SizedBox(height: AppSpace.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ShadButton.outline(
                    onPressed: () => context.push('/insights/${note['id']}'),
                    child: Text(
                      note['locked'] == true ? '소개와 멤버십 안내 보기' : '투자 관점 읽기',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
        ],
        if (_more && !_failed)
          ShadButton.outline(
            enabled: !_loading,
            onPressed: _loading ? null : () => _load(append: true),
            child: Text(_loading ? '불러오는 중…' : '더 보기'),
          ),
      ],
    );
  }
}

String _date(dynamic value) =>
    value is String && value.length >= 10 ? value.substring(0, 10) : '날짜 확인 중';
