import 'package:flutter/material.dart';
import 'package:flutter_code_editor/controller/language_controller/syntax/index.dart';

class TextEditingControllerIDE extends TextEditingController {
  TextEditingControllerIDE({
    Key? key,
    required this.syntax,
    required this.theme,
    required this.code,
  });

  Syntax syntax;
  SyntaxTheme theme;
  String code;

  @override
  TextSpan buildTextSpan(
      {required BuildContext context,
      TextStyle? style,
      required bool withComposing}) {
    return TextSpan(
        style: null, children: [getSyntax(syntax, theme).format(code)]);
  }
}
