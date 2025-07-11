import 'package:flutter/painting.dart';
import 'package:phone_ide/highlight_engine/highlight_rules.dart';

/// Engine to highlight HTML (default), CSS, or JavaScript source.
class HighlightEngine {
  static final TextStyle defaultStyle = HighlightStyles.defaultStyle;
  static final TextStyle commentStyle = HighlightStyles.commentStyle;
  static final TextStyle stringStyle = HighlightStyles.stringStyle;
  static final TextStyle keywordStyle = HighlightStyles.keywordStyle;
  static final TextStyle tagStyle = HighlightStyles.tagStyle;
  static final TextStyle attrNameStyle = HighlightStyles.attrNameStyle;
  static final TextStyle cssPropStyle = HighlightStyles.cssPropStyle;
  static final TextStyle numberStyle = HighlightStyles.numberStyle;
  static final TextStyle cssSelectorStyle = HighlightStyles.cssSelectorStyle;
  static final TextStyle cssPropertyStyle = HighlightStyles.cssPropertyStyle;
  static final TextStyle cssValueStyle = HighlightStyles.cssValueStyle;

  /// Highlights [sourceCode] according to [language]: 'html', 'css', or 'js'.
  TextSpan highlight(String sourceCode, {String language = 'html'}) {
    switch (language.toLowerCase()) {
      case 'css':
        return _highlightCss(sourceCode);
      case 'js':
      case 'javascript':
        return _highlightJs(sourceCode);
      case 'html':
      default:
        return _highlightHtml(sourceCode);
    }
  }

  TextSpan _highlightHtml(String sourceCode) {
    final children = <TextSpan>[];
    final lines = sourceCode.split('\n');
    bool inStyle = false, inScript = false;
    int braceCount = 0;

    for (var line in lines) {
      if (!inStyle && !inScript) {
        if (_handleStyleOpen(line, children)) {
          inStyle = true;
          braceCount = 0;
        } else if (_handleScriptOpen(line, children)) {
          inScript = true;
        } else {
          children.addAll(_highlightLine(line, htmlRules));
          children.add(TextSpan(text: '\n', style: defaultStyle));
        }
      } else if (inStyle) {
        if (_handleStyleClose(line, children, braceCount)) {
          inStyle = false;
          braceCount = 0;
        } else {
          final rules = braceCount == 0 ? cssSelectorRules : cssPropertyRules;
          children.addAll(_highlightLine(line, rules));
          children.add(TextSpan(text: '\n', style: defaultStyle));
          braceCount += RegExp(r'\{').allMatches(line).length;
          braceCount -= RegExp(r'\}').allMatches(line).length;
        }
      } else {
        // inScript
        if (_handleScriptClose(line, children)) {
          inScript = false;
        } else {
          children.addAll(_highlightLine(line, jsRules));
          children.add(TextSpan(text: '\n', style: defaultStyle));
        }
      }
    }
    if (children.isNotEmpty && children.last.toPlainText() == '\n') {
      children.removeLast();
    }
    return TextSpan(style: defaultStyle, children: children);
  }

  TextSpan _highlightCss(String sourceCode) {
    final children = <TextSpan>[];
    int braceCount = 0;
    for (var line in sourceCode.split('\n')) {
      final rules = braceCount == 0 ? cssSelectorRules : cssPropertyRules;
      children.addAll(_highlightLine(line, rules));
      children.add(TextSpan(text: '\n', style: defaultStyle));
      braceCount += RegExp(r'\{').allMatches(line).length;
      braceCount -= RegExp(r'\}').allMatches(line).length;
    }
    if (children.isNotEmpty && children.last.toPlainText() == '\n') {
      children.removeLast();
    }
    return TextSpan(style: defaultStyle, children: children);
  }

  TextSpan _highlightJs(String sourceCode) {
    final children = <TextSpan>[];
    for (var line in sourceCode.split('\n')) {
      children.addAll(_highlightLine(line, jsRules));
      children.add(TextSpan(text: '\n', style: defaultStyle));
    }
    if (children.isNotEmpty && children.last.toPlainText() == '\n') {
      children.removeLast();
    }
    return TextSpan(style: defaultStyle, children: children);
  }

  bool _handleStyleOpen(String line, List<TextSpan> children) {
    final start = RegExp(r'<\s*style\b', caseSensitive: false);
    final end = RegExp(r'<\s*/\s*style\s*>', caseSensitive: false);
    if (start.hasMatch(line)) {
      children.addAll(_highlightLine(line, htmlRules));
      return !end.hasMatch(line);
    }
    return false;
  }

  bool _handleScriptOpen(String line, List<TextSpan> children) {
    final start = RegExp(r'<\s*script\b', caseSensitive: false);
    final end = RegExp(r'<\s*/\s*script\s*>', caseSensitive: false);
    if (start.hasMatch(line)) {
      children.addAll(_highlightLine(line, htmlRules));
      return !end.hasMatch(line);
    }
    return false;
  }

  bool _handleStyleClose(String line, List<TextSpan> children, int braceCount) {
    final end = RegExp(r'<\s*/\s*style\s*>', caseSensitive: false);
    if (end.hasMatch(line)) {
      children.addAll(_highlightLine(line, htmlRules));
      return true;
    }
    return false;
  }

  bool _handleScriptClose(String line, List<TextSpan> children) {
    final end = RegExp(r'<\s*/\s*script\s*>', caseSensitive: false);
    if (end.hasMatch(line)) {
      children.addAll(_highlightLine(line, htmlRules));
      return true;
    }
    return false;
  }

  List<TextSpan> _highlightLine(String line, List<HighlightRule> rules) {
    final spans = <TextSpan>[];
    var buffer = '';
    var i = 0;
    while (i < line.length) {
      var matched = false;
      for (final rule in rules) {
        final m = rule.regex.matchAsPrefix(line, i);
        if (m != null) {
          if (buffer.isNotEmpty) {
            spans.add(TextSpan(text: buffer, style: defaultStyle));
            buffer = '';
          }
          final token = m[0]!;
          spans.add(TextSpan(text: token, style: rule.style));
          i += token.length;
          matched = true;
          break;
        }
      }
      if (!matched) buffer += line[i++];
    }
    if (buffer.isNotEmpty) {
      spans.add(TextSpan(text: buffer, style: defaultStyle));
    }
    return spans;
  }
}
