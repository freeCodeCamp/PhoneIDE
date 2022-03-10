import 'package:flutter/material.dart';

class RegexMaps {
  static Map<RegExp, TextStyle> htmlRegexMap = <RegExp, TextStyle>{
    RegExp("<[^ \n]*"): const TextStyle(color: Colors.yellow),
    RegExp("</?.>"): const TextStyle(color: Colors.yellow),
    RegExp(">"): const TextStyle(color: Colors.yellow),
    RegExp('".*"'): TextStyle(color: Colors.orange[300]),
    RegExp('([A-Za-z-]*)='): TextStyle(color: Colors.green[300]),
  };
}
