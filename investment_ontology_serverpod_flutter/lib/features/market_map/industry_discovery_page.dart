import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/router.dart';
import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import '../screen/company_discovery_navigation.dart';
import 'industry_directory.dart';
import 'discovery_definitions.dart';

const discoveryRoles = {
  'chip': '칩 설계·제조',
  'equipment': '장비',
  'material': '소재',
  'component': '부품·소모품',
  'service': '위탁생산·패키징·테스트',
  'design': '설계 IP·디자인하우스',
};

/// Every predicate applies to ONE evidenced activity, not a company's union
/// of unrelated products. Results are deduplicated only after filtering.
List<IndustryActivity> filterIndustryActivities(
  List<IndustryActivity> items,
  Map<String, String> filters,
) => items.where((a) {
  for (final entry in {
    'industry': a.industryKey ?? 'semiconductor',
    'role': a.role,
    'product': a.productKey,
    'process': a.process,
    'target': a.target,
    'method': a.method,
    'market': a.market,
  }.entries) {
    if (filters[entry.key] case final String value when value.isNotEmpty) {
      if (entry.key == 'role' &&
          value == 'design' &&
          {'design_ip', 'design_service'}.contains(a.role)) {
        continue;
      }
      if (entry.key == 'role' &&
          value == 'service' &&
          {'foundry', 'osat'}.contains(a.role)) {
        continue;
      }
      if (entry.key == 'role' &&
          value.startsWith('registered:') &&
          a.productKey.startsWith(value)) {
        continue;
      }
      if (entry.key == 'role' && value != a.role) {
        const oldProducts = <String, Set<String>>{
          'business:가공식품': {'confectionery'},
          'business:가스 공급': {'city_gas'},
          'business:게임 개발·서비스': {'game_service'},
          'business:고분자·합성수지': {'synthetic_resin'},
          'business:광고·마케팅': {'advertising'},
          'business:교육 서비스': {'education_service'},
          'business:농축산 투입재': {'animal_feed', 'crop_protection', 'fertilizer'},
          'business:도료·접착제': {'adhesive', 'paint'},
          'business:로봇·자동화': {'robot'},
          'business:보험': {'life_insurance', 'nonlife_insurance'},
          'business:비철금속': {'copper_products'},
          'business:산업용 기계': {'agricultural_machine'},
          'business:엔지니어링': {'engineering'},
          'business:영상·음악': {'music_business'},
          'business:영상·치료 기기': {'medical_imaging'},
          'business:유공압·동력전달': {'industrial_valve'},
          'business:유제품·육가공': {'meat_processing'},
          'business:윤활유·윤활기유': {'lubricants'},
          'business:음료·주류': {'beverage'},
          'business:전력기기': {'switchgear', 'transformer'},
          'business:진단': {'ivd'},
          'business:진단 기기·시약': {'diagnostic_reagent'},
          'business:철강 제품': {'steel_pipe', 'steel_products', 'steel_wire'},
          'business:치과': {'dental'},
          'business:회전기기': {'electric_motor'},
          'business:신약 개발·기술이전': {'drug_discovery', 'drug_license'},
          'business:위탁개발·생산': {'bio_cdmo', 'drug_cmo'},
          'business:의약 원료': {'api_drug'},
          'business:연구·임상 서비스': {'cro'},
          'business:의약품 개발·판매': {'biosimilar', 'generic_drug'},
          'business:보안': {'security'},
          'business:업무용 소프트웨어': {'erp'},
          'business:클라우드·인프라': {'cloud', 'hosting'},
          'business:IT 구축·운영': {'si'},
          'business:데이터·AI': {'ai_software'},
          'business:전자상거래 솔루션': {'commerce_platform'},
        };
        if (oldProducts[value]?.contains(a.productKey) ?? false) continue;
      }
      if (value != entry.value) return false;
    }
  }
  return true;
}).toList();

class IndustryDiscoveryPage extends StatefulWidget {
  const IndustryDiscoveryPage({super.key, required this.query, this.fetch});
  final Map<String, String> query;
  final Future<IndustryDiscovery> Function()? fetch;

  @override
  State<IndustryDiscoveryPage> createState() => _IndustryDiscoveryPageState();
}

class _IndustryDiscoveryPageState extends State<IndustryDiscoveryPage> {
  // Old registered-industry links now open the same business view.
  Map<String, String> get _query {
    final query = Map<String, String>.from(widget.query)..remove('basis');
    if (widget.query['basis'] == 'registered' ||
        (query['role']?.startsWith('ksic:') ?? false)) {
      for (final key in ['role', 'product', 'process', 'target', 'method']) {
        query.remove(key);
      }
    }
    return query;
  }

