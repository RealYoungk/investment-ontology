import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../../client.dart';
import '../../../design/components/components.dart';
import '../../../design/tokens.dart';
import '../../common/formatters.dart';

class NewCompanies extends StatefulWidget {
  const NewCompanies({super.key});

  @override
  State<NewCompanies> createState() => _NewCompaniesState();
}

class _NewCompaniesState extends State<NewCompanies> {
  late Future<List<NewCompanyView>> _items = client.market.newCompanies();

  @override
  Widget build(BuildContext context) => DataPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('새로 확인한 기업'),
        const SizedBox(height: AppSpace.sm),
        Text(
          '일일 수집에서 처음 확인한 기업입니다. 확인일은 공식 상장일과 다를 수 있습니다.',
          style: context.typo.body(12, color: context.colors.textMuted),
        ),
        const SizedBox(height: AppSpace.md),
        FutureBuilder<List<NewCompanyView>>(
          future: _items,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('새로 확인한 기업을 불러오지 못했습니다.'),
                  ShadButton.link(
                    onPressed: () =>
                        setState(() => _items = client.market.newCompanies()),
                    child: const Text('다시 확인'),
                  ),
                ],
              );
            }
            if (!snapshot.hasData) return const Text('불러오는 중…');
            final items = snapshot.data!;
            if (items.isEmpty) {
              return const Text('아직 새로 확인한 기업이 없습니다. 다음 정상 수집부터 기록합니다.');
            }
            return Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                for (final item in items)
                  ShadButton.outline(
                    height: 0,
                    padding: const EdgeInsets.all(AppSpace.md),
                    onPressed: () => context.push('/company/${item.corpCode}'),
                    child: Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(item.name),
                          Text(
                            '${marketLabel(item.market)} · 확인 ${formatDate(item.observedDate)}',
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}
