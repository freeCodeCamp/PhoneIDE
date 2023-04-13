import 'package:flutter/material.dart';

class EditorOptions {
  EditorOptions({
    this.editorBackgroundColor = const Color.fromRGBO(0x2a, 0x2a, 0x40, 1),
    this.linebarColor = const Color.fromRGBO(0x3b, 0x3b, 0x4f, 1),
    this.linebarTextColor = Colors.white,
    this.hasRegion = false,
  });

  Color editorBackgroundColor;

  Color linebarColor;

  Color linebarTextColor;

  bool hasRegion;
}

class EditorRegionOptions {
  EditorRegionOptions({
    required this.start,
    required this.end,
    this.color = const Color.fromRGBO(0x0a, 0x0a, 0x23, 1),
    this.condition = false,
  });

  int? start;
  int? end;
  Color color;
  bool condition;
}
