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
import 'package:investment_ontology_serverpod_server/src/generated/future_calls.dart'
    as _i4o8e4lj;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/company_sort.dart'
    as _iosqhah1;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/dart_section.dart'
    as _i6h8j7tv;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/document_fact_kind.dart'
    as _i1rhjzgf;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/fs_div.dart'
    as _i69nddnn;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/market.dart'
    as _iyonaxpd;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/relation_predicate.dart'
    as _iw7mt1ku;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/relation_status.dart'
    as _iy39k7od;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/screen_sort.dart'
    as _i9blzem0;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _iais;
import '../auth/email_idp_endpoint.dart' as _iuc1hd5t;
import '../auth/jwt_refresh_endpoint.dart' as _inwq3ztq;
import '../greetings/greeting_endpoint.dart' as _il624ik7;
import '../ontology/endpoints/account_endpoint.dart' as _io2i71g8;
import '../ontology/endpoints/ai_endpoint.dart' as _iadofkda;
import '../ontology/endpoints/bond_endpoint.dart' as _iuax3zj5;
import '../ontology/endpoints/capital_endpoint.dart' as _idxbctvq;
import '../ontology/endpoints/company_endpoint.dart' as _itnisr3u;
import '../ontology/endpoints/company_news_endpoint.dart' as _ij4mm9jr;
import '../ontology/endpoints/company_research_endpoint.dart' as _iqx60vuh;
import '../ontology/endpoints/disclosure_endpoint.dart' as _i23b9rs7;
import '../ontology/endpoints/financial_endpoint.dart' as _ipit2z9y;
import '../ontology/endpoints/governance_endpoint.dart' as _i6kw8hva;
import '../ontology/endpoints/graph_endpoint.dart' as _ixdq71x8;
import '../ontology/endpoints/group_endpoint.dart' as _i8zm50hy;
import '../ontology/endpoints/industry_endpoint.dart' as _ihimn963;
import '../ontology/endpoints/ingest_endpoint.dart' as _icbircc0;
import '../ontology/endpoints/macro_endpoint.dart' as _ii38wwy2;
import '../ontology/endpoints/market_endpoint.dart' as _iaw7fzks;
import '../ontology/endpoints/membership_endpoint.dart' as _i4hwwhem;
import '../ontology/endpoints/membership_offer_endpoint.dart' as _ilgl7tj9;
import '../ontology/endpoints/review_endpoint.dart' as _i9uttt4a;
import '../ontology/endpoints/screen_endpoint.dart' as _ilgabfhk;
import '../ontology/endpoints/theme_endpoint.dart' as _iqaca509;
import '../ontology/endpoints/watchlist_endpoint.dart' as _ia3gawxy;
export 'future_calls.dart' show ServerpodFutureCallsGetter;

