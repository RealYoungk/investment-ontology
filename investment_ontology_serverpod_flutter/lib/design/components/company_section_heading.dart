import 'package:shad/shad.dart';
import 'package:flutter/material.dart';

import '../tokens.dart';
import 'adaptive_detail.dart';
import 'data_panel.dart';

/// 기업 상세 탭의 공통 정보 계층: 항목명 다음에 짧은 읽기 안내.
class CompanySectionHeading extends StatelessWidget {
  const CompanySectionHeading(
    this.title, {
    super.key,
    this.description,
    this.help,
    this.trailing,
  });
  final String title;
  final String? description;
  final String? help;
  final Widget? trailing;
  void _showHelp(BuildContext context) => showAdaptiveDetail(
    context: context,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$title 읽는 법',
                  style: context.typo.body(16, weight: FontWeight.w600),
                ),
              ),
              Semantics(
                container: true,
                label: '닫기',
                button: true,
                onTap: () => Navigator.of(context).pop(),
                child: ExcludeSemantics(
                  child: ShadIconButton.ghost(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text(help!, style: context.typo.body(13).copyWith(height: 1.6)),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final heading = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(title, style: context.typo.sectionTitle)),
        if (help != null)
          Semantics(
            container: true,
            label: '$title 읽는 법',
            button: true,
            onTap: () => _showHelp(context),
            child: ExcludeSemantics(
              child: ShadIconButton.ghost(
                icon: Icon(
                  Icons.info_outline,
                  size: 18,
                  color: context.colors.textMuted,
                ),
                onPressed: () => _showHelp(context),
              ),
            ),
          ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, box) {
            if (trailing == null) return heading;
            if (box.maxWidth < 600) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  heading,
                  const SizedBox(height: AppSpace.sm),
                  Align(alignment: Alignment.centerRight, child: trailing!),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: Align(alignment: Alignment.centerLeft, child: heading),
                ),
                const SizedBox(width: AppSpace.md),
                trailing!,
              ],
            );
          },
        ),
        if (description != null) ...[
          const SizedBox(height: AppSpace.xs),
          Text(
            description!,
            style: context.typo.body(13, color: context.colors.textSecondary),
          ),
        ],
      ],
    );
  }
}

/// 탭의 목적은 한 번만 안내하고, 아래의 섹션 제목보다 한 단계 높게 표시한다.
class CompanyTabIntro extends StatelessWidget {
  const CompanyTabIntro(this.title, this.description, {super.key});
  final String title;
  final String description;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.typo.body(22, weight: FontWeight.w700)),
        const SizedBox(height: AppSpace.xs),
        Text(
          description,
          style: context.typo.body(13, color: context.colors.textSecondary),
        ),
      ],
    ),
  );
}

class CompanyDataCard extends StatelessWidget {
  const CompanyDataCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DataPanel(child: child);
}
