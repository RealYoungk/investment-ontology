/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _ida;
import 'package:http/http.dart' as _i85jenna;
import 'package:investment_ontology_serverpod_client/src/protocol/greetings/greeting.dart'
    as _iqvwj7cf;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/ai_extraction.dart'
    as _i8m2dvht;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/ai_status.dart'
    as _ie40qci9;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/business_content.dart'
    as _i6ht4m6x;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/business_document_ref.dart'
    as _id7v70oo;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/company_detail.dart'
    as _ig9j925g;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/company_financials.dart'
    as _i8vk5eaa;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/company_governance.dart'
    as _iyg8kuqs;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/company_graph.dart'
    as _ihkbqpbm;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/company_group.dart'
    as _i7uvzrch;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/company_page.dart'
    as _itgpgg86;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/company_sort.dart'
    as _i35nawlu;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/dart_disclosure.dart'
    as _izt0hsdc;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/dart_section.dart'
    as _iaqblgop;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/disclosure_section_info.dart'
    as _i39r1xmm;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/disclosure_table.dart'
    as _i1woaxtv;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/document_fact.dart'
    as _ip7x5uw8;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/document_fact_kind.dart'
    as _i7h2wu58;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/facet_count.dart'
    as _icfgas7c;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/fact_page.dart'
    as _i9n1o9ln;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/filing_feed_item.dart'
    as _iuq4bocx;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/financial_report_detail.dart'
    as _iurgb10z;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/fs_div.dart'
    as _indtcksm;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/ingest_coverage.dart'
    as _i2drq233;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/ingest_job.dart'
    as _i1paap7y;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/investment_theme.dart'
    as _izhmhfon;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/market.dart'
    as _iamn97sz;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/market_cap_treemap.dart'
    as _ifex1fnm;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/ontology_relation.dart'
    as _isup83mn;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/overview.dart'
    as _iqnrnt8q;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/peer_comparison.dart'
    as _izfg2hmi;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/person_hit.dart'
    as _i96d117e;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/person_profile.dart'
    as _impgjy6j;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/relation_predicate.dart'
    as _iklpi3wo;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/relation_status.dart'
    as _ixp2yk27;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/review_check.dart'
    as _ixhvmecn;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/review_item.dart'
    as _ihqozc6p;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/review_page.dart'
    as _i59ekwm6;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/screen_page.dart'
    as _iy3d4gdi;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/screen_sort.dart'
    as _iswpkxoo;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/shareholder_return.dart'
    as _ir6fk3mk;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/theme_detail.dart'
    as _is8fq5gm;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/theme_member.dart'
    as _i33gd2p5;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/theme_summary.dart'
    as _ihj01hrs;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _iacc;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _iaic;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'protocol.dart' as _il2as5qe;

/// By extending [EmailIdpBaseEndpoint], the email identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
/// {@category Endpoint}
class EndpointEmailIdp extends _iaic.EndpointEmailIdpBase {
  EndpointEmailIdp(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'emailIdp';

  /// Logs in the user and returns a new session.
  ///
  /// Throws an [EmailAccountLoginException] in case of errors, with reason:
  /// - [EmailAccountLoginExceptionReason.invalidCredentials] if the email or
  ///   password is incorrect.
  /// - [EmailAccountLoginExceptionReason.tooManyAttempts] if there have been
  ///   too many failed login attempts.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _ida.Future<_iacc.AuthSuccess> login({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
    'emailIdp',
    'login',
    {
      'email': email,
      'password': password,
    },
  );

  /// Starts the registration for a new user account with an email-based login
  /// associated to it.
  ///
  /// Upon successful completion of this method, an email will have been
  /// sent to [email] with a verification link, which the user must open to
  /// complete the registration.
  ///
  /// Always returns a account request ID, which can be used to complete the
  /// registration. If the email is already registered, the returned ID will not
  /// be valid.
  @override
  _ida.Future<_isc.UuidValue> startRegistration({required String email}) =>
      caller.callServerEndpoint<_isc.UuidValue>(
        'emailIdp',
        'startRegistration',
        {'email': email},
      );

