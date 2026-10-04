import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../app/router.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../auth/app_auth.dart';
import 'watchlist_store.dart';
import '../monetization/membership_offer.dart';

class WatchlistButton extends StatelessWidget {
  const WatchlistButton({
    super.key,
    required this.corpCode,
    this.compact = false,
  });
  final String corpCode;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final store = WatchlistStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final saved = store.contains(corpCode);
        final label = store.busyCodes.contains(corpCode)
            ? '저장 중…'
            : saved
            ? '관심등록됨'
            : '관심등록';
        const icon = LucideIcons.star;
        final VoidCallback? onPressed =
            store.busyCodes.contains(corpCode) || store.loading
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
                  if (context.mounted &&
                      e.code == 'limit' &&
                      store.view?.paid == false) {
                    await showMembershipOffer(context);
                  } else if (context.mounted) {
                    ShadToaster.of(context).show(
                      ShadToast(
                        description: Text(e.message),
                      ),
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    ShadToaster.of(context).show(
                      ShadToast(
                        description: Text('관심종목 저장에 실패했습니다. 다시 시도해 주세요.'),
                      ),
                    );
                  }
                }
              };
        return ShadButton.raw(
          enabled: onPressed != null,
          onPressed: onPressed,

          variant: ShadButtonVariant.outline,
          size: (compact) ? ShadButtonSize.sm : ShadButtonSize.regular,
          leading: Icon(
            icon,
            size: 16,
            color: saved ? context.colors.accent : context.colors.textMuted,
          ),
          child: Flexible(child: Text(label)),
        );
      },
    );
  }
}
