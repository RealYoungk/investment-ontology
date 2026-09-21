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
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _iais;
import '../auth/email_idp_endpoint.dart' as _iuc1hd5t;
import '../auth/jwt_refresh_endpoint.dart' as _inwq3ztq;
import '../greetings/greeting_endpoint.dart' as _il624ik7;
import '../ontology/endpoints/ai_endpoint.dart' as _iadofkda;
import '../ontology/endpoints/company_endpoint.dart' as _itnisr3u;
import '../ontology/endpoints/disclosure_endpoint.dart' as _i23b9rs7;
import '../ontology/endpoints/financial_endpoint.dart' as _ipit2z9y;
import '../ontology/endpoints/governance_endpoint.dart' as _i6kw8hva;
import '../ontology/endpoints/graph_endpoint.dart' as _ixdq71x8;
import '../ontology/endpoints/group_endpoint.dart' as _i8zm50hy;
import '../ontology/endpoints/ingest_endpoint.dart' as _icbircc0;
import '../ontology/endpoints/market_endpoint.dart' as _iaw7fzks;
import '../ontology/endpoints/review_endpoint.dart' as _i9uttt4a;
import '../ontology/endpoints/theme_endpoint.dart' as _iqaca509;
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
      'ai': _iadofkda.AiEndpoint()
        ..initialize(
          server,
          'ai',
          null,
        ),
      'company': _itnisr3u.CompanyEndpoint()
        ..initialize(
          server,
          'company',
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
      'review': _i9uttt4a.ReviewEndpoint()
        ..initialize(
          server,
          'review',
          null,
        ),
      'theme': _iqaca509.ThemeEndpoint()
        ..initialize(
          server,
          'theme',
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
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ai'] as _iadofkda.AiEndpoint).documentText(
                session,
                params['documentId'],
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
    connectors['disclosure'] = _is.EndpointConnector(
      name: 'disclosure',
      endpoint: endpoints['disclosure']!,
      methodConnectors: {
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
                  ),
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
