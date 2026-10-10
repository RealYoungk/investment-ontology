import 'package:http/http.dart' as http;
import 'package:investment_ontology_serverpod_server/src/ontology/news/google_news_service.dart';

Future<void> main() async {
  final client = http.Client();
  try {
    final items = await GoogleNewsService.read(
      client,
      '미코',
      DateTime.now().toUtc(),
      stockCode: '059090',
      ceoName: '전선규',
    );
    print('Google accepted: ${items.length}');
    for (final i in items) {
      print('${i.publishedAt} ${i.title}');
    }
  } finally {
    client.close();
  }
}
