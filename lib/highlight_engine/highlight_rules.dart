import 'package:flutter/painting.dart';

/// A simple pair of regex + style.
class HighlightRule {
  final RegExp regex;
  final TextStyle style;
  const HighlightRule(this.regex, this.style);
}

/// Atom One Dark–inspired text styles for HTML, CSS, and JS.
class HighlightStyles {
  static const TextStyle defaultStyle =
      TextStyle(color: Color.fromARGB(255, 255, 255, 255));
  static const TextStyle commentStyle =
      TextStyle(color: Color(0xFF5C6370), fontStyle: FontStyle.italic);
  static const TextStyle stringStyle = TextStyle(color: Color(0xFF98C379));
  static const TextStyle keywordStyle = TextStyle(color: Color(0xFFC678DD));
  static const TextStyle tagStyle = TextStyle(color: Color(0xFFE06C75));
  static const TextStyle attrNameStyle = TextStyle(color: Color(0xFFD19A66));
  static const TextStyle cssPropStyle = TextStyle(color: Color(0xFF61AFEF));
  static const TextStyle numberStyle = TextStyle(color: Color(0xFFD19A66));
  static const TextStyle cssSelectorStyle = TextStyle(color: Color(0xFF56B6C2));
  static const TextStyle cssPropertyStyle = TextStyle(color: Color(0xFF61AFEF));
  static const TextStyle cssValueStyle = TextStyle(color: Color(0xFF98C379));
  static const TextStyle jsIdentifierStyle =
      TextStyle(color: Color(0xFF56B6C2));
  static const TextStyle cssAtRuleStyle = TextStyle(color: Color(0xFF56B6C2));
  static const TextStyle cssFunctionStyle = TextStyle(color: Color(0xFF61AFEF));
  static const TextStyle functionStyle = TextStyle(color: Color(0xFF61AFEF));
}

/// HTML rules (outside of <style> or <script>)
final List<HighlightRule> htmlRules = [
  HighlightRule(RegExp(r'<!--[\s\S]*?-->', multiLine: true, dotAll: true),
      HighlightStyles.commentStyle),
  HighlightRule(RegExp(r'<!DOCTYPE[^>]*>', caseSensitive: false),
      HighlightStyles.tagStyle),
  HighlightRule(RegExp(r'(?<!style=)"([^"\\]|\\.)*"', multiLine: true),
      HighlightStyles.stringStyle),
  HighlightRule(RegExp(r"(?<!style=)'([^'\\]|\\.)*'", multiLine: true),
      HighlightStyles.stringStyle),
  HighlightRule(
      RegExp(r'(?<=<[^>]*\s)[^=\s>]+(?=\=)'), HighlightStyles.attrNameStyle),
  HighlightRule(RegExp(r'(?<=</?)(?![!])[^>\s/]+'), HighlightStyles.tagStyle),
];

/// CSS selectors and at-rules (outside of braces)
final List<HighlightRule> cssSelectorRules = [
  HighlightRule(RegExp(r'@[A-Za-z_-]+'), HighlightStyles.cssAtRuleStyle),
  HighlightRule(
      RegExp(r'\b[A-Za-z_-][\w-]*(?=\()'), HighlightStyles.cssFunctionStyle),
  HighlightRule(RegExp(r'/\*[\s\S]*?\*/', multiLine: true, dotAll: true),
      HighlightStyles.commentStyle),
  HighlightRule(RegExp(r'//.*'), HighlightStyles.commentStyle),
  HighlightRule(
      RegExp(r'"([^"\\]|\\.)*"', multiLine: true), HighlightStyles.stringStyle),
  HighlightRule(RegExp(r"'([^'\\]|\\.)*'"), HighlightStyles.stringStyle),
  HighlightRule(
      RegExp(r'\.[A-Za-z_-][\w-]*'), HighlightStyles.cssSelectorStyle),
  HighlightRule(
      RegExp(r'\#[A-Za-z_-][\w-]*'), HighlightStyles.cssSelectorStyle),
  HighlightRule(
      RegExp(r'\:\:[A-Za-z_-][\w-]*'), HighlightStyles.cssSelectorStyle),
  HighlightRule(
      RegExp(r'\:[A-Za-z_-][\w-]*'), HighlightStyles.cssSelectorStyle),
  HighlightRule(RegExp(r'\*'), HighlightStyles.cssSelectorStyle),
  HighlightRule(
      RegExp(r'\b[A-Za-z_-][\w-]*\b'), HighlightStyles.cssSelectorStyle),
];

/// CSS properties, values, functions, variables, and at-rules inside braces
final List<HighlightRule> cssPropertyRules = [
  HighlightRule(RegExp(r'@[A-Za-z_-]+'), HighlightStyles.cssAtRuleStyle),
  HighlightRule(
      RegExp(r'--[A-Za-z_-][\w-]*'), HighlightStyles.jsIdentifierStyle),
  HighlightRule(
      RegExp(r'\b[A-Za-z_-][\w-]*(?=\()'), HighlightStyles.cssFunctionStyle),
  HighlightRule(RegExp(r'/\*[\s\S]*?\*/', multiLine: true, dotAll: true),
      HighlightStyles.commentStyle),
  HighlightRule(RegExp(r'//.*'), HighlightStyles.commentStyle),
  HighlightRule(
      RegExp(r'"([^"\\]|\\.)*"', multiLine: true), HighlightStyles.stringStyle),
  HighlightRule(RegExp(r"'([^'\\]|\\.)*'"), HighlightStyles.stringStyle),
  HighlightRule(RegExp(r'[\w-]+(?=\s*:)'), HighlightStyles.cssPropertyStyle),
  HighlightRule(RegExp(r'#[0-9A-Fa-f]{3,6}'), HighlightStyles.cssValueStyle),
  HighlightRule(
      RegExp(r'-?\d+(?:\.\d+)?(?:%|[a-zA-Z]+)'), HighlightStyles.numberStyle),
  HighlightRule(RegExp(r'\b-?\d+\b'), HighlightStyles.numberStyle),
  HighlightRule(RegExp(r'\b[A-Za-z_-][\w-]*\b'), HighlightStyles.cssValueStyle),
];

/// JavaScript rules (inside <script>)
final List<HighlightRule> jsRules = [
  HighlightRule(RegExp(r'/\*[\s\S]*?\*/', multiLine: true, dotAll: true),
      HighlightStyles.commentStyle),
  HighlightRule(RegExp(r'//.*'), HighlightStyles.commentStyle),
  HighlightRule(
      RegExp(r'"([^"\\]|\\.)*"', multiLine: true), HighlightStyles.stringStyle),
  HighlightRule(RegExp(r"'([^'\\]|\\.)*'"), HighlightStyles.stringStyle),
  HighlightRule(
    RegExp(
        r'\b(?:if|else|for|while|break|continue|return|function|var|let|const|new|try|catch|finally|throw|class|extends|implements|switch|case|default|in|typeof|instanceof|true|false|null|async|await)\b'),
    HighlightStyles.keywordStyle,
  ),
  HighlightRule(
      RegExp(r'\b[A-Za-z_$][\w$]*(?=\()'), HighlightStyles.functionStyle),
  HighlightRule(
      RegExp(r'\b[A-Za-z_$][\w$]*\b'), HighlightStyles.jsIdentifierStyle),
  HighlightRule(RegExp(r'\b\d+(?:\.\d+)?\b'), HighlightStyles.numberStyle),
];
