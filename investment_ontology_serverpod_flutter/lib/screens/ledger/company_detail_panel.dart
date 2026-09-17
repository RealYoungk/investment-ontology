import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../client.dart';
import '../../theme/ledger_theme.dart';
import 'format.dart';

/// 기업 상세: 기업개황 원문 필드 + KSIC 경로 + 출처.
class CompanyDetailPanel extends StatefulWidget {
  const CompanyDetailPanel({
    super.key,
    required this.corpCode,
    required this.onClose,
  });

  final String corpCode;
  final VoidCallback onClose;

  @override
  State<CompanyDetailPanel> createState() => _CompanyDetailPanelState();
}

class _CompanyDetailPanelState extends State<CompanyDetailPanel> {
  late final Future<CompanyDetail?> _future = client.company.detail(
    widget.corpCode,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CompanyDetail?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final d = snap.data;
        if (snap.hasError || d == null) {
          return _Frame(
            onClose: widget.onClose,
            child: Text(
              snap.hasError ? '불러오지 못했습니다: ${snap.error}' : '기업을 찾을 수 없습니다.',
              style: Typo.body(14),
            ),
          );
        }
        return _Frame(
          onClose: widget.onClose,
          child: _Body(detail: d),
        );
      },
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.onClose, required this.child});

  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('기업 카드', style: Typo.label(color: Pal.seal)),
              const Spacer(),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, color: Pal.ink),
                tooltip: '닫기',
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.detail});

  final CompanyDetail detail;

  @override
  Widget build(BuildContext context) {
    final c = detail.company;
    final source = detail.profileSource;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(c.name, style: Typo.display(34)),
        if (c.nameEng != null) ...[
          const SizedBox(height: 6),
          Text(c.nameEng!, style: Typo.body(13.5, color: Pal.inkSoft)),
        ],
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _Stamp(label: marketLabel(c.market), strong: true),
            if (c.stockCode != null) _Stamp(label: c.stockCode!),
            _Stamp(label: 'DART ${c.corpCode}'),
          ],
        ),
        const SizedBox(height: 28),
        if (detail.industryPath.isNotEmpty) ...[
          Text('산업 분류 · KSIC', style: Typo.label()),
          const SizedBox(height: 10),
          _IndustryPath(path: detail.industryPath),
          const SizedBox(height: 28),
        ],
        Text('기업개황', style: Typo.label()),
        const SizedBox(height: 6),
        _Field('대표자', c.ceoName),
        _Field(
          '설립일',
          c.establishedDate == null ? null : formatYmd(c.establishedDate),
        ),
        _Field('결산월', c.fiscalMonth == null ? null : '${c.fiscalMonth}월'),
        _Field('법인등록번호', c.jurirNo, mono: true),
        _Field('사업자등록번호', c.bizrNo, mono: true),
        _Field('주소', c.address),
        _Field('전화', c.phone, mono: true),
        _LinkField('홈페이지', c.homepageUrl),
        _LinkField('IR', c.irUrl),
        const SizedBox(height: 28),
        _SourceNote(corpCode: c.corpCode, source: source),
      ],
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({required this.label, this.strong = false});

  final String label;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: strong ? Pal.seal : Colors.transparent,
        border: Border.all(color: strong ? Pal.seal : Pal.ink, width: 1.2),
      ),
      child: Text(
        label,
        style: Typo.mono(
          12.5,
          color: strong ? Pal.paper : Pal.ink,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _IndustryPath extends StatelessWidget {
  const _IndustryPath({required this.path});

  final List<Industry> path;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, ind) in path.indexed)
          Padding(
            padding: EdgeInsets.only(left: i * 16.0, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i == 0 ? '■ ' : '└ ',
                  style: Typo.mono(
                    12,
                    color: i == path.length - 1 ? Pal.seal : Pal.inkFaint,
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    ind.code,
                    style: Typo.mono(12.5, weight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  child: Text(
                    ind.name,
                    style: Typo.body(
                      13.5,
                      weight: i == path.length - 1
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value, {this.mono = false});

  final String label;
  final String? value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Pal.rule, width: 0.8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(label, style: Typo.body(13, color: Pal.inkSoft)),
          ),
          Expanded(
            child: SelectableText(
              value ?? '—',
              style: mono ? Typo.mono(13) : Typo.body(13.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkField extends StatelessWidget {
  const _LinkField(this.label, this.url);

  final String label;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final u = url;
    if (u == null) return _Field(label, null);
    final uri = Uri.tryParse(u.startsWith('http') ? u : 'https://$u');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Pal.rule, width: 0.8)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 108,
            child: Text(label, style: Typo.body(13, color: Pal.inkSoft)),
          ),
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: uri == null ? null : () => launchUrl(uri),
                child: Text(
                  u,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Typo.body(13.5, color: Pal.seal).copyWith(
                    decoration: TextDecoration.underline,
                    decorationColor: Pal.seal,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceNote extends StatelessWidget {
  const _SourceNote({required this.corpCode, required this.source});

  final String corpCode;
  final Source? source;

  @override
  Widget build(BuildContext context) {
    final s = source;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Pal.paper,
        border: Border.all(color: Pal.ink, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('출처', style: Typo.label(color: Pal.seal)),
          const SizedBox(height: 8),
          Text(
            s?.title ?? '출처 기록 없음',
            style: Typo.body(13.5, weight: FontWeight.w600),
          ),
          if (s != null) ...[
            const SizedBox(height: 4),
            Text(
              '수집 ${formatDateTime(s.retrievedAt)}',
              style: Typo.mono(12, color: Pal.inkSoft),
            ),
          ],
          const SizedBox(height: 12),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => launchUrl(
                Uri.parse(
                  'https://dart.fss.or.kr/dsab007/main.do?autoSearch=true&option=corp&textCrpCik=$corpCode',
                ),
              ),
              child: Text(
                'DART 공시 목록 열기 →',
                style: Typo.body(13, color: Pal.seal, weight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
