import 'package:flutter/material.dart';
import 'package:shad/shad.dart';

import 'design/app_theme.dart';
import 'design/design_gallery.dart';
import 'design/shad_theme.dart';

/// Standalone service design preview: synthetic examples, no client or auth.
void main() {
  final theme = buildAppTheme(serviceBrand);
  runApp(
    ShadApp.custom(
      theme: buildServiceShadTheme(theme),
      appBuilder: (context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: const Scaffold(body: DesignGallery()),
      ),
    ),
  );
}