class Endpoints extends _is.EndpointDispatch {
  @override
  void initializeEndpoints(_is.Server server) {
    var endpoints = <String, _is.Endpoint>{
      'emailIdp': _iuc1hd5t.EmailIdpEndpoint()
        ..initialize(
          server,
          'emailIdp',
          null,
        ),
      'jwtRefresh': _inwq3ztq.JwtRefreshEndpoint()
        ..initialize(
          server,
          'jwtRefresh',
          null,
        ),
      'greeting': _il624ik7.GreetingEndpoint()
        ..initialize(
          server,
          'greeting',
          null,
        ),
      'account': _io2i71g8.AccountEndpoint()
        ..initialize(
          server,
          'account',
          null,
        ),
      'ai': _iadofkda.AiEndpoint()
        ..initialize(
          server,
          'ai',
          null,
        ),
      'bond': _iuax3zj5.BondEndpoint()
        ..initialize(
          server,
          'bond',
          null,
        ),
      'capital': _idxbctvq.CapitalEndpoint()
        ..initialize(
          server,
          'capital',
          null,
        ),
      'company': _itnisr3u.CompanyEndpoint()
        ..initialize(
          server,
          'company',
          null,
        ),
      'companyNews': _ij4mm9jr.CompanyNewsEndpoint()
        ..initialize(
          server,
          'companyNews',
          null,
        ),
      'research': _iqx60vuh.ResearchEndpoint()
        ..initialize(
          server,
          'research',
          null,
        ),
      'disclosure': _i23b9rs7.DisclosureEndpoint()
        ..initialize(
          server,
          'disclosure',
          null,
        ),
      'financial': _ipit2z9y.FinancialEndpoint()
        ..initialize(
          server,
          'financial',
          null,
        ),
      'governance': _i6kw8hva.GovernanceEndpoint()
        ..initialize(
          server,
          'governance',
          null,
        ),
      'graph': _ixdq71x8.GraphEndpoint()
        ..initialize(
          server,
          'graph',
          null,
        ),
      'group': _i8zm50hy.GroupEndpoint()
        ..initialize(
          server,
          'group',
          null,
        ),
      'industry': _ihimn963.IndustryEndpoint()
        ..initialize(
          server,
          'industry',
          null,
        ),
      'ingest': _icbircc0.IngestEndpoint()
        ..initialize(
          server,
          'ingest',
          null,
        ),
      'macro': _ii38wwy2.MacroEndpoint()
        ..initialize(
          server,
          'macro',
          null,
        ),
      'market': _iaw7fzks.MarketEndpoint()
        ..initialize(
          server,
          'market',
          null,
        ),
      'membership': _i4hwwhem.MembershipEndpoint()
        ..initialize(
          server,
          'membership',
          null,
        ),
      'membershipOffer': _ilgl7tj9.MembershipOfferEndpoint()
        ..initialize(
          server,
          'membershipOffer',
          null,
        ),
      'review': _i9uttt4a.ReviewEndpoint()
        ..initialize(
          server,
          'review',
          null,
        ),
      'screen': _ilgabfhk.ScreenEndpoint()
        ..initialize(
          server,
          'screen',
          null,
        ),
      'theme': _iqaca509.ThemeEndpoint()
        ..initialize(
          server,
          'theme',
          null,
        ),
      'watchlist': _ia3gawxy.WatchlistEndpoint()
        ..initialize(
          server,
          'watchlist',
          null,
        ),
    };
    connectors['emailIdp'] = _is.EndpointConnector(
      name: 'emailIdp',
      endpoint: endpoints['emailIdp']!,
      methodConnectors: {
        'login': _is.MethodConnector(
          name: 'login',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint).login(
                    session,
                    email: params['email'],
                    password: params['password'],
                  ),
        ),
        'startRegistration': _is.MethodConnector(
          name: 'startRegistration',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .startRegistration(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyRegistrationCode': _is.MethodConnector(
          name: 'verifyRegistrationCode',
          params: {
            'accountRequestId': _is.ParameterDescription(
              name: 'accountRequestId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _is.ParameterDescription(
              name: 'verificationCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .verifyRegistrationCode(
                    session,
                    accountRequestId: params['accountRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishRegistration': _is.MethodConnector(
          name: 'finishRegistration',
          params: {
            'registrationToken': _is.ParameterDescription(
              name: 'registrationToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .finishRegistration(
                    session,
                    registrationToken: params['registrationToken'],
                    password: params['password'],
                  ),
        ),
        'startPasswordReset': _is.MethodConnector(
          name: 'startPasswordReset',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .startPasswordReset(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyPasswordResetCode': _is.MethodConnector(
          name: 'verifyPasswordResetCode',
          params: {
            'passwordResetRequestId': _is.ParameterDescription(
              name: 'passwordResetRequestId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _is.ParameterDescription(
              name: 'verificationCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .verifyPasswordResetCode(
                    session,
                    passwordResetRequestId: params['passwordResetRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishPasswordReset': _is.MethodConnector(
          name: 'finishPasswordReset',
          params: {
            'finishPasswordResetToken': _is.ParameterDescription(
              name: 'finishPasswordResetToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'newPassword': _is.ParameterDescription(
              name: 'newPassword',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .finishPasswordReset(
                    session,
                    finishPasswordResetToken:
                        params['finishPasswordResetToken'],
                    newPassword: params['newPassword'],
                  ),
        ),
        'hasAccount': _is.MethodConnector(
          name: 'hasAccount',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .hasAccount(session),
        ),
      },
    );
    connectors['jwtRefresh'] = _is.EndpointConnector(
      name: 'jwtRefresh',
      endpoint: endpoints['jwtRefresh']!,
      methodConnectors: {
        'refreshAccessToken': _is.MethodConnector(
          name: 'refreshAccessToken',
          params: {
            'refreshToken': _is.ParameterDescription(
              name: 'refreshToken',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['jwtRefresh'] as _inwq3ztq.JwtRefreshEndpoint)
                      .refreshAccessToken(
                        session,
                        refreshToken: params['refreshToken'],
                      ),
        ),
      },
    );
    connectors['greeting'] = _is.EndpointConnector(
      name: 'greeting',
      endpoint: endpoints['greeting']!,
      methodConnectors: {
        'hello': _is.MethodConnector(
          name: 'hello',
          params: {
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['greeting'] as _il624ik7.GreetingEndpoint).hello(
                    session,
                    params['name'],
                  ),
        ),
      },
    );
    connectors['account'] = _is.EndpointConnector(
      name: 'account',
      endpoint: endpoints['account']!,
      methodConnectors: {
        'mailConfigured': _is.MethodConnector(
          name: 'mailConfigured',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['account'] as _io2i71g8.AccountEndpoint)
                  .mailConfigured(session),
        ),
        'me': _is.MethodConnector(
          name: 'me',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['account'] as _io2i71g8.AccountEndpoint).me(
                session,
              ),
        ),
        'list': _is.MethodConnector(
          name: 'list',
          params: {
            'offset': _is.ParameterDescription(
              name: 'offset',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['account'] as _io2i71g8.AccountEndpoint).list(
                    session,
                    offset: params['offset'],
                  ),
        ),
        'updateAccess': _is.MethodConnector(
          name: 'updateAccess',
          params: {
            'userId': _is.ParameterDescription(
              name: 'userId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'isAdmin': _is.ParameterDescription(
              name: 'isAdmin',
              type: _is.getType<bool>(),
              nullable: false,
            ),
            'blocked': _is.ParameterDescription(
              name: 'blocked',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['account'] as _io2i71g8.AccountEndpoint)
                  .updateAccess(
                    session,
                    params['userId'],
                    isAdmin: params['isAdmin'],
                    blocked: params['blocked'],
                  ),
        ),
        'revokeSessions': _is.MethodConnector(
          name: 'revokeSessions',
          params: {
            'userId': _is.ParameterDescription(
              name: 'userId',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['account'] as _io2i71g8.AccountEndpoint)
                  .revokeSessions(
                    session,
                    userId: params['userId'],
                  ),
        ),
        'deleteMe': _is.MethodConnector(
          name: 'deleteMe',
          params: {
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['account'] as _io2i71g8.AccountEndpoint).deleteMe(
                    session,
                    params['password'],
                  ),
        ),
      },
    );
    connectors['ai'] = _is.EndpointConnector(
      name: 'ai',
      endpoint: endpoints['ai']!,
      methodConnectors: {
        'status': _is.MethodConnector(
          name: 'status',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['ai'] as _iadofkda.AiEndpoint).status(session),
        ),
        'extractCompany': _is.MethodConnector(
          name: 'extractCompany',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['ai'] as _iadofkda.AiEndpoint).extractCompany(
                    session,
                    params['corpCode'],
                  ),
        ),
        'startBatch': _is.MethodConnector(
          name: 'startBatch',
          params: {
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ai'] as _iadofkda.AiEndpoint).startBatch(
                session,
                limit: params['limit'],
              ),
        ),
        'pending': _is.MethodConnector(
          name: 'pending',
          params: {
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ai'] as _iadofkda.AiEndpoint).pending(
                session,
                limit: params['limit'],
              ),
        ),
        'documentText': _is.MethodConnector(
          name: 'documentText',
          params: {
            'documentId': _is.ParameterDescription(
              name: 'documentId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'maxChars': _is.ParameterDescription(
              name: 'maxChars',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ai'] as _iadofkda.AiEndpoint).documentText(
                session,
                params['documentId'],
                maxChars: params['maxChars'],
              ),
        ),
        'documentTexts': _is.MethodConnector(
          name: 'documentTexts',
          params: {
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int?>(),
              nullable: true,
            ),
            'maxChars': _is.ParameterDescription(
              name: 'maxChars',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['ai'] as _iadofkda.AiEndpoint).documentTexts(
                    session,
                    limit: params['limit'],
                    maxChars: params['maxChars'],
                  ),
        ),
        'submit': _is.MethodConnector(
          name: 'submit',
          params: {
            'documentId': _is.ParameterDescription(
              name: 'documentId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'answer': _is.ParameterDescription(
              name: 'answer',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'model': _is.ParameterDescription(
              name: 'model',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ai'] as _iadofkda.AiEndpoint).submit(
                session,
                params['documentId'],
                params['answer'],
                model: params['model'],
              ),
        ),
        'submitDigest': _is.MethodConnector(
          name: 'submitDigest',
          params: {
            'documentId': _is.ParameterDescription(
              name: 'documentId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'answer': _is.ParameterDescription(
              name: 'answer',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'model': _is.ParameterDescription(
              name: 'model',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ai'] as _iadofkda.AiEndpoint).submitDigest(
                session,
                params['documentId'],
                params['answer'],
                model: params['model'],
              ),
        ),
        'submitFacts': _is.MethodConnector(
          name: 'submitFacts',
          params: {
            'documentId': _is.ParameterDescription(
              name: 'documentId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'answer': _is.ParameterDescription(
              name: 'answer',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'model': _is.ParameterDescription(
              name: 'model',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ai'] as _iadofkda.AiEndpoint).submitFacts(
                session,
                params['documentId'],
                params['answer'],
                model: params['model'],
              ),
        ),
      },
    );
    connectors['bond'] = _is.EndpointConnector(
      name: 'bond',
      endpoint: endpoints['bond']!,
      methodConnectors: {
        'trends': _is.MethodConnector(
          name: 'trends',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['bond'] as _iuax3zj5.BondEndpoint).trends(
                session,
                params['corpCode'],
              ),
        ),
        'collect': _is.MethodConnector(
          name: 'collect',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['bond'] as _iuax3zj5.BondEndpoint).collect(
                session,
                params['corpCode'],
              ),
        ),
      },
    );
    connectors['capital'] = _is.EndpointConnector(
      name: 'capital',
      endpoint: endpoints['capital']!,
      methodConnectors: {
        'summary': _is.MethodConnector(
          name: 'summary',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['capital'] as _idxbctvq.CapitalEndpoint).summary(
                    session,
                    params['corpCode'],
                  ),
        ),
        'collect': _is.MethodConnector(
          name: 'collect',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['capital'] as _idxbctvq.CapitalEndpoint).collect(
                    session,
                    params['corpCode'],
                  ),
        ),
      },
    );
    connectors['company'] = _is.EndpointConnector(
      name: 'company',
      endpoint: endpoints['company']!,
      methodConnectors: {
        'overview': _is.MethodConnector(
          name: 'overview',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['company'] as _itnisr3u.CompanyEndpoint)
                  .overview(session),
        ),
        'divisions': _is.MethodConnector(
          name: 'divisions',
          params: {
            'sectionCode': _is.ParameterDescription(
              name: 'sectionCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'market': _is.ParameterDescription(
              name: 'market',
              type: _is.getType<_iyonaxpd.Market?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['company'] as _itnisr3u.CompanyEndpoint).divisions(
                    session,
                    params['sectionCode'],
                    market: params['market'],
                  ),
        ),
        'list': _is.MethodConnector(
          name: 'list',
          params: {
            'query': _is.ParameterDescription(
              name: 'query',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'market': _is.ParameterDescription(
              name: 'market',
              type: _is.getType<_iyonaxpd.Market?>(),
              nullable: true,
            ),
            'sectionCode': _is.ParameterDescription(
              name: 'sectionCode',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'divisionCode': _is.ParameterDescription(
              name: 'divisionCode',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'sort': _is.ParameterDescription(
              name: 'sort',
              type: _is.getType<_iosqhah1.CompanySort?>(),
              nullable: true,
            ),
            'offset': _is.ParameterDescription(
              name: 'offset',
              type: _is.getType<int?>(),
              nullable: true,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['company'] as _itnisr3u.CompanyEndpoint).list(
                    session,
                    query: params['query'],
                    market: params['market'],
                    sectionCode: params['sectionCode'],
                    divisionCode: params['divisionCode'],
                    sort: params['sort'],
                    offset: params['offset'],
                    limit: params['limit'],
                  ),
        ),
        'detail': _is.MethodConnector(
          name: 'detail',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['company'] as _itnisr3u.CompanyEndpoint).detail(
                    session,
                    params['corpCode'],
                  ),
        ),
      },
    );
    connectors['companyNews'] = _is.EndpointConnector(
      name: 'companyNews',
      endpoint: endpoints['companyNews']!,
      methodConnectors: {
        'recent': _is.MethodConnector(
          name: 'recent',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['companyNews'] as _ij4mm9jr.CompanyNewsEndpoint)
                      .recent(
                        session,
                        params['corpCode'],
                      ),
        ),
      },
    );
    connectors['research'] = _is.EndpointConnector(
      name: 'research',
      endpoint: endpoints['research']!,
      methodConnectors: {
        'data': _is.MethodConnector(
          name: 'data',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'kind': _is.ParameterDescription(
              name: 'kind',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['research'] as _iqx60vuh.ResearchEndpoint).data(
                    session,
                    params['corpCode'],
                    params['kind'],
                  ),
        ),
        'preview': _is.MethodConnector(
          name: 'preview',
          params: {
            'kind': _is.ParameterDescription(
              name: 'kind',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'payload': _is.ParameterDescription(
              name: 'payload',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['research'] as _iqx60vuh.ResearchEndpoint).preview(
                    session,
                    params['kind'],
                    params['payload'],
                  ),
        ),
        'importFeed': _is.MethodConnector(
          name: 'importFeed',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'kind': _is.ParameterDescription(
              name: 'kind',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'payload': _is.ParameterDescription(
              name: 'payload',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'provider': _is.ParameterDescription(
              name: 'provider',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'sourceUrl': _is.ParameterDescription(
              name: 'sourceUrl',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'rightsReference': _is.ParameterDescription(
              name: 'rightsReference',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['research'] as _iqx60vuh.ResearchEndpoint)
                  .importFeed(
                    session,
                    params['corpCode'],
                    params['kind'],
                    params['payload'],
                    params['provider'],
                    params['sourceUrl'],
                    params['rightsReference'],
                  ),
        ),
        'collectBatch': _is.MethodConnector(
          name: 'collectBatch',
          params: {
            'kind': _is.ParameterDescription(
              name: 'kind',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'afterCorpCode': _is.ParameterDescription(
              name: 'afterCorpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['research'] as _iqx60vuh.ResearchEndpoint)
                  .collectBatch(
                    session,
                    params['kind'],
                    afterCorpCode: params['afterCorpCode'],
                    limit: params['limit'],
                  ),
        ),
        'connectionStatus': _is.MethodConnector(
          name: 'connectionStatus',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['research'] as _iqx60vuh.ResearchEndpoint)
                  .connectionStatus(session),
        ),
        'collect': _is.MethodConnector(
          name: 'collect',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'kind': _is.ParameterDescription(
              name: 'kind',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['research'] as _iqx60vuh.ResearchEndpoint).collect(
                    session,
                    params['corpCode'],
                    params['kind'],
                  ),
        ),
      },
    );
    connectors['disclosure'] = _is.EndpointConnector(
      name: 'disclosure',
      endpoint: endpoints['disclosure']!,
      methodConnectors: {
        'understanding': _is.MethodConnector(
          name: 'understanding',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['disclosure'] as _i23b9rs7.DisclosureEndpoint)
                      .understanding(
                        session,
                        params['corpCode'],
                      ),
        ),
        'sections': _is.MethodConnector(
          name: 'sections',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['disclosure'] as _i23b9rs7.DisclosureEndpoint)
                      .sections(
                        session,
                        params['corpCode'],
                      ),
        ),
        'table': _is.MethodConnector(
          name: 'table',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'section': _is.ParameterDescription(
              name: 'section',
              type: _is.getType<_i6h8j7tv.DartSection>(),
              nullable: false,
            ),
            'bsnsYear': _is.ParameterDescription(
              name: 'bsnsYear',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['disclosure'] as _i23b9rs7.DisclosureEndpoint)
                      .table(
                        session,
                        params['corpCode'],
                        params['section'],
                        bsnsYear: params['bsnsYear'],
                      ),
        ),
        'businessContent': _is.MethodConnector(
          name: 'businessContent',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'bsnsYear': _is.ParameterDescription(
              name: 'bsnsYear',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['disclosure'] as _i23b9rs7.DisclosureEndpoint)
                      .businessContent(
                        session,
                        params['corpCode'],
                        bsnsYear: params['bsnsYear'],
                      ),
        ),
        'shareholderReturn': _is.MethodConnector(
          name: 'shareholderReturn',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['disclosure'] as _i23b9rs7.DisclosureEndpoint)
                      .shareholderReturn(
                        session,
                        params['corpCode'],
                      ),
        ),
        'facts': _is.MethodConnector(
          name: 'facts',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['disclosure'] as _i23b9rs7.DisclosureEndpoint)
                      .facts(
                        session,
                        params['corpCode'],
                      ),
        ),
        'factPeriods': _is.MethodConnector(
          name: 'factPeriods',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['disclosure'] as _i23b9rs7.DisclosureEndpoint)
                      .factPeriods(
                        session,
                        params['corpCode'],
                      ),
        ),
        'factTrends': _is.MethodConnector(
          name: 'factTrends',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['disclosure'] as _i23b9rs7.DisclosureEndpoint)
                      .factTrends(
                        session,
                        params['corpCode'],
                      ),
        ),
        'recentOf': _is.MethodConnector(
          name: 'recentOf',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['disclosure'] as _i23b9rs7.DisclosureEndpoint)
                      .recentOf(
                        session,
                        params['corpCode'],
                        limit: params['limit'],
                      ),
        ),
        'digest': _is.MethodConnector(
          name: 'digest',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'bsnsYear': _is.ParameterDescription(
              name: 'bsnsYear',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['disclosure'] as _i23b9rs7.DisclosureEndpoint)
                      .digest(
                        session,
                        params['corpCode'],
                        bsnsYear: params['bsnsYear'],
                      ),
        ),
        'recentFilings': _is.MethodConnector(
          name: 'recentFilings',
          params: {
            'market': _is.ParameterDescription(
              name: 'market',
              type: _is.getType<_iyonaxpd.Market?>(),
              nullable: true,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['disclosure'] as _i23b9rs7.DisclosureEndpoint)
                      .recentFilings(
                        session,
                        market: params['market'],
                        limit: params['limit'],
                      ),
        ),
      },
    );
    connectors['financial'] = _is.EndpointConnector(
      name: 'financial',
      endpoint: endpoints['financial']!,
      methodConnectors: {
        'summary': _is.MethodConnector(
          name: 'summary',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'fsDiv': _is.ParameterDescription(
              name: 'fsDiv',
              type: _is.getType<_i69nddnn.FsDiv?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['financial'] as _ipit2z9y.FinancialEndpoint)
                  .summary(
                    session,
                    params['corpCode'],
                    fsDiv: params['fsDiv'],
                  ),
        ),
        'report': _is.MethodConnector(
          name: 'report',
          params: {
            'reportId': _is.ParameterDescription(
              name: 'reportId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['financial'] as _ipit2z9y.FinancialEndpoint)
                  .report(
                    session,
                    params['reportId'],
                  ),
        ),
      },
    );
    connectors['governance'] = _is.EndpointConnector(
      name: 'governance',
      endpoint: endpoints['governance']!,
      methodConnectors: {
        'summary': _is.MethodConnector(
          name: 'summary',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'bsnsYear': _is.ParameterDescription(
              name: 'bsnsYear',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['governance'] as _i6kw8hva.GovernanceEndpoint)
                      .summary(
                        session,
                        params['corpCode'],
                        bsnsYear: params['bsnsYear'],
                      ),
        ),
        'ownershipHistory': _is.MethodConnector(
          name: 'ownershipHistory',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['governance'] as _i6kw8hva.GovernanceEndpoint)
                      .ownershipHistory(
                        session,
                        params['corpCode'],
                      ),
        ),
        'searchPersons': _is.MethodConnector(
          name: 'searchPersons',
          params: {
            'query': _is.ParameterDescription(
              name: 'query',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['governance'] as _i6kw8hva.GovernanceEndpoint)
                      .searchPersons(
                        session,
                        params['query'],
                        limit: params['limit'],
                      ),
        ),
        'person': _is.MethodConnector(
          name: 'person',
          params: {
            'personId': _is.ParameterDescription(
              name: 'personId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['governance'] as _i6kw8hva.GovernanceEndpoint)
                      .person(
                        session,
                        params['personId'],
                      ),
        ),
        'rejectPersonLink': _is.MethodConnector(
          name: 'rejectPersonLink',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'holderName': _is.ParameterDescription(
              name: 'holderName',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['governance'] as _i6kw8hva.GovernanceEndpoint)
                      .rejectPersonLink(
                        session,
                        params['corpCode'],
                        params['holderName'],
                      ),
        ),
      },
    );
    connectors['graph'] = _is.EndpointConnector(
      name: 'graph',
      endpoint: endpoints['graph']!,
      methodConnectors: {
        'neighborhood': _is.MethodConnector(
          name: 'neighborhood',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'depth': _is.ParameterDescription(
              name: 'depth',
              type: _is.getType<int?>(),
              nullable: true,
            ),
            'maxNodes': _is.ParameterDescription(
              name: 'maxNodes',
              type: _is.getType<int?>(),
              nullable: true,
            ),
            'includeNames': _is.ParameterDescription(
              name: 'includeNames',
              type: _is.getType<bool?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['graph'] as _ixdq71x8.GraphEndpoint).neighborhood(
                    session,
                    params['corpCode'],
                    depth: params['depth'],
                    maxNodes: params['maxNodes'],
                    includeNames: params['includeNames'],
                  ),
        ),
      },
    );
    connectors['group'] = _is.EndpointConnector(
      name: 'group',
      endpoint: endpoints['group']!,
      methodConnectors: {
        'list': _is.MethodConnector(
          name: 'list',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['group'] as _i8zm50hy.GroupEndpoint).list(session),
        ),
        'of': _is.MethodConnector(
          name: 'of',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['group'] as _i8zm50hy.GroupEndpoint).of(
                session,
                params['corpCode'],
              ),
        ),
      },
    );
    connectors['industry'] = _is.EndpointConnector(
      name: 'industry',
      endpoint: endpoints['industry']!,
      methodConnectors: {
        'browse': _is.MethodConnector(
          name: 'browse',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['industry'] as _ihimn963.IndustryEndpoint)
                  .browse(session),
        ),
        'discover': _is.MethodConnector(
          name: 'discover',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['industry'] as _ihimn963.IndustryEndpoint)
                  .discover(session),
        ),
      },
    );
    connectors['ingest'] = _is.EndpointConnector(
      name: 'ingest',
      endpoint: endpoints['ingest']!,
      methodConnectors: {
        'startCompanyMaster': _is.MethodConnector(
          name: 'startCompanyMaster',
          params: {
            'force': _is.ParameterDescription(
              name: 'force',
              type: _is.getType<bool?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ingest'] as _icbircc0.IngestEndpoint)
                  .startCompanyMaster(
                    session,
                    force: params['force'],
                  ),
        ),
        'startFinancials': _is.MethodConnector(
          name: 'startFinancials',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ingest'] as _icbircc0.IngestEndpoint)
                  .startFinancials(
                    session,
                    corpCode: params['corpCode'],
                  ),
        ),
        'startDisclosures': _is.MethodConnector(
          name: 'startDisclosures',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ingest'] as _icbircc0.IngestEndpoint)
                  .startDisclosures(
                    session,
                    corpCode: params['corpCode'],
                  ),
        ),
        'startBusinessDocuments': _is.MethodConnector(
          name: 'startBusinessDocuments',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ingest'] as _icbircc0.IngestEndpoint)
                  .startBusinessDocuments(session),
        ),
        'rebuildDisclosureLinks': _is.MethodConnector(
          name: 'rebuildDisclosureLinks',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ingest'] as _icbircc0.IngestEndpoint)
                  .rebuildDisclosureLinks(session),
        ),
        'startMarketSnapshot': _is.MethodConnector(
          name: 'startMarketSnapshot',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ingest'] as _icbircc0.IngestEndpoint)
                  .startMarketSnapshot(session),
        ),
        'cancel': _is.MethodConnector(
          name: 'cancel',
          params: {
            'jobId': _is.ParameterDescription(
              name: 'jobId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['ingest'] as _icbircc0.IngestEndpoint).cancel(
                    session,
                    params['jobId'],
                  ),
        ),
        'coverage': _is.MethodConnector(
          name: 'coverage',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ingest'] as _icbircc0.IngestEndpoint)
                  .coverage(session),
        ),
        'latest': _is.MethodConnector(
          name: 'latest',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ingest'] as _icbircc0.IngestEndpoint)
                  .latest(session),
        ),
        'latestOf': _is.MethodConnector(
          name: 'latestOf',
          params: {
            'kind': _is.ParameterDescription(
              name: 'kind',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['ingest'] as _icbircc0.IngestEndpoint).latestOf(
                    session,
                    params['kind'],
                  ),
        ),
        'schedule': _is.MethodConnector(
          name: 'schedule',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ingest'] as _icbircc0.IngestEndpoint)
                  .schedule(session),
        ),
        'latestOfKinds': _is.MethodConnector(
          name: 'latestOfKinds',
          params: {
            'kinds': _is.ParameterDescription(
              name: 'kinds',
              type: _is.getType<List<String>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ingest'] as _icbircc0.IngestEndpoint)
                  .latestOfKinds(
                    session,
                    params['kinds'],
                  ),
        ),
        'rebuildProductionFacts': _is.MethodConnector(
          name: 'rebuildProductionFacts',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ingest'] as _icbircc0.IngestEndpoint)
                  .rebuildProductionFacts(
                    session,
                    corpCode: params['corpCode'],
                  ),
        ),
      },
    );
    connectors['macro'] = _is.EndpointConnector(
      name: 'macro',
      endpoint: endpoints['macro']!,
      methodConnectors: {
        'overview': _is.MethodConnector(
          name: 'overview',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['macro'] as _ii38wwy2.MacroEndpoint)
                  .overview(session),
        ),
      },
    );
    connectors['market'] = _is.EndpointConnector(
      name: 'market',
      endpoint: endpoints['market']!,
      methodConnectors: {
        'companyCapHistory': _is.MethodConnector(
          name: 'companyCapHistory',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'years': _is.ParameterDescription(
              name: 'years',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['market'] as _iaw7fzks.MarketEndpoint)
                  .companyCapHistory(
                    session,
                    params['corpCode'],
                    years: params['years'],
                  ),
        ),
        'industryTreemap': _is.MethodConnector(
          name: 'industryTreemap',
          params: {
            'sectionCode': _is.ParameterDescription(
              name: 'sectionCode',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'market': _is.ParameterDescription(
              name: 'market',
              type: _is.getType<_iyonaxpd.Market?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['market'] as _iaw7fzks.MarketEndpoint)
                  .industryTreemap(
                    session,
                    sectionCode: params['sectionCode'],
                    market: params['market'],
                  ),
        ),
        'capHistory': _is.MethodConnector(
          name: 'capHistory',
          params: {
            'market': _is.ParameterDescription(
              name: 'market',
              type: _is.getType<_iyonaxpd.Market?>(),
              nullable: true,
            ),
            'days': _is.ParameterDescription(
              name: 'days',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['market'] as _iaw7fzks.MarketEndpoint).capHistory(
                    session,
                    market: params['market'],
                    days: params['days'],
                  ),
        ),
        'indexHistory': _is.MethodConnector(
          name: 'indexHistory',
          params: {
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'series': _is.ParameterDescription(
              name: 'series',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'days': _is.ParameterDescription(
              name: 'days',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['market'] as _iaw7fzks.MarketEndpoint)
                  .indexHistory(
                    session,
                    params['name'],
                    series: params['series'],
                    days: params['days'],
                  ),
        ),
        'priceHistory': _is.MethodConnector(
          name: 'priceHistory',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'days': _is.ParameterDescription(
              name: 'days',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['market'] as _iaw7fzks.MarketEndpoint)
                  .priceHistory(
                    session,
                    params['corpCode'],
                    days: params['days'],
                  ),
        ),
      },
    );
    connectors['membership'] = _is.EndpointConnector(
      name: 'membership',
      endpoint: endpoints['membership']!,
      methodConnectors: {
        'paymentsForAccount': _is.MethodConnector(
          name: 'paymentsForAccount',
          params: {
            'userId': _is.ParameterDescription(
              name: 'userId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['membership'] as _i4hwwhem.MembershipEndpoint)
                      .paymentsForAccount(
                        session,
                        params['userId'],
                      ),
        ),
        'refundPayment': _is.MethodConnector(
          name: 'refundPayment',
          params: {
            'attemptId': _is.ParameterDescription(
              name: 'attemptId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'expectedOrderId': _is.ParameterDescription(
              name: 'expectedOrderId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['membership'] as _i4hwwhem.MembershipEndpoint)
                      .refundPayment(
                        session,
                        params['attemptId'],
                        params['expectedOrderId'],
                      ),
        ),
        'status': _is.MethodConnector(
          name: 'status',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['membership'] as _i4hwwhem.MembershipEndpoint)
                      .status(session),
        ),
        'beginCheckout': _is.MethodConnector(
          name: 'beginCheckout',
          params: {
            'acceptedTestTerms': _is.ParameterDescription(
              name: 'acceptedTestTerms',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'expectedAmountKrw': _is.ParameterDescription(
              name: 'expectedAmountKrw',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['membership'] as _i4hwwhem.MembershipEndpoint)
                      .beginCheckout(
                        session,
                        params['acceptedTestTerms'],
                        expectedAmountKrw: params['expectedAmountKrw'],
                      ),
        ),
        'beginCardReplacement': _is.MethodConnector(
          name: 'beginCardReplacement',
          params: {
            'acceptedTestTerms': _is.ParameterDescription(
              name: 'acceptedTestTerms',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['membership'] as _i4hwwhem.MembershipEndpoint)
                      .beginCardReplacement(
                        session,
                        params['acceptedTestTerms'],
                      ),
        ),
        'resumeRenewal': _is.MethodConnector(
          name: 'resumeRenewal',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['membership'] as _i4hwwhem.MembershipEndpoint)
                      .resumeRenewal(session),
        ),
        'completeCheckout': _is.MethodConnector(
          name: 'completeCheckout',
          params: {
            'state': _is.ParameterDescription(
              name: 'state',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'authKey': _is.ParameterDescription(
              name: 'authKey',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['membership'] as _i4hwwhem.MembershipEndpoint)
                      .completeCheckout(
                        session,
                        params['state'],
                        params['authKey'],
                      ),
        ),
        'abortCheckout': _is.MethodConnector(
          name: 'abortCheckout',
          params: {
            'state': _is.ParameterDescription(
              name: 'state',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['membership'] as _i4hwwhem.MembershipEndpoint)
                      .abortCheckout(
                        session,
                        params['state'],
                      ),
        ),
        'cancelRenewal': _is.MethodConnector(
          name: 'cancelRenewal',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['membership'] as _i4hwwhem.MembershipEndpoint)
                      .cancelRenewal(session),
        ),
      },
    );
    connectors['membershipOffer'] = _is.EndpointConnector(
      name: 'membershipOffer',
      endpoint: endpoints['membershipOffer']!,
      methodConnectors: {
        'offer': _is.MethodConnector(
          name: 'offer',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['membershipOffer']
                          as _ilgl7tj9.MembershipOfferEndpoint)
                      .offer(session),
        ),
      },
    );
    connectors['review'] = _is.EndpointConnector(
      name: 'review',
      endpoint: endpoints['review']!,
      methodConnectors: {
        'list': _is.MethodConnector(
          name: 'list',
          params: {
            'status': _is.ParameterDescription(
              name: 'status',
              type: _is.getType<_iy39k7od.RelationStatus?>(),
              nullable: true,
            ),
            'predicate': _is.ParameterDescription(
              name: 'predicate',
              type: _is.getType<_iw7mt1ku.RelationPredicate?>(),
              nullable: true,
            ),
            'offset': _is.ParameterDescription(
              name: 'offset',
              type: _is.getType<int?>(),
              nullable: true,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['review'] as _i9uttt4a.ReviewEndpoint).list(
                session,
                status: params['status'],
                predicate: params['predicate'],
                offset: params['offset'],
                limit: params['limit'],
              ),
        ),
        'decide': _is.MethodConnector(
          name: 'decide',
          params: {
            'relationId': _is.ParameterDescription(
              name: 'relationId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'approve': _is.ParameterDescription(
              name: 'approve',
              type: _is.getType<bool>(),
              nullable: false,
            ),
            'by': _is.ParameterDescription(
              name: 'by',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['review'] as _i9uttt4a.ReviewEndpoint).decide(
                    session,
                    params['relationId'],
                    params['approve'],
                    by: params['by'],
                  ),
        ),
        'decideMany': _is.MethodConnector(
          name: 'decideMany',
          params: {
            'relationIds': _is.ParameterDescription(
              name: 'relationIds',
              type: _is.getType<List<int>>(),
              nullable: false,
            ),
            'approve': _is.ParameterDescription(
              name: 'approve',
              type: _is.getType<bool>(),
              nullable: false,
            ),
            'by': _is.ParameterDescription(
              name: 'by',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['review'] as _i9uttt4a.ReviewEndpoint).decideMany(
                    session,
                    params['relationIds'],
                    params['approve'],
                    by: params['by'],
                  ),
        ),
        'decideFactsMany': _is.MethodConnector(
          name: 'decideFactsMany',
          params: {
            'factIds': _is.ParameterDescription(
              name: 'factIds',
              type: _is.getType<List<int>>(),
              nullable: false,
            ),
            'approve': _is.ParameterDescription(
              name: 'approve',
              type: _is.getType<bool>(),
              nullable: false,
            ),
            'by': _is.ParameterDescription(
              name: 'by',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['review'] as _i9uttt4a.ReviewEndpoint)
                  .decideFactsMany(
                    session,
                    params['factIds'],
                    params['approve'],
                    by: params['by'],
                  ),
        ),
        'context': _is.MethodConnector(
          name: 'context',
          params: {
            'scope': _is.ParameterDescription(
              name: 'scope',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'around': _is.ParameterDescription(
              name: 'around',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['review'] as _i9uttt4a.ReviewEndpoint).context(
                    session,
                    params['scope'],
                    params['id'],
                    around: params['around'],
                  ),
        ),
        'recommend': _is.MethodConnector(
          name: 'recommend',
          params: {
            'scope': _is.ParameterDescription(
              name: 'scope',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'ids': _is.ParameterDescription(
              name: 'ids',
              type: _is.getType<List<int>>(),
              nullable: false,
            ),
            'recommendation': _is.ParameterDescription(
              name: 'recommendation',
              type: _is.getType<_iy39k7od.RelationStatus>(),
              nullable: false,
            ),
            'note': _is.ParameterDescription(
              name: 'note',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['review'] as _i9uttt4a.ReviewEndpoint).recommend(
                    session,
                    params['scope'],
                    params['ids'],
                    params['recommendation'],
                    params['note'],
                  ),
        ),
        'applyRecommended': _is.MethodConnector(
          name: 'applyRecommended',
          params: {
            'scope': _is.ParameterDescription(
              name: 'scope',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['review'] as _i9uttt4a.ReviewEndpoint)
                  .applyRecommended(
                    session,
                    params['scope'],
                  ),
        ),
        'recordCheck': _is.MethodConnector(
          name: 'recordCheck',
          params: {
            'scope': _is.ParameterDescription(
              name: 'scope',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'checked': _is.ParameterDescription(
              name: 'checked',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'correct': _is.ParameterDescription(
              name: 'correct',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'leftToPerson': _is.ParameterDescription(
              name: 'leftToPerson',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'checkedBy': _is.ParameterDescription(
              name: 'checkedBy',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'note': _is.ParameterDescription(
              name: 'note',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['review'] as _i9uttt4a.ReviewEndpoint).recordCheck(
                    session,
                    params['scope'],
                    params['checked'],
                    params['correct'],
                    params['leftToPerson'],
                    params['checkedBy'],
                    note: params['note'],
                  ),
        ),
        'checks': _is.MethodConnector(
          name: 'checks',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['review'] as _i9uttt4a.ReviewEndpoint)
                  .checks(session),
        ),
        'facts': _is.MethodConnector(
          name: 'facts',
          params: {
            'status': _is.ParameterDescription(
              name: 'status',
              type: _is.getType<_iy39k7od.RelationStatus?>(),
              nullable: true,
            ),
            'kind': _is.ParameterDescription(
              name: 'kind',
              type: _is.getType<_i1rhjzgf.DocumentFactKind?>(),
              nullable: true,
            ),
            'offset': _is.ParameterDescription(
              name: 'offset',
              type: _is.getType<int?>(),
              nullable: true,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['review'] as _i9uttt4a.ReviewEndpoint).facts(
                    session,
                    status: params['status'],
                    kind: params['kind'],
                    offset: params['offset'],
                    limit: params['limit'],
                  ),
        ),
        'decideFact': _is.MethodConnector(
          name: 'decideFact',
          params: {
            'factId': _is.ParameterDescription(
              name: 'factId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'approve': _is.ParameterDescription(
              name: 'approve',
              type: _is.getType<bool>(),
              nullable: false,
            ),
            'by': _is.ParameterDescription(
              name: 'by',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['review'] as _i9uttt4a.ReviewEndpoint).decideFact(
                    session,
                    params['factId'],
                    params['approve'],
                    by: params['by'],
                  ),
        ),
        'forCompany': _is.MethodConnector(
          name: 'forCompany',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['review'] as _i9uttt4a.ReviewEndpoint).forCompany(
                    session,
                    params['corpCode'],
                  ),
        ),
      },
    );
    connectors['screen'] = _is.EndpointConnector(
      name: 'screen',
      endpoint: endpoints['screen']!,
      methodConnectors: {
        'peerCandidates': _is.MethodConnector(
          name: 'peerCandidates',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'focusKey': _is.ParameterDescription(
              name: 'focusKey',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['screen'] as _ilgabfhk.ScreenEndpoint)
                  .peerCandidates(
                    session,
                    params['corpCode'],
                    focusKey: params['focusKey'],
                  ),
        ),
        'list': _is.MethodConnector(
          name: 'list',
          params: {
            'corpCodes': _is.ParameterDescription(
              name: 'corpCodes',
              type: _is.getType<List<String>?>(),
              nullable: true,
            ),
            'market': _is.ParameterDescription(
              name: 'market',
              type: _is.getType<_iyonaxpd.Market?>(),
              nullable: true,
            ),
            'sectionCode': _is.ParameterDescription(
              name: 'sectionCode',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'perMax': _is.ParameterDescription(
              name: 'perMax',
              type: _is.getType<double?>(),
              nullable: true,
            ),
            'pbrMax': _is.ParameterDescription(
              name: 'pbrMax',
              type: _is.getType<double?>(),
              nullable: true,
            ),
            'roeMin': _is.ParameterDescription(
              name: 'roeMin',
              type: _is.getType<double?>(),
              nullable: true,
            ),
            'operatingMarginMin': _is.ParameterDescription(
              name: 'operatingMarginMin',
              type: _is.getType<double?>(),
              nullable: true,
            ),
            'revenueGrowthMin': _is.ParameterDescription(
              name: 'revenueGrowthMin',
              type: _is.getType<double?>(),
              nullable: true,
            ),
            'operatingIncomeGrowthMin': _is.ParameterDescription(
              name: 'operatingIncomeGrowthMin',
              type: _is.getType<double?>(),
              nullable: true,
            ),
            'debtRatioMax': _is.ParameterDescription(
              name: 'debtRatioMax',
              type: _is.getType<double?>(),
              nullable: true,
            ),
            'dividendYieldMin': _is.ParameterDescription(
              name: 'dividendYieldMin',
              type: _is.getType<double?>(),
              nullable: true,
            ),
            'fcfYieldMin': _is.ParameterDescription(
              name: 'fcfYieldMin',
              type: _is.getType<double?>(),
              nullable: true,
            ),
            'dividendPayoutMax': _is.ParameterDescription(
              name: 'dividendPayoutMax',
              type: _is.getType<double?>(),
              nullable: true,
            ),
            'dividendYearsMin': _is.ParameterDescription(
              name: 'dividendYearsMin',
              type: _is.getType<int?>(),
              nullable: true,
            ),
            'volumeMin': _is.ParameterDescription(
              name: 'volumeMin',
              type: _is.getType<BigInt?>(),
              nullable: true,
            ),
            'volumeRatioMin': _is.ParameterDescription(
              name: 'volumeRatioMin',
              type: _is.getType<double?>(),
              nullable: true,
            ),
            'return3mMin': _is.ParameterDescription(
              name: 'return3mMin',
              type: _is.getType<double?>(),
              nullable: true,
            ),
            'return12mMin': _is.ParameterDescription(
              name: 'return12mMin',
              type: _is.getType<double?>(),
              nullable: true,
            ),
            'bandPositionMin': _is.ParameterDescription(
              name: 'bandPositionMin',
              type: _is.getType<double?>(),
              nullable: true,
            ),
            'marketCapMin': _is.ParameterDescription(
              name: 'marketCapMin',
              type: _is.getType<BigInt?>(),
              nullable: true,
            ),
            'avgTradingValueMin': _is.ParameterDescription(
              name: 'avgTradingValueMin',
              type: _is.getType<BigInt?>(),
              nullable: true,
            ),
            'sort': _is.ParameterDescription(
              name: 'sort',
              type: _is.getType<_i9blzem0.ScreenSort?>(),
              nullable: true,
            ),
            'ascending': _is.ParameterDescription(
              name: 'ascending',
              type: _is.getType<bool?>(),
              nullable: true,
            ),
            'offset': _is.ParameterDescription(
              name: 'offset',
              type: _is.getType<int?>(),
              nullable: true,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['screen'] as _ilgabfhk.ScreenEndpoint).list(
                session,
                corpCodes: params['corpCodes'],
                market: params['market'],
                sectionCode: params['sectionCode'],
                perMax: params['perMax'],
                pbrMax: params['pbrMax'],
                roeMin: params['roeMin'],
                operatingMarginMin: params['operatingMarginMin'],
                revenueGrowthMin: params['revenueGrowthMin'],
                operatingIncomeGrowthMin: params['operatingIncomeGrowthMin'],
                debtRatioMax: params['debtRatioMax'],
                dividendYieldMin: params['dividendYieldMin'],
                fcfYieldMin: params['fcfYieldMin'],
                dividendPayoutMax: params['dividendPayoutMax'],
                dividendYearsMin: params['dividendYearsMin'],
                volumeMin: params['volumeMin'],
                volumeRatioMin: params['volumeRatioMin'],
                return3mMin: params['return3mMin'],
                return12mMin: params['return12mMin'],
                bandPositionMin: params['bandPositionMin'],
                marketCapMin: params['marketCapMin'],
                avgTradingValueMin: params['avgTradingValueMin'],
                sort: params['sort'],
                ascending: params['ascending'],
                offset: params['offset'],
                limit: params['limit'],
              ),
        ),
        'peers': _is.MethodConnector(
          name: 'peers',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['screen'] as _ilgabfhk.ScreenEndpoint).peers(
                    session,
                    params['corpCode'],
                  ),
        ),
      },
    );
    connectors['theme'] = _is.EndpointConnector(
      name: 'theme',
      endpoint: endpoints['theme']!,
      methodConnectors: {
        'list': _is.MethodConnector(
          name: 'list',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['theme'] as _iqaca509.ThemeEndpoint).list(session),
        ),
        'create': _is.MethodConnector(
          name: 'create',
          params: {
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'description': _is.ParameterDescription(
              name: 'description',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['theme'] as _iqaca509.ThemeEndpoint).create(
                session,
                params['name'],
                description: params['description'],
              ),
        ),
        'update': _is.MethodConnector(
          name: 'update',
          params: {
            'themeId': _is.ParameterDescription(
              name: 'themeId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'description': _is.ParameterDescription(
              name: 'description',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['theme'] as _iqaca509.ThemeEndpoint).update(
                session,
                params['themeId'],
                params['name'],
                description: params['description'],
              ),
        ),
        'delete': _is.MethodConnector(
          name: 'delete',
          params: {
            'themeId': _is.ParameterDescription(
              name: 'themeId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['theme'] as _iqaca509.ThemeEndpoint).delete(
                session,
                params['themeId'],
              ),
        ),
        'detail': _is.MethodConnector(
          name: 'detail',
          params: {
            'themeId': _is.ParameterDescription(
              name: 'themeId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['theme'] as _iqaca509.ThemeEndpoint).detail(
                session,
                params['themeId'],
              ),
        ),
        'addCompany': _is.MethodConnector(
          name: 'addCompany',
          params: {
            'themeId': _is.ParameterDescription(
              name: 'themeId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'note': _is.ParameterDescription(
              name: 'note',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['theme'] as _iqaca509.ThemeEndpoint).addCompany(
                    session,
                    params['themeId'],
                    params['corpCode'],
                    note: params['note'],
                  ),
        ),
        'removeCompany': _is.MethodConnector(
          name: 'removeCompany',
          params: {
            'themeId': _is.ParameterDescription(
              name: 'themeId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['theme'] as _iqaca509.ThemeEndpoint).removeCompany(
                    session,
                    params['themeId'],
                    params['corpCode'],
                  ),
        ),
        'themesOf': _is.MethodConnector(
          name: 'themesOf',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['theme'] as _iqaca509.ThemeEndpoint).themesOf(
                    session,
                    params['corpCode'],
                  ),
        ),
      },
    );
    connectors['watchlist'] = _is.EndpointConnector(
      name: 'watchlist',
      endpoint: endpoints['watchlist']!,
      methodConnectors: {
        'mine': _is.MethodConnector(
          name: 'mine',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['watchlist'] as _ia3gawxy.WatchlistEndpoint)
                  .mine(session),
        ),
        'add': _is.MethodConnector(
          name: 'add',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['watchlist'] as _ia3gawxy.WatchlistEndpoint).add(
                    session,
                    params['corpCode'],
                  ),
        ),
        'remove': _is.MethodConnector(
          name: 'remove',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['watchlist'] as _ia3gawxy.WatchlistEndpoint)
                  .remove(
                    session,
                    params['corpCode'],
                  ),
        ),
        'mute': _is.MethodConnector(
          name: 'mute',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'muted': _is.ParameterDescription(
              name: 'muted',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['watchlist'] as _ia3gawxy.WatchlistEndpoint).mute(
                    session,
                    params['corpCode'],
                    params['muted'],
                  ),
        ),
        'prioritize': _is.MethodConnector(
          name: 'prioritize',
          params: {
            'corpCode': _is.ParameterDescription(
              name: 'corpCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['watchlist'] as _ia3gawxy.WatchlistEndpoint)
                  .prioritize(
                    session,
                    params['corpCode'],
                  ),
        ),
        'markRead': _is.MethodConnector(
          name: 'markRead',
          params: {
            'noticeId': _is.ParameterDescription(
              name: 'noticeId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['watchlist'] as _ia3gawxy.WatchlistEndpoint)
                  .markRead(
                    session,
                    params['noticeId'],
                  ),
        ),
        'subscribePush': _is.MethodConnector(
          name: 'subscribePush',
          params: {
            'endpoint': _is.ParameterDescription(
              name: 'endpoint',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'p256dh': _is.ParameterDescription(
              name: 'p256dh',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'auth': _is.ParameterDescription(
              name: 'auth',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['watchlist'] as _ia3gawxy.WatchlistEndpoint)
                  .subscribePush(
                    session,
                    params['endpoint'],
                    params['p256dh'],
                    params['auth'],
                  ),
        ),
        'unsubscribePush': _is.MethodConnector(
          name: 'unsubscribePush',
          params: {
            'endpoint': _is.ParameterDescription(
              name: 'endpoint',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['watchlist'] as _ia3gawxy.WatchlistEndpoint)
                  .unsubscribePush(
                    session,
                    params['endpoint'],
                  ),
        ),
      },
    );
    modules['serverpod_auth_idp'] = _iais.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth_core'] = _iacs.Endpoints()
      ..initializeEndpoints(server);
  }

  @override
  _is.FutureCallDispatch? get futureCalls {
    return _i4o8e4lj.FutureCalls();
  }
}
