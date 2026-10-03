import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/semantics.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shad/shad.dart';

import 'design/app_theme.dart';
import 'design/shad_theme.dart';
import 'design/compact_home_review.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final theme = buildAppTheme(serviceBrand);
  await GoogleFonts.pendingFonts();
  runApp(
    ShadApp.custom(
      theme: buildServiceShadTheme(theme),
      appBuilder: (context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: const CompactHomeReview(),
      ),
    ),
  );
  if (kIsWeb) SemanticsBinding.instance.ensureSemantics();
}
