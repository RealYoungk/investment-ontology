import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../client.dart';

/// Only accessible from the admin account screen; RPC enforces admin again.
class PaymentAdminDialog extends StatefulWidget {
  const PaymentAdminDialog({
    super.key,
    required this.user,
    this.loadPayments,
    this.refundPayment,
  });
  final Future<List<BillingPaymentView>> Function()? loadPayments;
  final Future<void> Function(int, String)? refundPayment;
  final AccountView user;
  @override
  State<PaymentAdminDialog> createState() => _PaymentAdminDialogState();
}

class _PaymentAdminDialogState extends State<PaymentAdminDialog> {
  late Future<List<BillingPaymentView>> _load = _fetch();
  Future<List<BillingPaymentView>> _fetch() =>
      widget.loadPayments?.call() ??
      client.membership.paymentsForAccount(widget.user.userId);
  bool _busy = false;
  String? _message;

  Future<void> _refund(BillingPaymentView row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('전액 환불 확인'),
        content: Text(
          '${widget.user.email}\n주문 ${row.orderId}\n'
          '${row.amountKrw}원 전액 환불을 요청합니다.\n'
          '고객 문의와 주문을 대조했나요? 현재 결제 주기라면 자동 갱신이 중지되고, '
          '결제사의 취소 확인 후 광고 제거 이용권이 종료됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('돌아가기'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('전액 환불 요청'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await (widget.refundPayment ?? client.membership.refundPayment)(
        row.attemptId,
        row.orderId,
      );
      if (mounted) {
        setState(() => _message = '결과를 확인해 주세요. 환불 확인 중이면 자동으로 재조회·재처리됩니다.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = '응답을 확인하지 못했습니다. 내역을 새로고침해 상태를 확인해 주세요.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _load = _fetch();
        });
      }
    }
  }

  String _status(String value) => switch (value) {
    'paid' => '결제 완료',
    'refunded' => '전액 환불 완료',
    'refundRequested' || 'refundRequired' => '환불 확인 중',
    'unknown' => '결제 결과 확인 중',
    'pending' => '결제 처리 중',
    'abandoned' => '결제 중단',
    _ => '확인 필요',
  };

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('결제 내역 · 환불'),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.user.email),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_message!),
              ),
            FutureBuilder<List<BillingPaymentView>>(
              future: _load,
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Text('내역을 불러오지 못했습니다.');
                if (!snapshot.hasData) return const CircularProgressIndicator();
                if (snapshot.data!.isEmpty) return const Text('결제 내역이 없습니다.');
                return Column(
                  children: [
                    for (final row in snapshot.data!)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText(row.orderId),
                            Text('${row.amountKrw}원 · ${_status(row.status)}'),
                            Text(
                              '이용 기간 (UTC) '
                              '${row.paidFromUtc.toIso8601String()} ~ '
                              '${row.paidThroughUtc.toIso8601String()}',
                            ),
                            if (row.status == 'paid' ||
                                row.status == 'refundRequested')
                              TextButton(
                                onPressed: _busy ? null : () => _refund(row),
                                child: Text(
                                  row.status == 'paid' ? '전액 환불' : '결과 다시 확인',
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy
            ? null
            : () => setState(
                () => _load = client.membership.paymentsForAccount(
                  widget.user.userId,
                ),
              ),
        child: const Text('새로고침'),
      ),
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context),
        child: const Text('닫기'),
      ),
    ],
  );
}
