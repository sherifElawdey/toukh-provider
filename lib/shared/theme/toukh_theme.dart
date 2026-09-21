import 'package:flutter/material.dart';

import 'app_theme.dart';

abstract final class ToukhTheme {
  static ThemeData light() => buildAppTheme();

  static ThemeData dark() => buildAppDarkTheme();
}
