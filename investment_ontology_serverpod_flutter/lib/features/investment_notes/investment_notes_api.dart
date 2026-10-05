import 'dart:convert';

import '../../client.dart';

/// Hand-written reader adapter. Authorization stays in Serverpod.
abstract final class InvestmentNotesApi {
  static Future<List<Map<String, dynamic>>> list({
    String? corpCode,
    int offset = 0,
  }) async {
    final response = await client.investmentNotes.list(
      corpCode: corpCode,
      offset: offset,
    );
    return (jsonDecode(response) as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>?> detail(
    int id, {
    bool preview = false,
  }) async {
    final response = preview
        ? await client.investmentNotes.preview(id)
        : await client.investmentNotes.detail(id);
    final decoded = jsonDecode(response);
    if (decoded == null) return null;
    final data = decoded as Map<String, dynamic>;
    if (!preview) return data;
    final content = data['content'] as Map<String, dynamic>;
    return {
      ...content,
      'id': id,
      'locked': false,
      'preview': true,
      'state': data['state'],
      'version': data['version'],
      'digest': data['digest'],
    };
  }
}
