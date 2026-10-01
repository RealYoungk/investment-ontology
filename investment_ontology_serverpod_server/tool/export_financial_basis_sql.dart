import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_basis.dart';

// Emits SQL for a read-only audit; does not connect to or start the server.
void main() => stdout.write(
  'COPY (WITH ${FinancialBasis.ctes()} SELECT row_to_json(q) FROM (SELECT t.*,c.y,c.code FROM ttm t JOIN candidates c ON c.id=t.id AND c.fs=t.fs) q) TO STDOUT;',
);
