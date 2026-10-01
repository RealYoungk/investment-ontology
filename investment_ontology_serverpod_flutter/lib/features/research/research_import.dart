import 'dart:convert';

import 'package:flutter/material.dart';

import '../../client.dart';
import '../../design/tokens.dart';
import '../auth/app_viewer.dart';

/// Optional supplier integration, available only to administrators.
class ResearchImport extends StatefulWidget {
  const ResearchImport({
    super.key,
    required this.corpCode,
    required this.kind,
    required this.onSaved,
  });
  final String corpCode, kind;
  final VoidCallback onSaved;
  @override
  State<ResearchImport> createState() => _ResearchImportState();
}

class _ResearchImportState extends State<ResearchImport> {
  final _payload = TextEditingController(),
      _provider = TextEditingController(),
      _url = TextEditingController(),
      _rights = TextEditingController();
  bool _busy = false;
  int? _count;
  String? _notice;
  @override
  void didUpdateWidget(covariant ResearchImport old) {
    super.didUpdateWidget(old);
    if (old.kind != widget.kind || old.corpCode != widget.corpCode) {
      _count = null;
      _notice = null;
      _payload.clear();
    }
  }

  @override
  void dispose() {
    for (final c in [_payload, _provider, _url, _rights]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _run(bool save) async {
    if (!context.ensureAdmin()) return;
    final corp = widget.corpCode, kind = widget.kind;
    setState(() => _busy = true);
    try {
      if (save) {
        await client.research.importFeed(
          corp,
          kind,
          _payload.text,
          _provider.text,
          _url.text,
          _rights.text,
        );
        widget.onSaved();
      } else {
        final rows = jsonDecode(
          await client.research.preview(kind, _payload.text),
        ) as List;
        if (mounted && kind == widget.kind && corp == widget.corpCode) {
          setState(() => _count = rows.length);
        }
      }
      if (mounted && kind == widget.kind && corp == widget.corpCode) {
        setState(
          () => _notice = save
              ? '저장했습니다.'
              : '$_count개 행 형식 검증 완료. 기업 소속 종목은 저장 시 검증합니다.',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _notice = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!context.isAdmin) return const SizedBox.shrink();
    return ExpansionTile(
      title: const Text('공급 자료 연결'),
      children: [
        Text(
          '계약·허용 범위가 확인된 자료만 반입합니다. 숫자는 원·주 단위 문자열, 기준일은 YYYY-MM-DD입니다.',
          style: context.typo.body(12, color: context.colors.textMuted),
        ),
        for (final field in [
          (_provider, '공급원'),
          (_url, '출처 HTTPS 주소'),
          (_rights, '공개 제공 권한 근거'),
        ])
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.sm),
            child: TextField(
              controller: field.$1,
              decoration: InputDecoration(labelText: field.$2),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpace.sm),
          child: TextField(
            controller: _payload,
            minLines: 4,
            maxLines: 10,
            onChanged: (_) => setState(() => _count = null),
            decoration: const InputDecoration(labelText: '검증할 JSON 배열'),
          ),
        ),
        Wrap(
          spacing: AppSpace.sm,
          children: [
            TextButton(
              onPressed: _busy ? null : () => _run(false),
              child: const Text('형식 검증'),
            ),
            FilledButton(
              onPressed: _busy || _count == null ? null : () => _run(true),
              child: Text(_busy ? '처리 중…' : '검증 자료 저장'),
            ),
          ],
        ),
        if (_notice != null) Text(_notice!, style: context.typo.body(12)),
      ],
    );
  }
}