  IndustryDiscovery? _data;
  bool _failed = false;
  int _limit = 10;
  int _unclassifiedLimit = 10;
  int _seq = 0;
  List<String> get _selected => (_query['codes'] ?? '')
      .split(',')
      .where((s) => RegExp(r'^\d{8}$').hasMatch(s))
      .toSet()
      .take(4)
      .toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant IndustryDiscoveryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query.isEmpty && _query.isNotEmpty && _data == null) {
      _load();
    }
    if (oldWidget.query.toString() != widget.query.toString()) {
      _limit = 10;
      _unclassifiedLimit = 10;
    }
  }

  Future<void> _load() async {
    final seq = ++_seq;
    setState(() => _failed = false);
    try {
      final data = await (widget.fetch?.call() ?? client.industry.browse());
      if (mounted && seq == _seq) setState(() => _data = data);
    } catch (_) {
      if (mounted && seq == _seq) setState(() => _failed = true);
    }
  }

  void _change(String key, String? value) {
    final next = Map<String, String>.from(_query)..remove('q');
    if (value == null || value.isEmpty) {
      next.remove(key);
    } else {
      next[key] = value;
    }
    if (key == 'role') {
      for (final k in ['product', 'process', 'target', 'method']) {
        next.remove(k);
      }
    }
    context.go(
      Uri(
        path: '/industries',
        queryParameters: next.isEmpty ? null : next,
      ).toString(),
    );
  }

  Widget _filter(String key, String label, Map<String, String> options) {
    if (options.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.typo.body(13, color: context.colors.textSecondary),
          ),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              AppButton(
                label: '전체',
                variant: _query[key] == null
                    ? AppButtonVariant.primary
                    : AppButtonVariant.secondary,
                onPressed: () => _change(key, null),
              ),
              for (final e in options.entries)
                AppButton(
                  label: e.value,
                  variant: _query[key] == e.key
                      ? AppButtonVariant.primary
                      : AppButtonVariant.secondary,
                  onPressed: () =>
                      _change(key, _query[key] == e.key ? null : e.key),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_query['industry'] == null) {
      return PageFrame(
        maxWidth: 1120,
        children: [
          const CompanyDiscoveryNavigation(discovery: true),
          const SizedBox(height: AppSpace.lg),
          Text('관심 있는 업종을 골라보세요', style: context.typo.sectionTitle),
          const SizedBox(height: AppSpace.md),
          if (_failed) ...[
            const Text('업종을 불러오지 못했어요.'),
            AppButton(label: '다시 불러오기', onPressed: _load),
          ] else if (_data == null)
            const LinearProgressIndicator()
          else
            IndustryDirectory(data: _data!),
        ],
      );
    }
    final data = _data;
    final colors = context.colors;
    final typo = context.typo;
    final industryItems = (data?.activities ?? <IndustryActivity>[])
        .where(
          (a) => (a.industryKey ?? 'semiconductor') == _query['industry'],
        )
        .toList();
    final industryName =
        industryItems.firstOrNull?.industryName ??
        (_query['industry'] == 'semiconductor' ? '반도체' : '업종 탐색');
    bool isRegistered(IndustryActivity a) =>
        a.classificationBasis == 'ksic' ||
        a.classificationBasis == 'unclassified';
    final businessItems = industryItems.where((a) => !isRegistered(a)).toList();
    final registeredItems = industryItems.where(isRegistered).toList();
    final allBusinessCodes = (data?.activities ?? <IndustryActivity>[])
        .where((a) => !isRegistered(a))
        .map((a) => a.corpCode)
        .toSet();
    final withoutBusiness = registeredItems
        .where((a) => !allBusinessCodes.contains(a.corpCode))
        .toList();
    final activeItems = businessItems;
    final definitions =
        offeringDefinitions[_query['industry']] ?? <String, (String, String)>{};
    final roles = <String, String>{
      for (final e in definitions.entries) e.key: e.value.$1,
      for (final a in activeItems)
        a.role:
            definitions[a.role]?.$1 ??
            a.groupName ??
            discoveryRoles[a.role] ??
            a.role,
    };
    final filtered = filterIndustryActivities(activeItems, _query);
    final companies = <String, List<IndustryActivity>>{};
    for (final a in filtered) {
      companies.putIfAbsent(a.corpCode, () => []).add(a);
    }
    final roleItems = filterIndustryActivities(activeItems, {
      if (_query['role'] != null) 'role': _query['role']!,
    });
    Map<String, String> values(String? Function(IndustryActivity) get) => {
      for (final a in roleItems)
        if (get(a) != null) get(a)!: get(a)!,
    };
    return PageFrame(
      maxWidth: 1120,
      children: [
        const CompanyDiscoveryNavigation(discovery: true),
        const SizedBox(height: AppSpace.lg),
        Row(
          children: [
            Expanded(child: Text(industryName, style: typo.sectionTitle)),
            const SizedBox(width: AppSpace.sm),
            AppButton(
              label: '분야 바꾸기',
              icon: Icons.swap_horiz_rounded,
              onPressed: () => context.go('/industries'),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        if (_failed) ...[
          Text('분류 정보를 불러오지 못했어요.', style: typo.body(14)),
          AppButton(label: '다시 시도', onPressed: _load),
        ] else if (data == null) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: AppSpace.sm),
          Text('기업을 불러오고 있어요…', style: typo.body(13)),
        ] else ...[
          LayoutBuilder(
            builder: (context, box) {
              final wide = box.maxWidth >= 850;
              final navigation = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '사업 선택',
                    style: typo.body(13, color: colors.textSecondary),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  LayoutBuilder(
                    builder: (context, box) {
                      final double? width = wide ? box.maxWidth : null;
                      return Wrap(
                        spacing: AppSpace.sm,
                        runSpacing: AppSpace.sm,
                        children: [
                          SizedBox(
                            width: width,
                            child: AppButton(
                              label: '전체 사업',
                              variant: _query['role'] == null
                                  ? AppButtonVariant.primary
                                  : AppButtonVariant.secondary,
                              onPressed: () => _change('role', null),
                            ),
                          ),
                          for (final role in roles.entries)
                            SizedBox(
                              width: width,
                              child: AppButton(
                                label:
                                    activeItems.any((a) => a.role == role.key)
                                    ? '${role.value} · ${activeItems.where((a) => a.role == role.key).map((a) => a.corpCode).toSet().length}개사'
                                    : '${role.value} · 근거 확인 전',
                                variant: _query['role'] == role.key
                                    ? AppButtonVariant.primary
                                    : AppButtonVariant.secondary,
                                onPressed: () => _change(
                                  'role',
                                  _query['role'] == role.key ? null : role.key,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpace.md),
                  if ((_query['role']?.startsWith('business:') ?? false) &&
                      !roles.containsKey(_query['role']))
                    Text(
                      '이전 링크의 사업 조건을 유지하고 있어요. 위에서 새 분류를 선택할 수 있어요.',
                      style: typo.body(13),
                    ),
                  if (definitions[_query['role']] case final definition?) ...[
                    Text(
                      definition.$2,
                      style: typo.body(13, color: colors.textSecondary),
                    ),
                    const SizedBox(height: AppSpace.md),
                  ],
                  if (_query['role'] == 'design')
                    Text(
                      '이전 링크의 설계 IP·설계 서비스를 함께 보여드려요. 위에서 원하는 사업을 골라보세요.',
                      style: typo.body(13),
                    ),
                  if ([
                    'role',
                    'product',
                    'process',
                    'target',
                    'method',
                    'market',
                  ].any(_query.containsKey))
                    ExpansionTile(
                      key: ValueKey('details-$_query'),
                      tilePadding: EdgeInsets.zero,
                      initiallyExpanded: [
                        'product',
                        'process',
                        'target',
                        'method',
                        'market',
                      ].any(_query.containsKey),
                      title: Text('제품·기술로 좁히기', style: typo.body(13)),
                      children: [
                        _filter('product', '세부 분야', {
                          for (final a in roleItems)
                            a.productKey: a.productName,
                        }),
                        if (_query['process'] != null ||
                            roleItems.map((a) => a.process).toSet().length > 1)
                          _filter(
                            'process',
                            '공정',
                            values((a) => a.process.isEmpty ? null : a.process),
                          ),
                        if (values((a) => a.target).isNotEmpty)
                          _filter('target', '적용 대상', values((a) => a.target)),
                        if (values((a) => a.method).isNotEmpty)
                          _filter('method', '기술 방식', values((a) => a.method)),

                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          initiallyExpanded: _query['market'] != null,
                          title: Text(
                            '시장 선택',
                            style: typo.body(13, color: colors.textSecondary),
                          ),
                          children: [
                            _filter('market', '시장', const {
                              'kospi': '코스피',
                              'kosdaq': '코스닥',
                              'konex': '코넥스',
                            }),
                          ],
                        ),
                        AppButton(
                          label: '조건 지우기',
                          variant: AppButtonVariant.link,
                          onPressed: () => context.go(
                            Uri(
                              path: '/industries',
                              queryParameters: {
                                'industry': _query['industry']!,
                                if (_selected.isNotEmpty)
                                  'codes': _selected.join(','),
                              },
                            ).toString(),
                          ),
                        ),
                      ],
                    ),
                ],
              );
              final results = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('${companies.length}개 기업', style: typo.sectionTitle),
                  const SizedBox(height: AppSpace.sm),
                  if (_selected.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.md),
                    Wrap(
                      spacing: AppSpace.sm,
                      runSpacing: AppSpace.sm,
                      children: [
                        for (final code in _selected)
                          AppButton(
                            label:
                                '${data.activities.where((a) => a.corpCode == code).firstOrNull?.companyName ?? code} ×',
                            onPressed: () => _change(
                              'codes',
                              (_selected..remove(code)).join(','),
                            ),
                          ),
                        AppButton(
                          label: '${_selected.length}개 기업 비교 →',
                          variant: AppButtonVariant.primary,
                          onPressed: _selected.length < 2
                              ? null
                              : () {
                                  final product = _query['product'];
                                  final shared =
                                      product != null &&
                                      product != 'equipment_unspecified' &&
                                      !product.startsWith('ksic:') &&
                                      !product.startsWith('registered:') &&
                                      !product.startsWith('activity:') &&
                                      !product.startsWith(
                                        'kind-registration:',
                                      ) &&
                                      _selected.every(
                                        (code) => filtered.any(
                                          (a) =>
                                              a.corpCode == code &&
                                              a.productKey == product,
                                        ),
                                      );
                                  final label = shared
                                      ? data.activities
                                            .firstWhere(
                                              (a) => a.productKey == product,
                                            )
                                            .productName
                                      : null;
                                  context.push(
                                    Uri(
                                      path: '/compare',
                                      queryParameters: {
                                        'codes': _selected.join(','),
                                        'industryProduct': ?label,
                                      },
                                    ).toString(),
                                  );
                                },
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpace.sm),
                  if (companies.isEmpty)
                    Text(
                      '이 조건의 사업 근거를 아직 확보하지 못했어요. 다른 사업을 골라보세요.',
                      style: typo.body(14),
                    ),
                  for (final entry in companies.entries.take(_limit)) ...[
                    _company(entry.value),
                    const SizedBox(height: AppSpace.sm),
                  ],
                  if (companies.length > _limit)
                    AppButton(
                      label: '기업 10개 더 보기',
                      onPressed: () => setState(() => _limit += 10),
                    ),
                  if (withoutBusiness.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.lg),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(
                        '아직 사업 분류가 없는 기업 · ${withoutBusiness.length}곳',
                        style: typo.body(13),
                      ),
                      children: [
                        Text(
                          '이 분야에 등록된 기업 중 사업을 아직 확인하지 못한 곳이에요. 선택한 사업을 하지 않는다는 뜻은 아니에요.',
                          style: typo.body(13, color: colors.textSecondary),
                        ),
                        for (final a in withoutBusiness.take(
                          _unclassifiedLimit,
                        ))
                          AppButton(
                            label: a.companyName,
                            variant: AppButtonVariant.link,
                            onPressed: () => context.push(
                              '/company/${a.corpCode}?tab=business',
                            ),
                          ),
                        if (withoutBusiness.length > _unclassifiedLimit)
                          AppButton(
                            label: '미분류 기업 10개 더 보기',
                            onPressed: () =>
                                setState(() => _unclassifiedLimit += 10),
                          ),
                      ],
                    ),
                  ],
                ],
              );
              if (box.maxWidth < 850) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    navigation,
                    const SizedBox(height: AppSpace.lg),
                    results,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 240, child: navigation),
                  const SizedBox(width: AppSpace.lg),
                  Expanded(child: results),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpace.lg),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text('어떤 기준으로 나눴나요?', style: typo.body(13)),
            children: [
              Text(
                '공시로 확인한 제품·서비스를 우선 보여드려요. 공시 분류가 없는 기업은 공식 등록 업종으로 연결하고, 기업에 근거 종류를 표시해요. 등록 업종만으로 세부 제품이나 경쟁 관계가 확인된 것은 아니에요. 공식 GICS 배정은 아니에요.',
                style: typo.body(13),
              ),
              AppButton(
                label: '참고한 MSCI 분류 원칙',
                variant: AppButtonVariant.link,
                onPressed: () => launchUrl(
                  Uri.parse(
                    'https://www.msci.com/indexes/documents/methodology/1_MSCI_Global_Industry_Classification_Standard_GICS_Methodology_20250220.pdf',
                  ),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              '분류 기준과 데이터 범위',
              style: typo.body(13, color: colors.textSecondary),
            ),
            children: [
              Text(
                '상장사 ${data.listedCompanyCount}곳을 대상으로 사업을 찾아볼 수 있어요. 한국거래소의 주요 제품과 DART 공시를 함께 사용해요.\n제품이 구체적으로 연결되지 않은 경우 등록 업종을 기준으로 묶었어요. 분류 근거에서 실제 제품과 원문을 확인할 수 있어요. 같은 사업군이라도 매출 구성과 고객은 다를 수 있어요.',
                style: typo.body(12, color: colors.textSecondary),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _company(List<IndustryActivity> items) {
    final a = items.first;
    final selected = _selected.contains(a.corpCode);
    final products = {for (final item in items) item.productName}.join(' · ');
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppButton(
          label: a.companyName,
          variant: AppButtonVariant.link,
          onPressed: () => context.push(AppRoutes.company(a.corpCode)),
        ),
        if (items.every(
          (item) => item.classificationBasis == 'registered_activity',
        ))
          Text(
            '등록 업종 근거 · 세부 사업 확인 전',
            style: context.typo.body(12, color: context.colors.textMuted),
          ),
        if (items.every(
          (item) => item.classificationBasis == 'filing_activity',
        ))
          Text(
            '공시로 사업군 확인 · 세부 제품 확인 전',
            style: context.typo.body(12, color: context.colors.textMuted),
          ),
        Text(
          products,
          style: context.typo.body(13, color: context.colors.textSecondary),
        ),
      ],
    );
    final actions = Wrap(
      spacing: AppSpace.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AppButton(
          label: '근거 보기',
          variant: AppButtonVariant.link,
          onPressed: () => _showEvidence(items),
        ),
        AppButton(
          label: selected ? '비교에서 빼기' : '비교에 추가',
          onPressed: !selected && _selected.length >= 4
              ? null
              : () {
                  final codes = _selected;
                  selected ? codes.remove(a.corpCode) : codes.add(a.corpCode);
                  _change('codes', codes.join(','));
                },
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.border),
        borderRadius: context.shape.borderRadius,
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          if (box.maxWidth < 500) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: AppSpace.sm),
                actions,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: identity),
              const SizedBox(width: AppSpace.md),
              actions,
            ],
          );
        },
      ),
    );
  }

  void _showEvidence(List<IndustryActivity> items) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${items.first.companyName} · 분류 근거'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in items) ...[
                  Text(
                    item.productName,
                    style: context.typo.body(14, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  if (item.classificationBasis == 'kind_registered')
                    Text(
                      '주요 제품은 거래소 원문, 사업군은 등록 업종을 기준으로 연결했어요.',
                      style: context.typo.body(
                        12,
                        color: context.colors.textMuted,
                      ),
                    ),
                  SelectableText(item.evidence, style: context.typo.body(13)),
                  if (item.classificationBasis?.startsWith('kind_') ?? false)
                    AppButton(
                      label: '한국거래소 주요 제품 원문',
                      variant: AppButtonVariant.link,
                      onPressed: () => launchUrl(
                        Uri.https(
                          'kind.krx.co.kr',
                          '/corpgeneral/corpList.do',
                          {'method': 'loadInitPage'},
                        ),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  if (item.classificationBasis == 'issuer_source')
                    AppButton(
                      label: '발행사·운용사 원문',
                      variant: AppButtonVariant.link,
                      onPressed: () {
                        final link = RegExp(r'원문: (https://\S+)')
                            .firstMatch(item.evidence)
                            ?.group(1);
                        if (link != null) {
                          launchUrl(
                            Uri.parse(link),
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                    ),
                  if (item.rceptNo.isNotEmpty)
                    AppButton(
                      label: '${item.bsnsYear}년 DART 원문',
                      variant: AppButtonVariant.link,
                      onPressed: () => launchUrl(
                        Uri.https('dart.fss.or.kr', '/dsaf001/main.do', {
                          'rcpNo': item.rceptNo,
                        }),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  const SizedBox(height: AppSpace.md),
                ],
              ],
            ),
          ),
        ),
        actions: [
          AppButton(label: '닫기', onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}
