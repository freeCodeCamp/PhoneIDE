import 'package:flutter/painting.dart';

// Styles for syntax highlighting
class HighlightStyles {
  static const TextStyle defaultStyle = TextStyle(color: Color(0xFFFFFFFF));
  static const TextStyle commentStyle = TextStyle(
    color: Color(0xFF999999),
    fontStyle: FontStyle.italic,
  );
  static const TextStyle stringStyle = TextStyle(color: Color(0xFF98C379));
  static const TextStyle keywordStyle = TextStyle(color: Color(0xFF569CD6));
  static const TextStyle tagStyle = TextStyle(color: Color(0xFFE06C75));
  static const TextStyle attrNameStyle = TextStyle(color: Color(0xFFD19A66));
  static const TextStyle cssPropStyle = TextStyle(color: Color(0xFFC678DD));
  static const TextStyle numberStyle = TextStyle(color: Color(0xFF56B6C2));
  static const TextStyle cssSelectorStyle = TextStyle(color: Color(0xFFE06C75));
  static const TextStyle cssPropertyStyle = TextStyle(color: Color(0xFF61AFEF));
  static const TextStyle cssValueStyle = TextStyle(color: Color(0xFF98C379));
}

class HighlightRule {
  final RegExp regex;
  final TextStyle style;
  const HighlightRule(this.regex, this.style);
}

// HTML rules
final List<HighlightRule> htmlRules = [
  HighlightRule(RegExp(r'<!--[\s\S]*?-->', multiLine: true, dotAll: true),
      HighlightStyles.commentStyle),
  HighlightRule(RegExp(r'(?<!style=)"([^"\\]|\\.)*"', multiLine: true),
      HighlightStyles.stringStyle),
  HighlightRule(RegExp(r"(?<!style=)'([^'\\]|\\.)*'", multiLine: true),
      HighlightStyles.stringStyle),
  HighlightRule(
      RegExp(r'(?<=<[^>]*\s)[^=\s>]+(?==)'), HighlightStyles.attrNameStyle),
  HighlightRule(RegExp(r'(?<=</?)(?![!])[^>\s/]+'), HighlightStyles.tagStyle),
  HighlightRule(RegExp(r'\b\d+(\.\d+)?\b'), HighlightStyles.numberStyle),
];

// CSS selector rules
final List<HighlightRule> cssSelectorRules = [
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

// CSS property rules
final List<HighlightRule> cssPropertyRules = [
  HighlightRule(RegExp(r'/\*[\s\S]*?\*/', multiLine: true, dotAll: true),
      HighlightStyles.commentStyle),
  HighlightRule(RegExp(r'//.*'), HighlightStyles.commentStyle),
  HighlightRule(
      RegExp(r'"([^"\\]|\\.)*"', multiLine: true), HighlightStyles.stringStyle),
  HighlightRule(RegExp(r"'([^'\\]|\\.)*'"), HighlightStyles.stringStyle),
  HighlightRule(RegExp(r'[\w-]+(?=\s*:)'), HighlightStyles.cssPropertyStyle),
  HighlightRule(
      RegExp(r'\b#(?:[0-9A-Fa-f]{3}){1,2}\b'), HighlightStyles.cssValueStyle),
  HighlightRule(RegExp(r'\b-?\d+(\.\d+)?(?:%|[a-zA-Z]+)\b'),
      HighlightStyles.cssValueStyle),
  HighlightRule(RegExp(r'\b-?\d+(\.\d+)?\b'), HighlightStyles.cssValueStyle),
  HighlightRule(RegExp(r'\b[A-Za-z_-][\w-]*\b'), HighlightStyles.cssValueStyle),
];

// JavaScript rules
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
      HighlightStyles.keywordStyle),
  HighlightRule(RegExp(r'\b\d+(\.\d+)?\b'), HighlightStyles.numberStyle),
];
