import 'package:shad/shad.dart';
import 'package:flutter/material.dart';

/// 서버의 `Scope.admin` 이름. 앱은 이 이름으로 역할을 표시만 하고, 막는 것은 서버다.
const adminScopeName = 'serverpod.admin';
const adFreeScopeName = 'alfinder.adFree';

/// 로그인한 사람. 앱이 알아야 하는 것은 누구인지와 관리자인지뿐이다.
@immutable
class AppViewer {
  const AppViewer({
    required this.userId,
    required this.isAdmin,
    this.isAdFree = false,
    this.membershipResolved = true,
    this.paidThroughUtc,
    this.cancelAtPeriodEnd = false,
    this.paymentAvailable = false,
    this.isTestMembership = false,
  });

  AppViewer.fromScopes(this.userId, Set<String> scopeNames)
    : membershipResolved = false,
      isAdmin = scopeNames.contains(adminScopeName),
      isAdFree = scopeNames.contains(adFreeScopeName),
      paidThroughUtc = null,
      cancelAtPeriodEnd = false,
      paymentAvailable = false,
      isTestMembership = false;

  final String userId;
  final bool isAdmin;

  /// Server-issued entitlement; independent of administrator access.
  final bool isAdFree;

  /// Suppress advertising while the account entitlement is still unknown.
  /// This never grants paid access or administrator permissions.
  final bool membershipResolved;
  final DateTime? paidThroughUtc;
  final bool cancelAtPeriodEnd;
  final bool paymentAvailable;
  final bool isTestMembership;

  String get roleLabel => isAdmin ? '관리자' : '읽기 전용';

  @override
  bool operator ==(Object other) =>
      other is AppViewer &&
      other.userId == userId &&
      other.isAdmin == isAdmin &&
      other.isAdFree == isAdFree &&
      other.membershipResolved == membershipResolved &&
      other.paidThroughUtc == paidThroughUtc &&
      other.cancelAtPeriodEnd == cancelAtPeriodEnd &&
      other.paymentAvailable == paymentAvailable &&
      other.isTestMembership == isTestMembership;

  @override
  int get hashCode => Object.hash(
    userId,
    isAdmin,
    isAdFree,
    membershipResolved,
    paidThroughUtc,
    cancelAtPeriodEnd,
    paymentAvailable,
    isTestMembership,
  );
}

/// 로그인 문 안쪽의 모든 화면에 [AppViewer]를 내려준다.
class AppViewerScope extends InheritedWidget {
  const AppViewerScope({super.key, required this.viewer, required super.child});

  final AppViewer? viewer;

  static AppViewer? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppViewerScope>()?.viewer;

  @override
  bool updateShouldNotify(AppViewerScope oldWidget) =>
      viewer != oldWidget.viewer;
}

/// 관리자만 하는 일(테마 편집, 수집 시작, 검수 결정 등)을 누르기 전에 확인한다.
extension AdminGuard on BuildContext {
  /// 로그인 문 안쪽이면 지금 사람. 바깥(테스트 등)이면 null.
  AppViewer? get viewer => AppViewerScope.maybeOf(this);

  bool get isAdmin => viewer?.isAdmin ?? false;

  /// 관리자면 true. 아니면 권한 안내를 띄우고 false — 서버에 요청을 보내지 않는다.
  bool ensureAdmin() {
    if (isAdmin) return true;
    showPermissionNotice();
    return false;
  }

  void showPermissionNotice() {
    ShadToaster.maybeOf(this)
      ?..hide()
      ..show(
        ShadToast(
          description: Text(permissionMessage),
        ),
      );
  }
}

const permissionMessage = '관리자 권한이 필요합니다. 읽기 전용 계정은 데이터를 바꿀 수 없습니다.';
