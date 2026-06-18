import 'package:flutter/material.dart';
import '../config/app_localizations.dart';

extension BuildContextLocalization on BuildContext {
  String tr(String key) {
    return AppLocalizations.of(this).translate(key);
  }
}
