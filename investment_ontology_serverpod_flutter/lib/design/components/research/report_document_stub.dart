import 'package:flutter/material.dart';

class ReportDocument extends StatelessWidget {
  const ReportDocument({
    super.key,
    required this.title,
    required this.summary,
    required this.date,
    required this.content,
    required this.legacy,
  });
  final String title, summary, date, content;
  final bool legacy;
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('웹에서 리포트 원문을 열어주세요.'));
}
