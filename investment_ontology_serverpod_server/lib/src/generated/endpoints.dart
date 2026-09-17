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
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/fs_div.dart'
    as _i69nddnn;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/market.dart'
    as _iyonaxpd;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _iais;
import '../auth/email_idp_endpoint.dart' as _iuc1hd5t;
import '../auth/jwt_refresh_endpoint.dart' as _inwq3ztq;
import '../greetings/greeting_endpoint.dart' as _il624ik7;
import '../ontology/endpoints/company_endpoint.dart' as _itnisr3u;
import '../ontology/endpoints/financial_endpoint.dart' as _ipit2z9y;
import '../ontology/endpoints/ingest_endpoint.dart' as _icbircc0;
import '../ontology/endpoints/market_endpoint.dart' as _iaw7fzks;
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
      'company': _itnisr3u.CompanyEndpoint()
        ..initialize(
          server,
          'company',
          null,
        ),
      'financial': _ipit2z9y.FinancialEndpoint()
        ..initialize(
          server,
          'financial',
          null,
        ),
      'ingest': _icbircc0.IngestEndpoint()
        ..initialize(
          server,
          'ingest',
          null,
        ),
      'market': _iaw7fzks.MarketEndpoint()
        ..initialize(
          server,
          'market',
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
      },
    );
    connectors['market'] = _is.EndpointConnector(
      name: 'market',
      endpoint: endpoints['market']!,
      methodConnectors: {
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
