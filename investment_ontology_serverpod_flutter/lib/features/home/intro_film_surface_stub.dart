import 'package:flutter/material.dart';

import '../../design/tokens.dart';

class FilmSurface extends StatelessWidget {
  const FilmSurface({super.key, required this.progress, required this.reduced});
  final double progress;
  final bool reduced;
  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: context.colors.accentSubtle);
}
