import 'package:flutter/painting.dart';
import 'package:phone_ide/highlight_engine/highlight_rules.dart';

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

  TextSpan highlight(String sourceCode) {
    final List<TextSpan> children = [];
    final lines = sourceCode.split('\n');
    bool inStyleBlock = false;
    bool inScriptBlock = false;
    int cssBracesCount = 0;

    for (final line in lines) {
      if (!inStyleBlock && !inScriptBlock) {
        if (_handleStyleOpen(line, children)) {
          inStyleBlock = true;
          cssBracesCount = 0;
          continue;
        } else if (_handleScriptOpen(line, children)) {
          inScriptBlock = true;
          continue;
        } else {
          children.addAll(_highlightLine(line, htmlRules));
          children.add(TextSpan(text: '\n', style: defaultStyle));
        }
      } else if (inStyleBlock) {
        if (_handleStyleClose(line, children, cssBracesCount)) {
          inStyleBlock = false;
          cssBracesCount = 0;
          continue;
        }
        final activeRules =
            cssBracesCount == 0 ? cssSelectorRules : cssPropertyRules;
        children.addAll(_highlightLine(line, activeRules));
        children.add(TextSpan(text: '\n', style: defaultStyle));
        cssBracesCount += RegExp(r'\{').allMatches(line).length;
        cssBracesCount -= RegExp(r'\}').allMatches(line).length;
        if (cssBracesCount < 0) cssBracesCount = 0;
      } else if (inScriptBlock) {
        if (_handleScriptClose(line, children)) {
          inScriptBlock = false;
          continue;
        }
        children.addAll(_highlightLine(line, jsRules));
        children.add(TextSpan(text: '\n', style: defaultStyle));
      }
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
      if (end.hasMatch(line)) {
        final low = line.toLowerCase();
        final openEnd = low.indexOf('>');
        final closeStart = low.indexOf('</style');
        if (openEnd != -1 && closeStart != -1) {
          final openingTag = line.substring(0, openEnd + 1);
          final cssContent = line.substring(openEnd + 1, closeStart);
          final closingTag = line.substring(closeStart);
          children.addAll(_highlightLine(openingTag, htmlRules));
          if (cssContent.isNotEmpty) {
            children.addAll(_highlightLine(cssContent, cssPropertyRules));
          }
          children.addAll(_highlightLine(closingTag, htmlRules));
          children.add(TextSpan(text: '\n', style: defaultStyle));
          return true; // skip further processing
        }
      } else {
        children.addAll(_highlightLine(line, htmlRules));
        children.add(TextSpan(text: '\n', style: defaultStyle));
        return true;
      }
    }
    return false;
  }

  bool _handleScriptOpen(String line, List<TextSpan> children) {
    final start = RegExp(r'<\s*script\b', caseSensitive: false);
    final end = RegExp(r'<\s*/\s*script\s*>', caseSensitive: false);
    if (start.hasMatch(line)) {
      if (end.hasMatch(line)) {
        final low = line.toLowerCase();
        final openEnd = low.indexOf('>');
        final closeStart = low.indexOf('</script');
        if (openEnd != -1 && closeStart != -1) {
          final openingTag = line.substring(0, openEnd + 1);
          final jsContent = line.substring(openEnd + 1, closeStart);
          final closingTag = line.substring(closeStart);
          children.addAll(_highlightLine(openingTag, htmlRules));
          if (jsContent.isNotEmpty) {
            children.addAll(_highlightLine(jsContent, jsRules));
          }
          children.addAll(_highlightLine(closingTag, htmlRules));
          children.add(TextSpan(text: '\n', style: defaultStyle));
          return true;
        }
      } else {
        children.addAll(_highlightLine(line, htmlRules));
        children.add(TextSpan(text: '\n', style: defaultStyle));
        return true;
      }
    }
    return false;
  }

  bool _handleStyleClose(
      String line, List<TextSpan> children, int cssBracesCount) {
    final end = RegExp(r'<\s*/\s*style\s*>', caseSensitive: false);
    if (end.hasMatch(line)) {
      final low = line.toLowerCase();
      final idx = low.indexOf('</style');
      final cssPart = line.substring(0, idx);
      final closingTag = line.substring(idx);
      if (cssPart.isNotEmpty) {
        final activeRules =
            cssBracesCount == 0 ? cssSelectorRules : cssPropertyRules;
        children.addAll(_highlightLine(cssPart, activeRules));
      }
      children.addAll(_highlightLine(closingTag, htmlRules));
      children.add(TextSpan(text: '\n', style: defaultStyle));
      return true;
    }
    return false;
  }

  bool _handleScriptClose(String line, List<TextSpan> children) {
    final end = RegExp(r'<\s*/\s*script\s*>', caseSensitive: false);
    if (end.hasMatch(line)) {
      final low = line.toLowerCase();
      final idx = low.indexOf('</script');
      final jsPart = line.substring(0, idx);
      final closingTag = line.substring(idx);
      if (jsPart.isNotEmpty) {
        children.addAll(_highlightLine(jsPart, jsRules));
      }
      children.addAll(_highlightLine(closingTag, htmlRules));
      children.add(TextSpan(text: '\n', style: defaultStyle));
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
