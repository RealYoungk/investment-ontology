import 'dart:convert';

import 'package:crypto/crypto.dart';

/// One official historical cover's printed role, never a general name alias.
abstract final class ExactCoverExecutiveRole {
  static RegExp names(String rawCover) {
    final exact =
        sha256.convert(utf8.encode(rawCover)).toString() ==
        '0a421d3cc8f069bed67bdfbe86b33ab51011f90c5c2ab16edb4744b479b20d92';
    return RegExp(exact ? r'회사명:(.*?)대표집행임원:' : r'회사명:(.*?)(?:공동)?대표이사:');
  }
}
