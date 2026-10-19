import 'package:flutter/material.dart';
import 'package:phone_ide/editor/editor_syntax_theme.dart';

class EditorOptions {
  EditorOptions({
    this.backgroundColor = const Color(0xFF2A2A40),
    this.regionOptions,
    this.linebarColor = const Color(0xFF3B3B4F),
    this.linebarTextColor = Colors.white,
    this.linebarBorderColor = const Color(0xFF888888),
    this.textColor = const Color(0xDDFFFFFF),
    this.cursorColor,
    this.selectionColor,
    this.selectionHandleColor,
    this.activeLineColor,
    this.activeLineBorderColor,
    this.diagnosticColor = const Color(0xFFD32F2F),
    this.diagnosticBackgroundColor = const Color(0x0FD32F2F),
    this.fontSize = 18,
    this.lineHeight = 1.5,
    this.linebarWidth = 28,
    this.syntaxTheme,
    this.showLinebar = true,
    this.takeFullHeight = true,
    this.isEditable = true,
    this.fontFamily,
  })  : assert(fontSize > 0),
        assert(lineHeight > 0),
        assert(linebarWidth >= 0);

  Color backgroundColor;
  Color linebarColor;
  Color linebarTextColor;
  Color linebarBorderColor;
  Color textColor;
  Color? cursorColor;
  Color? selectionColor;
  Color? selectionHandleColor;

  /// Optional background and 3 logical pixel leading stripe for the caret row.
  Color? activeLineColor;
  Color? activeLineBorderColor;
  Color diagnosticColor;
  Color diagnosticBackgroundColor;

  double fontSize;

  /// Line height as a multiple of [fontSize], before accessibility text scaling.
  double lineHeight;

  /// Minimum gutter width. It grows to fit longer numbers and larger text.
  double linebarWidth;

  /// Null retains the original Atom One Dark syntax colors.
  EditorSyntaxTheme? syntaxTheme;
  EditorRegionOptions? regionOptions;
  bool takeFullHeight;
  bool isEditable;
  bool showLinebar;
  String? fontFamily;
}

class EditorRegionOptions {
  EditorRegionOptions({
    required this.start,
    required this.end,
    this.color = const Color(0xFF0A0A23),
  });

  int? start;
  int? end;
  Color color;
}
