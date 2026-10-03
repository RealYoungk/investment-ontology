import 'package:flutter/widgets.dart';

import '../common/service_footer.dart';

/// 기존 정책 링크 사용처도 동일한 공용 푸터를 사용한다.
class ServiceLinks extends StatelessWidget {
  const ServiceLinks({super.key});

  @override
  Widget build(BuildContext context) => const ServiceFooter();
}
