import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design/tokens.dart';

class CompanyDiscoveryNavigation extends StatelessWidget {
  const CompanyDiscoveryNavigation({super.key, required this.discovery});
  final bool discovery;

  // Keep each tab's URL filters while switching discovery methods in this session.
  static final _locations = <String, String>{};

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final toggle = SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: '/screen', label: Text('조건으로 찾기')),
          ButtonSegment(value: '/industries', label: Text('업종으로 찾기')),
        ],
        selected: {discovery ? '/industries' : '/screen'},
        showSelectedIcon: false,
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            context.typo.body(13, weight: FontWeight.w600),
          ),
          minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
        ),
        onSelectionChanged: (selection) {
          final current = GoRouterState.of(context).uri;
          _locations[current.path] = current.toString();
          final path = selection.single;
          context.go(_locations[path] ?? path);
        },
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
