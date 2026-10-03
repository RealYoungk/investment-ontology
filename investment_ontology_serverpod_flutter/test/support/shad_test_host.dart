import 'package:flutter/material.dart';
import 'package:shad/shad.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/research_desk_brand.dart';
import 'package:investment_ontology_serverpod_flutter/design/shad_theme.dart';

/// Tests use the same package theme ancestor as production.
Widget shadTestHost(Widget child) => ShadApp.custom(
  theme: buildServiceShadTheme(
    child is MaterialApp && child.theme != null
        ? child.theme!
        : buildAppTheme(researchDeskBrand),
  ),
  appBuilder: (context) => Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery.fromView(
      view: View.of(context),
      child: ShadToaster(child: child),
    ),
  ),
);
