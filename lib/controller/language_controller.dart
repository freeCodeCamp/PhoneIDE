import 'package:flutter/material.dart';
import 'package:flutter_code_editor/enums/language.dart';
import 'package:flutter_code_editor/language_maps/maps.dart';

class LanguageController {
  static Map<RegExp, TextStyle> provideLanguageMap(Language lang) {
    switch (lang) {
      case Language.html:
        return RegexMaps.htmlRegexMap;
      case Language.javaScript:
        return <RegExp, TextStyle>{};
      default:
        throw Exception('could not find provided language');
    }
  }
}
