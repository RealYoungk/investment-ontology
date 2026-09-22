import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:serverpod_auth_idp_flutter/widgets.dart';

/// 인증 코드 화면(가입 인증·재설정 코드 인증 둘 다 이 위젯을 쓴다).
///
/// 패키지 기본 `VerificationForm`은 재전송 버튼(`ResendCodeButton`)의 문구가 고정 영어라
/// 지역화할 방법이 없다. 좁은 화면에서도 8자리 코드를 입력할 수 있는 텍스트 칸과
/// 한국어 재전송 버튼을 사용하고, 인증 처리는 Serverpod 컨트롤러에 맡긴다.
class VerificationFormKo extends StatefulWidget {
  const VerificationFormKo({
    super.key,
    required this.controller,
    required this.title,
    required this.onCompleted,
  });

  final EmailAuthController controller;
  final String title;
  final VoidCallback onCompleted;

  @override
  State<VerificationFormKo> createState() => _VerificationFormKoState();
}

class _VerificationFormKoState extends State<VerificationFormKo> {
  final _focusNode = FocusNode();

  EmailAuthController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(_focusOnError);
  }

  @override
  void dispose() {
    controller.removeListener(_focusOnError);
    _focusNode.dispose();
    super.dispose();
  }

  /// 오류가 나면 코드 입력칸에 다시 초점을 준다(원문 VerificationForm과 같은 동작).
  void _focusOnError() {
    if (mounted && controller.state == EmailAuthState.error) {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final texts = context.emailSignInTexts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.headlineMedium),
        smallGap,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              texts.verificationMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.left,
            ),
            smallGap,
            TextField(
              focusNode: _focusNode,
              controller: controller.verificationCodeController,
              decoration: const InputDecoration(labelText: '인증 코드 (8자리)'),
              enabled: !controller.isLoading,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.oneTimeCode],
              autocorrect: false,
              enableSuggestions: false,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[1-9]')),
                LengthLimitingTextInputFormatter(8),
              ],
              onChanged: (value) {
                if (value.length == 8) widget.onCompleted();
              },
              onSubmitted: (value) {
                if (value.length == 8 && !controller.isLoading) {
                  widget.onCompleted();
                }
              },
            ),
            _ResendCodeButtonKo(
              onResendPressed: controller.resendVerificationCode,
            ),
          ],
        ),
        smallGap,
        ActionButton(
          onPressed: widget.onCompleted,
          label: texts.verify,
          isLoading: controller.isLoading,
        ),
        BackToSignInButton(controller: controller),
      ],
    );
  }
}

/// 패키지의 `ResendCodeButton`과 같은 카운트다운 동작을 하는 한국어 재전송 버튼.
class _ResendCodeButtonKo extends StatefulWidget {
  const _ResendCodeButtonKo({required this.onResendPressed});

  final Future<void> Function() onResendPressed;

  @override
  State<_ResendCodeButtonKo> createState() => _ResendCodeButtonKoState();
}

class _ResendCodeButtonKoState extends State<_ResendCodeButtonKo> {
  static const _countdown = Duration(minutes: 1);

  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _remainingSeconds = _countdown.inSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleResend() async {
    if (_remainingSeconds > 0 || _isResending) return;
    setState(() => _isResending = true);
    try {
      await widget.onResendPressed();
      if (mounted) _startTimer();
    } catch (_) {
      // 오류는 EmailAuthController의 onError로 이미 알린다.
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  String get _label => _remainingSeconds > 0
      ? '코드를 받지 못하셨나요? 새 코드 보내기 ($_remainingSeconds'
            '초 후)'
      : '코드를 받지 못하셨나요? 새 코드 보내기';

  @override
  Widget build(BuildContext context) {
    final isEnabled = _remainingSeconds == 0 && !_isResending;
    return Column(
      children: [
        tinyGap,
        TextButton(
          onPressed: isEnabled ? _handleResend : null,
          child: Text(_label),
        ),
      ],
    );
  }
}
