import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../../generated/protocol.dart';
import 'known_annual_source_conflict.dart';
import 'land_trust_own_source_conflicts.dart';

/// Exact immutable conflict evidence only. Never yields numerical/noData rows.
class KnownAnnualConflictCache {
  KnownAnnualConflictCache({Future<List<int>> Function(String)? readFile})
    : _read = readFile ?? ((path) => File(path).readAsBytes());
  final Future<List<int>> Function(String) _read;
  static const directory =
      'assets/financial_source_cache/known-annual-conflicts';
  static const manifestSha =
      '1c1258d005c9be24980a12b10ef7bf1506d053327366f8598b0ebfa821eb41d5';
  static const pins = {
    "20220322000964-cfs.html":
        "8add3792568e83399c5ca5f41a10efbcd840ecd1b0f51252a4421b7feaa48d87",
    "20220322000964-cover.html":
        "e2c871b9d537eb40220ce7df44a37b06234cff699cee77f23013dd2a81d0c7f6",
    "20240320001438-cfs.html":
        "8a55352ab6ab28b50e276f0e70fee937a739cedf33ddbac8fbd9d09844503a65",
    "20240320001438-cover.html":
        "779a3a6cff8c09e3ed3660cd48e812803e0ecc623fc20736c8c4887e30734363",
    "20250324000541-cover.html":
        "d1ce204fe71edcbaf822117d9d2d52b103d9559004ac9c2d2385d0b54f379b82",
    "20250324000541-ofs.html":
        "7e8d331b085aa3df62ded276a617b80d456085d77c0ab32c6df3da653de67e6a",
    "20220316000546-cfs.html":
        "48ccfccc4770ad6a4c3271541c10fd53712906eba6e00612fc17cf27cb202404",
    "20220316000546-cover.html":
        "b89e6fca1bacd91fa9277469ca7937e41a48a3b58946c1b404a4412dc83cc766",
    "20220316000546-ofs.html":
        "0db9a581dad9341761daed84b87b74865c006f7ee39d148f0020f0597da13da2",
    "20230323000917-cfs.html":
        "ae0c5a76ea7ca152e477ade0671ff792394218480d03b8a9e8ce8c06ea53c381",
    "20230323000917-cover.html":
        "bb0ba718d8a9777cbfb2c827e6a5d466437ba6d54fdbb1da09bcab12fa740f70",
    "20230323000917-ofs.html":
        "ec5eb32389c0d94bb3f16e27c569cf34c8e1894211bf201377dc5bf2d02bb992",
  };
  static List<Map<String, Object>> get profiles => [
    for (final e in KnownAnnualSourceConflicts.profiles.entries)
      {'receipt': e.key, ...e.value},
    for (final e in LandTrustOwnSourceConflicts.profiles.values)
      {
        ...Map<String, Object>.from(e as Map),
        'consolidated': e['basis'] == 'CFS',
        'coverSource': e['coverURI'],
        'statementSource': e['sourceURI'],
        'coverSha256': e['coverSHA'],
        'statementSha256': e['sourceSHA'],
      },
  ];
  static Map<String, Object>? profile(DartFiling f, Company c, FsDiv div) {
    // Preserve legitimate ordinary public retries independently of the general
    // attempt counter. Only exhausted public attempts enter this local audit.
    final error = f.lastError ?? '';
    if (error.contains('api-noData-annual-public')) {
      final attempt = int.tryParse(
        RegExp(r'api-noData-annual-public:attempt=(\d+)')
                .firstMatch(error)
                ?.group(1) ??
            '',
      );
      if (attempt == null || attempt < 3) {
        return null;
      }
    }
    for (final p in profiles) {
      if (p['receipt'] == f.rceptNo &&
          p['corpCode'] == f.corpCode &&
          c.corpCode == f.corpCode &&
          c.id != null &&
          f.companyId == c.id &&
          p['year'] == f.bsnsYear &&
          p['consolidated'] == (div == FsDiv.consolidated) &&
          f.reportCode == FinancialReportCode.annual &&
          f.reportName == '사업보고서 (${p['year']}.12)' &&
          f.attempts >= 3 &&
          (div == FsDiv.consolidated
                  ? f.consolidatedStatus
                  : f.separateStatus) ==
              FilingFetchStatus.failed) {
        return p;
      }
    }
    return null;
  }

  Future<KnownAnnualSourceConflict> verify(
    DartFiling f,
    Company c,
    FsDiv div,
  ) async {
    final p = profile(f, c, div);
    if (p == null) {
      throw const FormatException('Conflict negative cache scope mismatch');
    }
    final manifest = await _read('$directory/manifest.json');
    if (sha256.convert(manifest).toString() != manifestSha) {
      throw const FormatException('Conflict manifest changed');
    }
    final basis = div == FsDiv.consolidated ? 'cfs' : 'ofs';
    Future<String> read(String label, String expected) async {
      final name = '${f.rceptNo}-$label.html';
      final bytes = await _read('$directory/$name');
      if (pins[name] != expected ||
          sha256.convert(bytes).toString() != expected) {
        throw const FormatException('Conflict source bytes changed');
      }
      return utf8.decode(bytes);
    }

    final cover = await read('cover', p['coverSha256'] as String);
    final body = await read(basis, p['statementSha256'] as String);
    try {
      KnownAnnualSourceConflicts.verify(
        receipt: f.rceptNo,
        corpCode: c.corpCode,
        consolidated: div == FsDiv.consolidated,
        start: DateTime.utc(f.bsnsYear!),
        end: DateTime.utc(f.bsnsYear!, 12, 31),
        coverSource: Uri.parse(p['coverSource'] as String),
        statementSource: Uri.parse(p['statementSource'] as String),
        coverHtml: cover,
        statementHtml: body,
      );
    } on KnownAnnualSourceConflict catch (e) {
      return KnownAnnualSourceConflict({
        ...e.evidence,
        'negativeCacheManifestSha256': manifestSha,
        'networkRequests': 0,
        'apiCalls': 0,
        'noData': false,
        'collectionComplete': false,
        'financialFactsStored': false,
        'readFromPinnedCache': true,
      });
    }
    throw const FormatException('Pinned conflict contract not recognized');
  }
}
