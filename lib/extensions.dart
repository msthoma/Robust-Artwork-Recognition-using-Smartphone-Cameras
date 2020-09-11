import 'package:flutter/material.dart';

import 'lang/localization.dart';

extension Localization on BuildContext {
  /// Extension method on [BuildContext] that provides access to the localized
  /// list of strings generated by the flutter_sheet_localization library.
  AppLocalizations_Labels strings() => AppLocalizations.of(this);
}

extension CustomStringMethods on String {
  String customToUpperCase() {
    RegExp greek = RegExp(r'[α-ωΑ-Ω]');
    if (this.contains(greek)) {
      Map<String, String> greekAccentMap = Map.fromIterables(
        ["ά", "έ", "ή", "ί", "ό", "ύ", "ώ"],
        ["α", "ε", "η", "ι", "ο", "υ", "ω"],
      );

      return greekAccentMap.entries
          .fold(
              this.toLowerCase(),
              (String prev, MapEntry<String, String> vowelToReplace) =>
                  prev.replaceAll(vowelToReplace.key, vowelToReplace.value))
          .toUpperCase();
    }
    return this.toUpperCase();
  }
}
