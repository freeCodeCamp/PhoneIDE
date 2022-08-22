import 'package:flutter/material.dart';
import 'package:flutter_code_editor/controller/language_controller/syntax/index.dart';
import 'package:flutter_highlight/themes/atom-one-dark-reasonable.dart';
import 'package:string_scanner/string_scanner.dart';
import 'package:highlight/highlight.dart' show highlight, Node;

class HTMLSyntaxHighlighter extends SyntaxBase {
  HTMLSyntaxHighlighter([this.syntaxTheme]) {
    _spans = <HighlightSpan>[];
    syntaxTheme ??= SyntaxTheme.vscodeDark();
  }

  @override
  Syntax get type => Syntax.HTML;

  @override
  SyntaxTheme? syntaxTheme;

  late String _src;
  late StringScanner _scanner;

  late List<HighlightSpan> _spans;

  List<TextSpan> _convert(List<Node> nodes) {
    List<TextSpan> spans = [];
    var currentSpans = spans;
    List<List<TextSpan>> stack = [];

    _traverse(Node node) {
      if (node.value != null) {
        currentSpans.add(node.className == null
            ? TextSpan(text: node.value)
            : TextSpan(
                text: node.value,
                style: atomOneDarkReasonableTheme[node.className!]));
      } else if (node.children != null) {
        List<TextSpan> tmp = [];
        currentSpans.add(TextSpan(
            children: tmp, style: atomOneDarkReasonableTheme[node.className!]));
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
  TextSpan format(String src) {
    _src = src;
    _scanner = StringScanner(_src);

    if (_generateSpans()) {
      /// Successfully parsed the code
      final List<TextSpan> formattedText = <TextSpan>[];
      int currentPosition = 0;

      for (HighlightSpan span in _spans) {
        if (currentPosition > span.start) continue;
        if (currentPosition != span.start) {
          formattedText.add(
            TextSpan(
              text: _src.substring(currentPosition, span.start),
            ),
          );
        }

        formattedText.add(TextSpan(
          style: span.textStyle(syntaxTheme),
          text: span.textForSpan(_src),
        ));

        currentPosition = span.end;
      }

      if (currentPosition != _src.length) {
        formattedText.add(TextSpan(
          text: _src.substring(currentPosition, _src.length),
        ));
      }

      return TextSpan(
        children: _convert(highlight.parse(_src, language: 'html').nodes!),
      );
    } else {
      /// Parsing failed, return with only basic formatting
      return TextSpan(
        children: _convert(highlight.parse(_src, language: 'css').nodes!),
      );
    }
  }

  bool _generateSpans() {
    int lastLoopPosition = _scanner.position;

    while (!_scanner.isDone) {
      _scanner.scan(RegExp(r'\s+'));

      if (_scanner.scan(RegExp(r'<!--(?:(?!<!--)[\s\S])*?-->'))) {
        _spans.add(HighlightSpan(HighlightType.comment,
            _scanner.lastMatch!.start, _scanner.lastMatch!.end));
        continue;
      }

      if (_scanner.scan(RegExp(r'"[^"]*"'))) {
        _spans.add(HighlightSpan(HighlightType.string,
            _scanner.lastMatch!.start, _scanner.lastMatch!.end));
      }

      if (_scanner.scan(RegExp(r'<[^> \n]*'))) {
        _spans.add(HighlightSpan(HighlightType.keyword,
            _scanner.lastMatch!.start, _scanner.lastMatch!.end));
        continue;
      }

      if (_scanner.scan(RegExp(r'\/?>'))) {
        _spans.add(HighlightSpan(HighlightType.keyword,
            _scanner.lastMatch!.start, _scanner.lastMatch!.end));
        continue;
      }

      if (_scanner.scan(RegExp(r'{'))) {
        _spans.add(HighlightSpan(HighlightType.punctuation,
            _scanner.lastMatch!.start, _scanner.lastMatch!.end));
        continue;
      }

      if (_scanner.scan(RegExp(r'}'))) {
        _spans.add(HighlightSpan(HighlightType.punctuation,
            _scanner.lastMatch!.start, _scanner.lastMatch!.end));
        continue;
      }

      if (_scanner.scan(RegExp(r';'))) {
        _spans.add(HighlightSpan(HighlightType.punctuation,
            _scanner.lastMatch!.start, _scanner.lastMatch!.end));
        continue;
      }

      if (_scanner.scan(RegExp(r'(\s*[A-Za-z]*)='))) {
        _spans.add(HighlightSpan(HighlightType.constant,
            _scanner.lastMatch!.start, _scanner.lastMatch!.end));
        continue;
      }

      if (_scanner.scan(RegExp(r'([\-A-Za-z]*):'))) {
        _spans.add(HighlightSpan(HighlightType.constant,
            _scanner.lastMatch!.start, _scanner.lastMatch!.end));
        continue;
      }

      if (_scanner.scan(RegExp(r'[\#\.\w\-\,\s\n\r\t:]+(?=\s*\{)'))) {
        _spans.add(HighlightSpan(HighlightType.string,
            _scanner.lastMatch!.start, _scanner.lastMatch!.end));
        continue;
      }

      /// Words
      if (_scanner.scan(RegExp(r'[^<>/{}]*'))) {
        HighlightType? type;

        String word = _scanner.lastMatch![0]!;

        if (type != null) {
          _spans.add(HighlightSpan(
              type, _scanner.lastMatch!.start, _scanner.lastMatch!.end));
        }
      }

      /// Check if this loop did anything
      if (lastLoopPosition == _scanner.position) {
        /// Failed to parse this file, abort gracefully
        return false;
      }

      lastLoopPosition = _scanner.position;
    }
    _simplify();
    return true;
  }

  void _simplify() {
    for (int i = _spans.length - 2; i >= 0; i -= 1) {
      if (_spans[i].type == _spans[i + 1].type &&
          _spans[i].end == _spans[i + 1].start) {
        _spans[i] =
            HighlightSpan(_spans[i].type, _spans[i].start, _spans[i + 1].end);
        _spans.removeAt(i + 1);
      }
    }
  }
}
