import 'package:shad/shad.dart';
import 'package:flutter/material.dart';

import '../tokens.dart';
import 'data_panel.dart';

/// 기업 상세에서 보조 정보를 여는 카드. 접힌 상태에서도 내용을 예고한다.
class CompanyDetailDisclosure extends StatelessWidget {
  const CompanyDetailDisclosure({
    super.key,
    required this.title,
    required this.summary,
    required this.children,
    this.collapsible = true,
  });
  final String title;
  final String summary;
  final List<Widget> children;
  final bool collapsible;

  @override
  Widget build(BuildContext context) {
    return DataPanel(
      child: !collapsible
          ? Padding(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: context.typo.body(16, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    summary,
                    style: context.typo.body(
                      12,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  ...children,
                ],
              ),
            )
          : ShadAccordion<int>(
              maintainState: false,
              children: [
                ShadAccordionItem<int>(
                  value: 0,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.typo.body(16, weight: FontWeight.w600),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpace.xs),
                        child: Text(
                          summary,
                          style: context.typo.body(
                            12,
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.md,
                    vertical: AppSpace.sm,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.md,
                      0,
                      AppSpace.md,
                      AppSpace.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
