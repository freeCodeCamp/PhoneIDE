import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/atom-one-dark-reasonable.dart';
import 'package:highlight/highlight.dart' show highlight, Node;

class TextEditingControllerIDE extends TextEditingController {
  TextEditingControllerIDE({Key? key, this.font, required this.language});

  final String language;
  final TextStyle? font;

  List<TextSpan> _convert(List<Node> nodes) {
    List<TextSpan> spans = [];
    var currentSpans = spans;
    List<List<TextSpan>> stack = [];

    traverse(Node node) {
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
          traverse(n);
          if (n == node.children!.last) {
            currentSpans = stack.isEmpty ? spans : stack.removeLast();
          }
        }
      }
    }

    for (var node in nodes) {
      traverse(node);
    }

    return spans;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    required bool withComposing,
    TextStyle? style,
  }) {
    String lower = language.toLowerCase();

    List<Node> nodes = highlight.parse(text, language: lower).nodes!;

    return TextSpan(
      style: style,
      children: _convert(nodes),
    );
  }
}
