import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../auth/app_auth.dart';
import 'investment_notes_api.dart';

typedef NoteLoad = Future<Map<String, dynamic>?> Function(int id, bool preview);

class InvestmentNotePage extends StatefulWidget {
  const InvestmentNotePage({
    super.key,
    required this.articleId,
    this.preview = false,
    this.load,
  });
  final int articleId;
  final bool preview;
  final NoteLoad? load;
  @override
  State<InvestmentNotePage> createState() => _InvestmentNotePageState();
}

class _InvestmentNotePageState extends State<InvestmentNotePage> {
  Map<String, dynamic>? _note;
  bool _loading = true, _failed = false;
  int _epoch = 0;
  @override
  void initState() {
    super.initState();
    AppAuth.viewer.addListener(_load);
    _load();
  }

  @override
  void didUpdateWidget(covariant InvestmentNotePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.articleId != widget.articleId ||
        oldWidget.preview != widget.preview) {
      _load();
    }
  }

  @override
  void dispose() {
    AppAuth.viewer.removeListener(_load);
    _epoch++;
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_epoch;
    // Immediately discard the previous account's restricted reader projection.
    setState(() {
      _note = null;
      _loading = true;
      _failed = false;
    });
    try {
      final result =
          await (widget.load?.call(widget.articleId, widget.preview) ??
              InvestmentNotesApi.detail(
                widget.articleId,
                preview: widget.preview,
              ));
      if (!mounted || request != _epoch) return;
      setState(() {
        _note = result;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || request != _epoch) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.typo;
    final note = _note;
    return PageFrame(
      maxWidth: 760,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: ShadButton.ghost(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/insights');
              }
            },
            child: const Text('투자 관점 목록으로'),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        if (_loading)
          const Text('투자 관점을 불러오는 중…')
        else if (_failed) ...[
          Text(
            widget.preview
                ? '미리보기를 불러오지 못했습니다. 관리자 계정으로 확인하세요.'
                : '글을 불러오지 못했습니다. 다시 시도해 주세요.',
          ),
          ShadButton.outline(onPressed: _load, child: const Text('다시 시도')),
        ] else if (note == null)
          const Text('공개된 글을 찾을 수 없습니다.')
        else ...[
          if (widget.preview) ...[
            Text(
              '공개 전 미리보기 · 작성자 최종 확인이 필요합니다.',
              style: t.body(
                14,
                color: context.colors.accent,
                weight: FontWeight.w600,
              ),
            ),
            SelectableText(
              '버전 ${note['version']} · 승인 대조값 ${note['digest']}',
              style: t.body(11, color: context.colors.textMuted),
            ),
            const SizedBox(height: AppSpace.lg),
          ],
          Text(note['title'] as String, style: t.display(30)),
          const SizedBox(height: AppSpace.md),
          Text(
            '${note['tier'] == 'topPick' ? '탑픽' : '관심종목'}${note['author'] == null ? '' : ' · ${note['author']}'}${note['publishedAt'] == null ? '' : ' · ${(note['publishedAt'] as String).substring(0, 10)}'}',
            style: t.body(13, color: context.colors.textSecondary),
          ),
          if (note['dataAsOf'] != null)
            Text(
              '자료 확인 기준일 ${(note['dataAsOf'] as String).substring(0, 10)}',
              style: t.body(12, color: context.colors.textMuted),
            ),
          const SizedBox(height: AppSpace.lg),
          SelectableText(
            note['introduction'] as String,
            style: t.body(17).copyWith(height: 1.8),
          ),
          const SizedBox(height: AppSpace.lg),
          if (note['locked'] == true)
            DataPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('상세 투자 관점은 멤버십에서', style: t.display(21)),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    '탑픽과 상세 투자 근거, 날짜별 후속 관점을 하나의 멤버십으로 읽어보세요.',
                    style: t.body(14).copyWith(height: 1.7),
                  ),
                  const SizedBox(height: AppSpace.md),
                  Wrap(
                    spacing: AppSpace.sm,
                    runSpacing: AppSpace.sm,
                    children: [
                      ShadButton(
                        onPressed: () => context.go('/membership'),
                        child: const Text('멤버십 확인하기'),
                      ),
                      if (AppAuth.viewer.value == null)
                        ShadButton.outline(
                          onPressed: () => context.go(
                            Uri(
                              path: '/login',
                              queryParameters: {
                                'next': '/insights/${widget.articleId}',
                              },
                            ).toString(),
                          ),
                          child: const Text('이미 회원이라면 로그인'),
                        ),
                    ],
                  ),
                ],
              ),
            )
          else ...[
            for (final raw in note['sections'] as List? ?? []) ...[
              Text(raw['heading'] as String, style: t.display(22)),
              const SizedBox(height: AppSpace.md),
              SelectableText(
                raw['text'] as String,
                style: t.body(15).copyWith(height: 1.9),
              ),
              const SizedBox(height: AppSpace.sm),
              for (final source in (note['sources'] as List? ?? []).where(
                (s) => (raw['sourceIds'] as List).contains(s['id']),
              ))
                Align(
                  alignment: Alignment.centerLeft,
                  child: ShadButton.ghost(
                    onPressed: () => launchUrl(
                      Uri.parse(source['url'] as String),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Flexible(child: Text('근거 · ${source['title']}')),
                  ),
                ),
              const SizedBox(height: AppSpace.xl),
            ],
            Text('근거 자료', style: t.display(20)),
            const SizedBox(height: AppSpace.md),
            for (final source in note['sources'] as List? ?? [])
              Align(
                alignment: Alignment.centerLeft,
                child: ShadButton.outline(
                  onPressed: () => launchUrl(
                    Uri.parse(source['url'] as String),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Flexible(child: Text(source['title'] as String)),
                ),
              ),
            const SizedBox(height: AppSpace.xl),
          ],
          if (note['previousArticleId'] != null)
            ShadButton.outline(
              onPressed: () =>
                  context.push('/insights/${note['previousArticleId']}'),
              child: const Text('이전 투자 관점 읽기'),
            ),
          if (note['corpCode'] != null) ...[
            const SizedBox(height: AppSpace.lg),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                ShadButton.outline(
                  onPressed: () => context.push('/company/${note['corpCode']}'),
                  child: const Text('기업 분석 이어가기'),
                ),
                ShadButton.outline(
                  onPressed: () =>
                      context.go('/watchlist?add=${note['corpCode']}'),
                  child: const Text('관심기업으로 모니터링'),
                ),
                ShadButton.ghost(
                  onPressed: () =>
                      context.push('/insights?company=${note['corpCode']}'),
                  child: const Text('이 기업의 전체 기록'),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpace.xl),
          Text(
            '작성자의 투자 관점과 확인한 근거를 구분해 읽어주세요. 이후의 변화는 새 글로 남깁니다.',
            style: t
                .body(12, color: context.colors.textMuted)
                .copyWith(height: 1.7),
          ),
        ],
      ],
    );
  }
}
