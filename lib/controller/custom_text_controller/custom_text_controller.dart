import 'package:flutter/material.dart';
import 'package:flutter_code_editor/controller/language_controller/syntax/index.dart';

class TextEditingControllerIDE extends TextEditingController {
  TextEditingControllerIDE(
      {Key? key, required this.syntax, required this.theme, this.font});

  final Syntax syntax;
  final SyntaxTheme theme;
  final TextStyle? font;

  @override
  TextSpan buildTextSpan(
      {required BuildContext context,
      TextStyle? style,
      required bool withComposing}) {
    return TextSpan(
        style: style, children: [getSyntax(syntax, theme).format(text)]);
  }
}
