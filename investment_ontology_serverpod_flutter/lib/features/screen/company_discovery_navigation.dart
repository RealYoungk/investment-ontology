import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design/tokens.dart';

import 'package:shad/shad.dart';

class CompanyDiscoveryNavigation extends StatelessWidget {
  const CompanyDiscoveryNavigation({super.key, required this.discovery});
  final bool discovery;

  // Keep each tab's URL filters while switching discovery methods in this session.
  static final _locations = <String, String>{};

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final toggle = Wrap(
        spacing: AppSpace.sm,
        runSpacing: AppSpace.sm,
        children: [
          for (final entry in const {
            '/screen': '조건으로 찾기',
            '/industries': '업종으로 찾기',
          }.entries)
            IntrinsicWidth(
              child: ShadToggle(
                value: entry.key == (discovery ? '/industries' : '/screen'),
                onChanged: (selected) {
                  if (!selected) return;
                  final current = GoRouterState.of(context).uri;
                  _locations[current.path] = current.toString();
                  context.go(_locations[entry.key] ?? entry.key);
                },
                child: Text(entry.value),
              ),
            ),
        ],
      );
      if (box.maxWidth >= 600) {
        return Row(
          children: [
            Expanded(child: Text('기업 찾기', style: context.typo.pageTitle)),
            const SizedBox(width: AppSpace.md),
            toggle,
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('기업 찾기', style: context.typo.pageTitle),
          const SizedBox(height: AppSpace.md),
          toggle,
        ],
      );
    },
  );
}
