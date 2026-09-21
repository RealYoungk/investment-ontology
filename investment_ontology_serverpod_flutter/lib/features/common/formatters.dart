import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../design/tokens.dart';

String marketLabel(Market? m) => switch (m) {
  Market.kospi => '유가',
  Market.kosdaq => '코스닥',
  Market.konex => '코넥스',
  Market.other => '기타',
  null => '—',
};

Color marketColor(BuildContext context, Market? m) {
  final c = context.colors;
  return switch (m) {
    Market.kospi => c.marketKospi,
    Market.kosdaq => c.marketKosdaq,
    Market.konex => c.marketKonex,
    _ => c.textMuted,
  };
}

String _two(int v) => v.toString().padLeft(2, '0');

/// 날짜만 의미 있는 값 (UTC 자정으로 저장된 설립일 등) → YYYY.MM.DD
String formatDate(DateTime? d) =>
    d == null ? '—' : '${d.year}.${_two(d.month)}.${_two(d.day)}';

/// 시각 → 로컬 YYYY.MM.DD HH:mm
String formatDateTime(DateTime dt) {
  final l = dt.toLocal();
  return '${formatDate(l)} ${_two(l.hour)}:${_two(l.minute)}';
}

String formatCount(int n) => n.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ',',
);

/// 변경 이력의 필드명 → 화면 표시명.
String companyFieldLabel(String field) => switch (field) {
  'name' => '회사명',
  'nameEng' => '영문명',
  'stockName' => '종목명',
  'stockCode' => '종목코드',
  'market' => '시장',
  'ceoName' => '대표자',
  'jurirNo' => '법인등록번호',
  'bizrNo' => '사업자등록번호',
  'address' => '주소',
  'homepageUrl' => '홈페이지',
  'irUrl' => 'IR',
  'phone' => '전화',
  'industryCode' => '업종코드',
  'establishedDate' => '설립일',
  'fiscalMonth' => '결산월',
  _ => field,
};
