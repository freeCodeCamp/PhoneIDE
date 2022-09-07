import 'package:flutter/material.dart';
import 'package:flutter_code_editor/enums/syntax.dart';
import 'package:flutter_highlight/themes/atom-one-dark-reasonable.dart';
import 'package:highlight/highlight.dart' show highlight, Node;

class TextEditingControllerIDE extends TextEditingController {
  TextEditingControllerIDE({Key? key, this.font});

  static String language = 'HTML';
  final TextStyle? font;

  List<TextSpan> _convert(List<Node> nodes) {
    List<TextSpan> spans = [];
    var currentSpans = spans;
    List<List<TextSpan>> stack = [];

    _traverse(Node node) {
      if (node.value != null) {
        currentSpans.add(
          node.className == null
              ? TextSpan(text: node.value)
              : TextSpan(
                  text: node.value,
                  style: atomOneDarkReasonableTheme[node.className!],
                ),
        );
      } else if (node.children != null) {
        List<TextSpan> tmp = [];
        currentSpans.add(
          TextSpan(
            children: tmp,
            style: atomOneDarkReasonableTheme[node.className!],
          ),
        );
        stack.add(currentSpans);
        currentSpans = tmp;

        for (var n in node.children!) {
          _traverse(n);
          if (n == node.children!.last) {
            currentSpans = stack.isEmpty ? spans : stack.removeLast();
          }
        }
      }
    }

    for (var node in nodes) {
      _traverse(node);
    }

    return spans;
  }

  @override
  TextSpan buildTextSpan(
      {required BuildContext context,
      TextStyle? style,
      required bool withComposing}) {
    Syntax syntax =
        Syntax.values.firstWhere((s) => s.name == language.toUpperCase());
    var nodes =
        highlight.parse(text, language: syntax.name.toLowerCase()).nodes!;
    return TextSpan(style: style, children: _convert(nodes));
  }
}