  /// Verifies an account request code and returns a token
  /// that can be used to complete the account creation.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if no request exists
  ///   for the given [accountRequestId] or [verificationCode] is invalid.
  @override
  _ida.Future<String> verifyRegistrationCode({
    required _isc.UuidValue accountRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyRegistrationCode',
    {
      'accountRequestId': accountRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a new account registration, creating a new auth user with a
  /// profile and attaching the given email account to it.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if the [registrationToken]
  ///   is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  ///
  /// Returns a session for the newly created user.
  @override
  _ida.Future<_iacc.AuthSuccess> finishRegistration({
    required String registrationToken,
    required String password,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
    'emailIdp',
    'finishRegistration',
    {
      'registrationToken': registrationToken,
      'password': password,
    },
  );

  /// Requests a password reset for [email].
  ///
  /// If the email address is registered, an email with reset instructions will
  /// be send out. If the email is unknown, this method will have no effect.
  ///
  /// Always returns a password reset request ID, which can be used to complete
  /// the reset. If the email is not registered, the returned ID will not be
  /// valid.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to request a password reset.
  ///
  @override
  _ida.Future<_isc.UuidValue> startPasswordReset({required String email}) =>
      caller.callServerEndpoint<_isc.UuidValue>(
        'emailIdp',
        'startPasswordReset',
        {'email': email},
      );

  /// Verifies a password reset code and returns a finishPasswordResetToken
  /// that can be used to finish the password reset.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to verify the password reset.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// If multiple steps are required to complete the password reset, this endpoint
  /// should be overridden to return credentials for the next step instead
  /// of the credentials for setting the password.
  @override
  _ida.Future<String> verifyPasswordResetCode({
    required _isc.UuidValue passwordResetRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyPasswordResetCode',
    {
      'passwordResetRequestId': passwordResetRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a password reset request by setting a new password.
  ///
  /// The [verificationCode] returned from [verifyPasswordResetCode] is used to
  /// validate the password reset request.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.policyViolation] if the new
  ///   password does not comply with the password policy.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _ida.Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) => caller.callServerEndpoint<void>(
    'emailIdp',
    'finishPasswordReset',
    {
      'finishPasswordResetToken': finishPasswordResetToken,
      'newPassword': newPassword,
    },
  );

  @override
  _ida.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'emailIdp',
    'hasAccount',
    {},
  );
}

/// By extending [RefreshJwtTokensEndpoint], the JWT token refresh endpoint
/// is made available on the server and enables automatic token refresh on the client.
/// {@category Endpoint}
class EndpointJwtRefresh extends _iacc.EndpointRefreshJwtTokens {
  EndpointJwtRefresh(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'jwtRefresh';

  /// Creates a new token pair for the given [refreshToken].
  ///
  /// If [refreshToken] is omitted, cookie-mode web clients fall back to the
  /// configured HttpOnly refresh cookie. When neither source is present this
  /// throws [RefreshTokenNotFoundException], the same public "no usable refresh
  /// credential" exception used for unknown refresh tokens.
  ///
  /// Can throw the following exceptions:
  /// -[RefreshTokenMalformedException]: refresh token is malformed and could
  ///   not be parsed. Not expected to happen for tokens issued by the server.
  /// -[RefreshTokenNotFoundException]: refresh token is unknown to the server.
  ///   Either the token was deleted or generated by a different server.
  /// -[RefreshTokenExpiredException]: refresh token has expired. Will happen
  ///   only if it has not been used within configured `refreshTokenLifetime`.
  /// -[RefreshTokenInvalidSecretException]: refresh token is incorrect, meaning
  ///   it does not refer to the current secret refresh token. This indicates
  ///   either a malfunctioning client or a malicious attempt by someone who has
  ///   obtained the refresh token. In this case the underlying refresh token
  ///   will be deleted, and access to it will expire fully when the last access
  ///   token is elapsed.
  ///
  /// This endpoint is unauthenticated, meaning the client won't include any
  /// authentication information with the call.
  @override
  _ida.Future<_iacc.AuthSuccess> refreshAccessToken({String? refreshToken}) =>
      caller.callServerEndpoint<_iacc.AuthSuccess>(
        'jwtRefresh',
        'refreshAccessToken',
        {'refreshToken': refreshToken},
        authenticated: false,
      );
}

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _isc.EndpointRef {
  EndpointGreeting(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _ida.Future<_iqvwj7cf.Greeting> hello(String name) =>
      caller.callServerEndpoint<_iqvwj7cf.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

/// AI 관계 추출 (4단계).
///
/// 화면 요청 중에는 모델을 부르지 않는다. 미리 뽑아 저장해 두고 화면은 저장된 것만 읽는다.
/// 뽑는 방법은 둘이다. (1) Anthropic 키로 배치 실행, (2) 밖(구독 세션 등)에서 본문을 읽고
/// [submit]으로 결과를 넣기. 어느 쪽이든 결과는 검수 대기(draft)이고, 인용이 원문에 그대로
/// 있는 후보만 남는다.
/// {@category Endpoint}
class EndpointAi extends _isc.EndpointRef {
  EndpointAi(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'ai';

  _ida.Future<_ie40qci9.AiStatus> status() =>
      caller.callServerEndpoint<_ie40qci9.AiStatus>(
        'ai',
        'status',
        {},
      );

  /// 기업 하나의 가장 최근 사업보고서 본문을 바로 읽는다 (수십 초 걸린다).
  _ida.Future<_i8m2dvht.AiExtraction> extractCompany(String corpCode) =>
      caller.callServerEndpoint<_i8m2dvht.AiExtraction>(
        'ai',
        'extractCompany',
        {'corpCode': corpCode},
      );

  /// 아직 읽지 않은 기업의 최근 본문을 [limit]개까지 읽는 작업을 시작한다.
  _ida.Future<_i1paap7y.IngestJob> startBatch({int? limit}) =>
      caller.callServerEndpoint<_i1paap7y.IngestJob>(
        'ai',
        'startBatch',
        {'limit': limit},
      );

  /// 아직 읽지 않은 기업의 최근 본문 목록. 밖에서 미리 뽑을 때 이 순서로 고른다
  /// (본문이 짧은 것부터 — 한 번에 읽기 좋다).
  _ida.Future<List<_id7v70oo.BusinessDocumentRef>> pending({int? limit}) =>
      caller.callServerEndpoint<List<_id7v70oo.BusinessDocumentRef>>(
        'ai',
        'pending',
        {'limit': limit},
      );

  /// 본문 발췌 (모델에 넣는 것과 같은 범위).
  _ida.Future<String> documentText(
    int documentId, {
    int? maxChars,
  }) => caller.callServerEndpoint<String>(
    'ai',
    'documentText',
    {
      'documentId': documentId,
      'maxChars': maxChars,
    },
  );

  /// 여러 기업의 본문을 한 번에. 아직 읽지 않은 것부터 준다.
  ///
  /// 한 기업씩 왕복하면 느려서, 구독 세션에서 관계를 뽑을 때 이걸로 묶어 받는다.
  /// 결과는 `=== <documentId> <기업 이름> FY<연도> ===` 줄로 구분한다.
  _ida.Future<String> documentTexts({
    int? limit,
    int? maxChars,
  }) => caller.callServerEndpoint<String>(
    'ai',
    'documentTexts',
    {
      'limit': limit,
      'maxChars': maxChars,
    },
  );

  /// 밖에서 뽑은 결과를 저장한다. [answer]는 배치 실행과 같은 JSON 형식이다.
  ///
  /// 인용이 원문에 그대로 없으면 그 후보는 버린다. 키가 없어도 된다.
  _ida.Future<_i8m2dvht.AiExtraction> submit(
    int documentId,
    String answer, {
    String? model,
  }) => caller.callServerEndpoint<_i8m2dvht.AiExtraction>(
    'ai',
    'submit',
    {
      'documentId': documentId,
      'answer': answer,
      'model': model,
    },
  );

  /// 밖에서 뽑은 '본문 값'(수주잔고·가동률·점유율 등)을 저장한다.
  ///
  /// ```json
  /// {"facts": [{"kind": "orderBacklog", "label": "건설사업", "value": 21292358,
  ///             "unit": "백만원", "asOf": "2025-12-31", "evidence": "…"}]}
  /// ```
  _ida.Future<String> submitFacts(
    int documentId,
    String answer, {
    String? model,
  }) => caller.callServerEndpoint<String>(
    'ai',
    'submitFacts',
    {
      'documentId': documentId,
      'answer': answer,
      'model': model,
    },
  );
}

/// 상장사 조회.
/// {@category Endpoint}
class EndpointCompany extends _isc.EndpointRef {
  EndpointCompany(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'company';

  /// 시장·대분류별 상장사 수와 최근 수집 작업.
  _ida.Future<_iqnrnt8q.Overview> overview() =>
      caller.callServerEndpoint<_iqnrnt8q.Overview>(
        'company',
        'overview',
        {},
      );

  /// 대분류 안의 중분류별 상장사 수.
  _ida.Future<List<_icfgas7c.FacetCount>> divisions(
    String sectionCode, {
    _iamn97sz.Market? market,
  }) => caller.callServerEndpoint<List<_icfgas7c.FacetCount>>(
    'company',
    'divisions',
    {
      'sectionCode': sectionCode,
      'market': market,
    },
  );

  _ida.Future<_itgpgg86.CompanyPage> list({
    String? query,
    _iamn97sz.Market? market,
    String? sectionCode,
    String? divisionCode,
    _i35nawlu.CompanySort? sort,
    int? offset,
    int? limit,
  }) => caller.callServerEndpoint<_itgpgg86.CompanyPage>(
    'company',
    'list',
    {
      'query': query,
      'market': market,
      'sectionCode': sectionCode,
      'divisionCode': divisionCode,
      'sort': sort,
      'offset': offset,
      'limit': limit,
    },
  );

  _ida.Future<_ig9j925g.CompanyDetail?> detail(String corpCode) =>
      caller.callServerEndpoint<_ig9j925g.CompanyDetail?>(
        'company',
        'detail',
        {'corpCode': corpCode},
      );
}

/// 정기보고서 주요정보 조회: 항목 목록 · 원문 표 · 주주환원.
/// {@category Endpoint}
class EndpointDisclosure extends _isc.EndpointRef {
  EndpointDisclosure(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'disclosure';

  /// 기업이 가진 주요정보 항목과 사업연도 (항목 순서는 [DartSections.info]).
  _ida.Future<List<_i39r1xmm.DisclosureSectionInfo>> sections(
    String corpCode,
  ) => caller.callServerEndpoint<List<_i39r1xmm.DisclosureSectionInfo>>(
    'disclosure',
    'sections',
    {'corpCode': corpCode},
  );

  /// 항목 하나의 원문 표 (응답 필드 그대로, 머리글만 한글). [bsnsYear]가 없으면 가장 최근.
  _ida.Future<_i1woaxtv.DisclosureTable?> table(
    String corpCode,
    _iaqblgop.DartSection section, {
    int? bsnsYear,
  }) => caller.callServerEndpoint<_i1woaxtv.DisclosureTable?>(
    'disclosure',
    'table',
    {
      'corpCode': corpCode,
      'section': section,
      'bsnsYear': bsnsYear,
    },
  );

  /// 사업보고서 본문 "II. 사업의 내용"을 하위 절로 나눠서. [bsnsYear]가 없으면 가장 최근.
  _ida.Future<_i6ht4m6x.BusinessContent?> businessContent(
    String corpCode, {
    int? bsnsYear,
  }) => caller.callServerEndpoint<_i6ht4m6x.BusinessContent?>(
    'disclosure',
    'businessContent',
    {
      'corpCode': corpCode,
      'bsnsYear': bsnsYear,
    },
  );

  /// 배당(사업보고서마다 당기·전기·전전기) · 가장 최근 자기주식 · 주식 총수.
  _ida.Future<_ir6fk3mk.ShareholderReturn?> shareholderReturn(
    String corpCode,
  ) => caller.callServerEndpoint<_ir6fk3mk.ShareholderReturn?>(
    'disclosure',
    'shareholderReturn',
    {'corpCode': corpCode},
  );

  /// 기업의 '본문에서 뽑은 값' 가운데 승인된 것 (수주잔고·가동률·점유율 등).
  ///
  /// 가장 최근 사업연도만. 화면은 이 값을 출처·근거와 함께 보여 준다.
  _ida.Future<List<_ip7x5uw8.DocumentFact>> facts(String corpCode) =>
      caller.callServerEndpoint<List<_ip7x5uw8.DocumentFact>>(
        'disclosure',
        'facts',
        {'corpCode': corpCode},
      );

  /// 승인된 값 전부 (연도별 흐름을 보려고). 오래된 해부터.
  ///
  /// 같은 항목이 해마다 있으면 화면이 막대 차트로 그린다 — 표만 있으면 흐름이 안 보인다.
  _ida.Future<List<_ip7x5uw8.DocumentFact>> factTrends(String corpCode) =>
      caller.callServerEndpoint<List<_ip7x5uw8.DocumentFact>>(
        'disclosure',
        'factTrends',
        {'corpCode': corpCode},
      );

  /// 이 기업의 최근 공시 (종류 가리지 않음). 계약·증자·주요사항 등.
  _ida.Future<List<_izt0hsdc.DartDisclosure>> recentOf(
    String corpCode, {
    int? limit,
  }) => caller.callServerEndpoint<List<_izt0hsdc.DartDisclosure>>(
    'disclosure',
    'recentOf',
    {
      'corpCode': corpCode,
      'limit': limit,
    },
  );

  /// 최근 올라온 정기보고서. 새 공시를 눈에 띄게 보여 주는 용도다.
  ///
  /// 사업·반기·분기보고서만 다룬다 (수집 대상이 그것뿐이다). 정정 공시도 그대로 보인다.
  _ida.Future<List<_iuq4bocx.FilingFeedItem>> recentFilings({
    _iamn97sz.Market? market,
    int? limit,
  }) => caller.callServerEndpoint<List<_iuq4bocx.FilingFeedItem>>(
    'disclosure',
    'recentFilings',
    {
      'market': market,
      'limit': limit,
    },
  );
}

/// 기업 재무·시세 조회. 파생 지표는 계산하지 않고 원천 값만 돌려준다.
/// {@category Endpoint}
class EndpointFinancial extends _isc.EndpointRef {
  EndpointFinancial(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'financial';

  /// 기업의 기간별 핵심 계정과 최근 시가총액.
  ///
  /// [fsDiv]가 없으면 연결재무제표가 있으면 연결, 없으면 별도를 쓴다.
  _ida.Future<_i8vk5eaa.CompanyFinancials?> summary(
    String corpCode, {
    _indtcksm.FsDiv? fsDiv,
  }) => caller.callServerEndpoint<_i8vk5eaa.CompanyFinancials?>(
    'financial',
    'summary',
    {
      'corpCode': corpCode,
      'fsDiv': fsDiv,
    },
  );

  /// 재무 보고서 원문 표와 같은 기간의 정정 이력.
  _ida.Future<_iurgb10z.FinancialReportDetail?> report(int reportId) =>
      caller.callServerEndpoint<_iurgb10z.FinancialReportDetail?>(
        'financial',
        'report',
        {'reportId': reportId},
      );
}

/// 지배구조 조회: 최대주주 · 임원 · 타법인출자와 인물.
/// {@category Endpoint}
class EndpointGovernance extends _isc.EndpointRef {
  EndpointGovernance(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'governance';

  /// 기업의 한 사업연도(없으면 가장 최근) 지배구조.
  _ida.Future<_iyg8kuqs.CompanyGovernance?> summary(
    String corpCode, {
    int? bsnsYear,
  }) => caller.callServerEndpoint<_iyg8kuqs.CompanyGovernance?>(
    'governance',
    'summary',
    {
      'corpCode': corpCode,
      'bsnsYear': bsnsYear,
    },
  );

  /// 이름으로 인물을 찾는다. 이어진 기업이 많은 순서로 [limit]명.
  _ida.Future<List<_i96d117e.PersonHit>> searchPersons(
    String query, {
    int? limit,
  }) => caller.callServerEndpoint<List<_i96d117e.PersonHit>>(
    'governance',
    'searchPersons',
    {
      'query': query,
      'limit': limit,
    },
  );

  /// 인물과 그가 주주·임원으로 있는 기업 (각 기업의 가장 최근 사업보고서 기준).
  _ida.Future<_impgjy6j.PersonProfile?> person(int personId) =>
      caller.callServerEndpoint<_impgjy6j.PersonProfile?>(
        'governance',
        'person',
        {'personId': personId},
      );

  /// 추정 인물 연결을 끊는다: 이 기업의 이 이름은 다시 계산해도 묶지 않는다.
  _ida.Future<void> rejectPersonLink(
    String corpCode,
    String holderName,
  ) => caller.callServerEndpoint<void>(
    'governance',
    'rejectPersonLink',
    {
      'corpCode': corpCode,
      'holderName': holderName,
    },
  );
}

/// 관계망: 기업을 가운데 두고 관계 색인(OntologyRelation)을 따라 이웃을 넓힌다.
///
/// 넓히는 것은 기업·인물 노드만이고, 이름뿐인 대상(비상장·해외 법인, 제품)은 끝 노드로만 둔다.
/// 거절한 관계와 검수 전 AI 관계(draft)는 빼고, 인물 추정 연결(draft)은 점선으로 넣는다.
/// {@category Endpoint}
class EndpointGraph extends _isc.EndpointRef {
  EndpointGraph(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'graph';

  _ida.Future<_ihkbqpbm.CompanyGraph?> neighborhood(
    String corpCode, {
    int? depth,
    int? maxNodes,
    bool? includeNames,
  }) => caller.callServerEndpoint<_ihkbqpbm.CompanyGraph?>(
    'graph',
    'neighborhood',
    {
      'corpCode': corpCode,
      'depth': depth,
      'maxNodes': maxNodes,
      'includeNames': includeNames,
    },
  );
}

/// 지분으로 이어진 상장사 묶음 조회.
/// {@category Endpoint}
class EndpointGroup extends _isc.EndpointRef {
  EndpointGroup(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'group';

  /// 두 곳 이상으로 이루어진 묶음. 시가총액 합이 큰 순서.
  ///
  /// 목록 화면은 지분 연결을 쓰지 않아 빼고 보낸다 (응답이 절반 아래로 줄어든다).
  _ida.Future<List<_i7uvzrch.CompanyGroup>> list() =>
      caller.callServerEndpoint<List<_i7uvzrch.CompanyGroup>>(
        'group',
        'list',
        {},
      );

  /// [corpCode] 기업이 속한 묶음. 어느 묶음에도 없으면 null.
  _ida.Future<_i7uvzrch.CompanyGroup?> of(String corpCode) =>
      caller.callServerEndpoint<_i7uvzrch.CompanyGroup?>(
        'group',
        'of',
        {'corpCode': corpCode},
      );
}

/// 외부 원천 수집 제어.
///
/// 1인 로컬 사용 전제라 인증이 없다. 외부에 배포하기 전에 인증을 붙여야 한다.
/// {@category Endpoint}
class EndpointIngest extends _isc.EndpointRef {
  EndpointIngest(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'ingest';

  /// 상장사 마스터 수집 시작. 이미 실행 중이면 그 작업을 돌려준다.
  ///
  /// 평소에는 DART 변경일이 바뀐 기업만 다시 받는다. [force]이거나 마지막 전체
  /// 갱신 후 [CompanyMasterSync.fullRefreshInterval]이 지났으면 전체를 다시 받는다.
  _ida.Future<_i1paap7y.IngestJob> startCompanyMaster({bool? force}) =>
      caller.callServerEndpoint<_i1paap7y.IngestJob>(
        'ingest',
        'startCompanyMaster',
        {'force': force},
      );

  /// 재무제표 수집 시작. 이미 실행 중이면 그 작업을 돌려준다.
  ///
  /// 공시 목록에서 새 정기보고서를 찾고, 받지 않은 보고서를 최신순으로 받는다.
  /// DART 일일 호출 예산을 다 쓰면 멈추고 다음 날 이어서 받는다.
  /// [corpCode]를 주면 그 기업의 정기보고서만 찾아 바로 받는다. 전체 수집이 돌고 있어도 된다.
  _ida.Future<_i1paap7y.IngestJob> startFinancials({String? corpCode}) =>
      caller.callServerEndpoint<_i1paap7y.IngestJob>(
        'ingest',
        'startFinancials',
        {'corpCode': corpCode},
      );

  /// 정기보고서 주요정보(주주·임원·출자·배당 등 28종) 수집 시작. 이미 실행 중이면 그 작업을 돌려준다.
  ///
  /// 재무 수집이 장부에 넣은 사업보고서의 항목을 최신 사업연도·핵심 항목부터 받는다.
  /// 재무 백필이 남아 있으면 최신 사업연도의 핵심 항목만 받는다.
  /// [corpCode]를 주면 그 기업의 사업보고서 항목만 바로 받는다.
  _ida.Future<_i1paap7y.IngestJob> startDisclosures({String? corpCode}) =>
      caller.callServerEndpoint<_i1paap7y.IngestJob>(
        'ingest',
        'startDisclosures',
        {'corpCode': corpCode},
      );

  /// 주요정보의 인물 연결과 관계 색인을 다시 만든다 (DART 호출 없음). 연결 규칙을 고친 뒤 쓴다.
  _ida.Future<String> rebuildDisclosureLinks() =>
      caller.callServerEndpoint<String>(
        'ingest',
        'rebuildDisclosureLinks',
        {},
      );

  /// 시세 수집 시작. 이미 실행 중이면 그 작업을 돌려준다.
  ///
  /// 받지 않은 평일 기준일을 최신순으로 받고(처음에는 5년), 가장 최근 기준일의
  /// 상장종목 정보로 종목을 기업에 잇는다.
  _ida.Future<_i1paap7y.IngestJob> startMarketSnapshot() =>
      caller.callServerEndpoint<_i1paap7y.IngestJob>(
        'ingest',
        'startMarketSnapshot',
        {},
      );

  _ida.Future<_i1paap7y.IngestJob?> cancel(int jobId) =>
      caller.callServerEndpoint<_i1paap7y.IngestJob?>(
        'ingest',
        'cancel',
        {'jobId': jobId},
      );

  /// 수집 현황. 층마다 얼마나 받았는지 한 번에 센다.
  _ida.Future<_i2drq233.IngestCoverage> coverage() =>
      caller.callServerEndpoint<_i2drq233.IngestCoverage>(
        'ingest',
        'coverage',
        {},
      );

  _ida.Future<_i1paap7y.IngestJob?> latest() =>
      caller.callServerEndpoint<_i1paap7y.IngestJob?>(
        'ingest',
        'latest',
        {},
      );

  /// [kind]의 최근 작업 (`company_master`, `financial_facts`, `market_snapshot`, `disclosures` …).
  _ida.Future<_i1paap7y.IngestJob?> latestOf(String kind) =>
      caller.callServerEndpoint<_i1paap7y.IngestJob?>(
        'ingest',
        'latestOf',
        {'kind': kind},
      );

  /// 여러 종류의 마지막 작업을 한 번에. 앱이 15초마다 부르므로 왕복을 한 번으로 줄인다.
  /// 없는 종류는 빠지므로 `kind`로 맞춰 읽는다.
  _ida.Future<List<_i1paap7y.IngestJob>> latestOfKinds(List<String> kinds) =>
      caller.callServerEndpoint<List<_i1paap7y.IngestJob>>(
        'ingest',
        'latestOfKinds',
        {'kinds': kinds},
      );

  /// 이미 받아 둔 본문에서 생산능력·생산실적·가동률 표를 다시 읽는다 (호출 없음).
  ///
  /// 규칙을 고친 뒤 되돌려 읽을 때 쓴다. 사람이 이미 결정한 항목은 건드리지 않는다.
  _ida.Future<String> rebuildProductionFacts() =>
      caller.callServerEndpoint<String>(
        'ingest',
        'rebuildProductionFacts',
        {},
      );
}

/// 시세 조회.
/// {@category Endpoint}
class EndpointMarket extends _isc.EndpointRef {
  EndpointMarket(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'market';

  /// 가장 최근 기준일의 업종별 시가총액.
  ///
  /// 기업 시가총액은 기업에 연결된 종목(보통주·우선주 등) 시가총액의 합이다.
  /// [sectionCode]가 없으면 대분류 → 그 안 시가총액 상위 기업, 있으면 그 대분류의
  /// 중분류 → 기업으로 묶는다. 화면에 다 그릴 수 없어 대분류마다 [_topCompanies]개까지만 보낸다.
  _ida.Future<_ifex1fnm.MarketCapTreemap> industryTreemap({
    String? sectionCode,
    _iamn97sz.Market? market,
  }) => caller.callServerEndpoint<_ifex1fnm.MarketCapTreemap>(
    'market',
    'industryTreemap',
    {
      'sectionCode': sectionCode,
      'market': market,
    },
  );
}

/// AI 관계 검수 큐: 근거 인용을 보고 승인(verified)·거절(rejected)한다.
/// {@category Endpoint}
class EndpointReview extends _isc.EndpointRef {
  EndpointReview(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'review';

  _ida.Future<_i59ekwm6.ReviewPage> list({
    _ixp2yk27.RelationStatus? status,
    _iklpi3wo.RelationPredicate? predicate,
    int? offset,
    int? limit,
  }) => caller.callServerEndpoint<_i59ekwm6.ReviewPage>(
    'review',
    'list',
    {
      'status': status,
      'predicate': predicate,
      'offset': offset,
      'limit': limit,
    },
  );

  /// 승인하면 verified, 거절하면 rejected. 다시 추출해도 이 결정은 유지된다.
  _ida.Future<_isup83mn.OntologyRelation?> decide(
    int relationId,
    bool approve, {
    String? by,
  }) => caller.callServerEndpoint<_isup83mn.OntologyRelation?>(
    'review',
    'decide',
    {
      'relationId': relationId,
      'approve': approve,
      'by': by,
    },
  );

  /// 여러 건을 한 번에. 원문과 대조한 결과를 넣을 때 쓴다.
  _ida.Future<int> decideMany(
    List<int> relationIds,
    bool approve, {
    String? by,
  }) => caller.callServerEndpoint<int>(
    'review',
    'decideMany',
    {
      'relationIds': relationIds,
      'approve': approve,
      'by': by,
    },
  );

  /// 값도 여러 건을 한 번에.
  _ida.Future<int> decideFactsMany(
    List<int> factIds,
    bool approve, {
    String? by,
  }) => caller.callServerEndpoint<int>(
    'review',
    'decideFactsMany',
    {
      'factIds': factIds,
      'approve': approve,
      'by': by,
    },
  );

  /// 대조 검수 기록을 남긴다 (정확률을 숫자로).
  _ida.Future<_ixhvmecn.ReviewCheck> recordCheck(
    String scope,
    int checked,
    int correct,
    int leftToPerson,
    String checkedBy, {
    String? note,
  }) => caller.callServerEndpoint<_ixhvmecn.ReviewCheck>(
    'review',
    'recordCheck',
    {
      'scope': scope,
      'checked': checked,
      'correct': correct,
      'leftToPerson': leftToPerson,
      'checkedBy': checkedBy,
      'note': note,
    },
  );

  /// 남겨 둔 대조 검수 기록 (최근 것부터).
  _ida.Future<List<_ixhvmecn.ReviewCheck>> checks() =>
      caller.callServerEndpoint<List<_ixhvmecn.ReviewCheck>>(
        'review',
        'checks',
        {},
      );

  /// 본문에서 뽑은 값 검수 목록 (수주잔고·가동률·점유율 등).
  _ida.Future<_i9n1o9ln.FactPage> facts({
    _ixp2yk27.RelationStatus? status,
    _i7h2wu58.DocumentFactKind? kind,
    int? offset,
    int? limit,
  }) => caller.callServerEndpoint<_i9n1o9ln.FactPage>(
    'review',
    'facts',
    {
      'status': status,
      'kind': kind,
      'offset': offset,
      'limit': limit,
    },
  );

  /// 값 하나를 승인·거절한다.
  _ida.Future<_ip7x5uw8.DocumentFact?> decideFact(
    int factId,
    bool approve, {
    String? by,
  }) => caller.callServerEndpoint<_ip7x5uw8.DocumentFact?>(
    'review',
    'decideFact',
    {
      'factId': factId,
      'approve': approve,
      'by': by,
    },
  );

  /// 기업이 주어나 목적어인 AI 관계 (거절한 것 제외).
  _ida.Future<List<_ihqozc6p.ReviewItem>> forCompany(String corpCode) =>
      caller.callServerEndpoint<List<_ihqozc6p.ReviewItem>>(
        'review',
        'forCompany',
        {'corpCode': corpCode},
      );
}

/// 재무·시세로 기업을 거르는 스크리닝.
///
/// 지표(PER·PBR·ROE·영업이익률)는 저장하지 않는다. 최근 12개월(TTM) 원천 값과 최근
/// 시가총액으로 계산하고, 계산에 쓴 값도 같이 돌려준다. 기업 화면의 지표와 같은 기준이다.
///
/// 전 상장사를 한 번 계산해 두고(데이터가 바뀌면 다시), 거르기·정렬은 메모리에서 한다.
/// {@category Endpoint}
class EndpointScreen extends _isc.EndpointRef {
  EndpointScreen(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'screen';

  /// 조건에 맞는 기업. 값이 없는 기업(적자·자본잠식 등)은 그 지표 조건이 있으면 빠진다.
  _ida.Future<_iy3d4gdi.ScreenPage> list({
    List<String>? corpCodes,
    _iamn97sz.Market? market,
    String? sectionCode,
    double? perMax,
    double? pbrMax,
    double? roeMin,
    double? operatingMarginMin,
    double? revenueGrowthMin,
    double? operatingIncomeGrowthMin,
    double? debtRatioMax,
    double? dividendYieldMin,
    double? fcfYieldMin,
    BigInt? marketCapMin,
    _iswpkxoo.ScreenSort? sort,
    bool? ascending,
    int? offset,
    int? limit,
  }) => caller.callServerEndpoint<_iy3d4gdi.ScreenPage>(
    'screen',
    'list',
    {
      'corpCodes': corpCodes,
      'market': market,
      'sectionCode': sectionCode,
      'perMax': perMax,
      'pbrMax': pbrMax,
      'roeMin': roeMin,
      'operatingMarginMin': operatingMarginMin,
      'revenueGrowthMin': revenueGrowthMin,
      'operatingIncomeGrowthMin': operatingIncomeGrowthMin,
      'debtRatioMax': debtRatioMax,
      'dividendYieldMin': dividendYieldMin,
      'fcfYieldMin': fcfYieldMin,
      'marketCapMin': marketCapMin,
      'sort': sort,
      'ascending': ascending,
      'offset': offset,
      'limit': limit,
    },
  );

  /// 같은 업종 기업들과의 비교. 업종은 값이 있는 기업이 다섯 곳은 되도록
  /// 세분류 → 중분류 → 대분류 순으로 넓혀 잡는다.
  _ida.Future<_izfg2hmi.PeerComparison?> peers(String corpCode) =>
      caller.callServerEndpoint<_izfg2hmi.PeerComparison?>(
        'screen',
        'peers',
        {'corpCode': corpCode},
      );
}

/// 테마 (5단계): 사용자가 정의하는 투자 주제와 기업 편입.
///
/// 편입은 사람의 판단이므로 출처는 manual Source로 남긴다.
/// {@category Endpoint}
class EndpointTheme extends _isc.EndpointRef {
  EndpointTheme(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'theme';

  /// 테마 목록. 편입 기업 시가총액이 큰 순서.
  _ida.Future<List<_ihj01hrs.ThemeSummary>> list() =>
      caller.callServerEndpoint<List<_ihj01hrs.ThemeSummary>>(
        'theme',
        'list',
        {},
      );

  _ida.Future<_izhmhfon.InvestmentTheme> create(
    String name, {
    String? description,
  }) => caller.callServerEndpoint<_izhmhfon.InvestmentTheme>(
    'theme',
    'create',
    {
      'name': name,
      'description': description,
    },
  );

  _ida.Future<_izhmhfon.InvestmentTheme?> update(
    int themeId,
    String name, {
    String? description,
  }) => caller.callServerEndpoint<_izhmhfon.InvestmentTheme?>(
    'theme',
    'update',
    {
      'themeId': themeId,
      'name': name,
      'description': description,
    },
  );

  /// 테마를 지운다 (편입 기록도 함께). 사용자가 만든 것이라 지울 수 있다.
  _ida.Future<void> delete(int themeId) => caller.callServerEndpoint<void>(
    'theme',
    'delete',
    {'themeId': themeId},
  );

  /// 테마와 편입 기업 (시가총액 큰 순서).
  _ida.Future<_is8fq5gm.ThemeDetail?> detail(int themeId) =>
      caller.callServerEndpoint<_is8fq5gm.ThemeDetail?>(
        'theme',
        'detail',
        {'themeId': themeId},
      );

  /// 기업을 테마에 넣는다. 이미 있으면 메모만 고친다.
  _ida.Future<_i33gd2p5.ThemeMember?> addCompany(
    int themeId,
    String corpCode, {
    String? note,
  }) => caller.callServerEndpoint<_i33gd2p5.ThemeMember?>(
    'theme',
    'addCompany',
    {
      'themeId': themeId,
      'corpCode': corpCode,
      'note': note,
    },
  );

  _ida.Future<void> removeCompany(
    int themeId,
    String corpCode,
  ) => caller.callServerEndpoint<void>(
    'theme',
    'removeCompany',
    {
      'themeId': themeId,
      'corpCode': corpCode,
    },
  );

  /// 기업이 속한 테마.
  _ida.Future<List<_izhmhfon.InvestmentTheme>> themesOf(String corpCode) =>
      caller.callServerEndpoint<List<_izhmhfon.InvestmentTheme>>(
        'theme',
        'themesOf',
        {'corpCode': corpCode},
      );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_idp = _iaic.Caller(client);
    serverpod_auth_core = _iacc.Caller(client);
  }

  late final _iaic.Caller serverpod_auth_idp;

  late final _iacc.Caller serverpod_auth_core;
}

class Client extends _isc.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _isc.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_isc.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
    _i85jenna.Client? httpClientOverride,
  }) : super(
         host,
         _il2as5qe.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
         httpClientOverride: httpClientOverride,
       ) {
    emailIdp = EndpointEmailIdp(this);
    jwtRefresh = EndpointJwtRefresh(this);
    greeting = EndpointGreeting(this);
    ai = EndpointAi(this);
    company = EndpointCompany(this);
    disclosure = EndpointDisclosure(this);
    financial = EndpointFinancial(this);
    governance = EndpointGovernance(this);
    graph = EndpointGraph(this);
    group = EndpointGroup(this);
    ingest = EndpointIngest(this);
    market = EndpointMarket(this);
    review = EndpointReview(this);
    screen = EndpointScreen(this);
    theme = EndpointTheme(this);
    modules = Modules(this);
  }

  late final EndpointEmailIdp emailIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointGreeting greeting;

  late final EndpointAi ai;

  late final EndpointCompany company;

  late final EndpointDisclosure disclosure;

  late final EndpointFinancial financial;

  late final EndpointGovernance governance;

  late final EndpointGraph graph;

  late final EndpointGroup group;

  late final EndpointIngest ingest;

  late final EndpointMarket market;

  late final EndpointReview review;

  late final EndpointScreen screen;

  late final EndpointTheme theme;

  late final Modules modules;

  @override
  Map<String, _isc.EndpointRef> get endpointRefLookup => {
    'emailIdp': emailIdp,
    'jwtRefresh': jwtRefresh,
    'greeting': greeting,
    'ai': ai,
    'company': company,
    'disclosure': disclosure,
    'financial': financial,
    'governance': governance,
    'graph': graph,
    'group': group,
    'ingest': ingest,
    'market': market,
    'review': review,
    'screen': screen,
    'theme': theme,
  };

  @override
  Map<String, _isc.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };
}
