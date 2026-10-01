import 'dart:convert';
import 'dart:io';

/// Evidence-backed exceptions reviewed against the latest stored filing.
/// A new/corrected filing invalidates an entry: neither identity nor a product
/// label alone can silently carry it forward. These are classification records,
/// not generated business summaries or numeric facts.
abstract final class ReviewedFilingOfferings {
  static final rows = (jsonDecode(
    File('assets/discovery/reviewed_filing_offerings.json').readAsStringSync(),
  ) as List).cast<Map<String, dynamic>>();

  static List<((String, String, String, String), String)> match({
    required String corpCode,
    required String receipt,
    required int year,
    required String text,
  }) => [
    for (var i = 0; i < rows.length; i++)
      if (rows[i]['corpCode'] == corpCode &&
          rows[i]['rceptNo'] == receipt &&
          rows[i]['year'] == year &&
          (rows[i]['evidence'] as String).isNotEmpty &&
          text.contains(rows[i]['evidence'] as String))
        (
          (
            rows[i]['industry'] as String,
            rows[i]['group'] as String,
            'reviewed-filing:$i',
            rows[i]['product'] as String,
          ),
          rows[i]['evidence'] as String,
        ),
  ];
}
