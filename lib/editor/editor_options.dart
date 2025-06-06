import 'package:flutter/material.dart';

class EditorOptions {
  EditorOptions({
    this.backgroundColor = const Color.fromRGBO(0x2a, 0x2a, 0x40, 1),
    this.regionOptions,
    this.linebarColor = const Color.fromRGBO(0x3b, 0x3b, 0x4f, 1),
    this.linebarTextColor = Colors.white,
    this.showLinebar = true,
    this.takeFullHeight = true,
    this.isEditable = true,
    this.fontFamily,
  });

  // [backgroundColor] is the background color of the editor.

  Color backgroundColor;

  // [linebarColor] is the background color of the linebar.

  Color linebarColor;

  // [linebarTextColor] is the text color of the linebar.

  Color linebarTextColor;

  // If the file has a region these are the options that are available
  EditorRegionOptions? regionOptions;

  // Should take all available vertical height
  bool takeFullHeight;

  // Control if the text in the editor is editable
  bool isEditable;

  // Hide or Show the linebar
  bool showLinebar;

  String? fontFamily;
}

class EditorRegionOptions {
  EditorRegionOptions({
    required this.start,
    required this.end,
    this.color = const Color.fromRGBO(0x0a, 0x0a, 0x23, 1),
  });

  // [start] is the start line of the region.

  int? start;

  // [end] is the end line of the region.
  int? end;

  // [color] is the background color of the region.

  Color color;
}
