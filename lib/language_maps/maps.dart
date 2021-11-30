import 'package:flutter/material.dart';

class RegexMaps {
  static Map<RegExp, TextStyle> htmlRegexMap = <RegExp, TextStyle>{
    RegExp('<\/?([a-z]{1,10})([0-9]{0,2})\>?'):
        const TextStyle(color: Colors.yellow),
    RegExp('<'): const TextStyle(color: Colors.yellow),
    RegExp('>'): const TextStyle(color: Colors.yellow),
    RegExp('"([a-zA-Z0-9\-\.\=\,\:\/]*"*)'):
        TextStyle(color: Colors.orange[300]),
    RegExp('([A-Za-z\-]*)\='): TextStyle(color: Colors.green[300])
  };
}
