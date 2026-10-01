import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../app/router.dart';
import '../../design/components/components.dart';
import '../auth/app_auth.dart';
import 'watchlist_store.dart';

class WatchlistButton extends StatelessWidget {
  const WatchlistButton({super.key, required this.corpCode});
  final String corpCode;
  @override
  Widget build(BuildContext context) {
    final store = WatchlistStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final saved = store.contains(corpCode);
        return AppButton(
          label: store.busyCodes.contains(corpCode)
              ? '저장 중…'
              : saved
              ? '관심등록됨'
              : '관심등록',
          icon: saved ? Icons.star : Icons.star_border,
          onPressed: store.busyCodes.contains(corpCode) || store.loading
              ? null
              : () async {
                  if (AppAuth.viewer.value == null) {
                    context.push(
                      AppRoutes.login(next: '/watchlist?add=$corpCode'),
                    );
                    return;
                  }
                  try {
                    await store.toggle(corpCode);
                  } on WatchlistError catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(e.message)));
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('관심종목 저장에 실패했습니다. 다시 시도해 주세요.'),
                        ),
                      );
                    }
                  }
                },
        );
      },
    );
  }
}
