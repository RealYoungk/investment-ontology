import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design/components/components.dart';
import '../design/tokens.dart';

class RouteNotFoundPage extends StatelessWidget {
  const RouteNotFoundPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.colors.surface,
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '페이지를 찾을 수 없어요',
                style: context.typo.sectionTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpace.sm),
              const Text('주소를 확인하거나 홈으로 돌아가세요.', textAlign: TextAlign.center),
              const SizedBox(height: AppSpace.lg),
              ShadButton(
                onPressed: () => context.go('/home'),
                child: const Text('홈으로 돌아가기'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
