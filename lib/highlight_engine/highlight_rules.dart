import 'package:flutter/painting.dart';

/// A simple pair of regex + style.
class HighlightRule {
  final RegExp regex;
  final TextStyle style;
  const HighlightRule(this.regex, this.style);
}

/// All of your text styles, including new ones for JS identifiers and CSS integers.
class HighlightStyles {
  static const TextStyle defaultStyle = TextStyle(color: Color(0xFFFFFFFF));
  static const TextStyle commentStyle =
      TextStyle(color: Color(0xFF999999), fontStyle: FontStyle.italic);
  static const TextStyle stringStyle = TextStyle(color: Color(0xFF98C379));
  static const TextStyle keywordStyle = TextStyle(color: Color(0xFF569CD6));
  static const TextStyle tagStyle = TextStyle(color: Color(0xFFE06C75));
  static const TextStyle attrNameStyle = TextStyle(color: Color(0xFFD19A66));
  static const TextStyle cssPropStyle = TextStyle(color: Color(0xFFC678DD));
  static const TextStyle numberStyle = TextStyle(color: Color(0xFF56B6C2));
  static const TextStyle cssSelectorStyle = TextStyle(color: Color(0xFFE06C75));
  static const TextStyle cssPropertyStyle = TextStyle(color: Color(0xFF61AFEF));
  static const TextStyle cssValueStyle = TextStyle(color: Color(0xFF98C379));

  static const TextStyle jsIdentifierStyle =
      TextStyle(color: Color(0xFF9CDCFE));

  static const TextStyle cssIntegerStyle = TextStyle(color: Color(0xFFE5C07B));
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

/// CSS selectors (outside of braces)
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

/// CSS properties & values (inside braces)
final List<HighlightRule> cssPropertyRules = [
  // 1) Comments
  HighlightRule(RegExp(r'/\*[\s\S]*?\*/', multiLine: true, dotAll: true),
      HighlightStyles.commentStyle),
  HighlightRule(RegExp(r'//.*'), HighlightStyles.commentStyle),

  // 2) Strings
  HighlightRule(
      RegExp(r'"([^"\\]|\\.)*"', multiLine: true), HighlightStyles.stringStyle),
  HighlightRule(RegExp(r"'([^'\\]|\\.)*'"), HighlightStyles.stringStyle),

  // 3) Property names
  HighlightRule(RegExp(r'[\w-]+(?=\s*:)'), HighlightStyles.cssPropertyStyle),

  // 4) Hex colors
  HighlightRule(RegExp(r'#[0-9A-Fa-f]{3,6}'), HighlightStyles.cssValueStyle),

  // 5) Unit-bearing and percentage values (including %, px, em, rem, vh, etc.)
  HighlightRule(RegExp(r'-?\d+(?:\.\d+)?(?:%|[a-zA-Z]+)'),
      HighlightStyles.cssIntegerStyle),

  // 6) Integer-only values (no units)
  HighlightRule(RegExp(r'\b-?\d+\b'), HighlightStyles.cssIntegerStyle),

  // 7) Keywords in values (e.g. red, solid, block)
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
      RegExp(r'\b[A-Za-z_$][\w$]*\b'), HighlightStyles.jsIdentifierStyle),
  HighlightRule(RegExp(r'\b\d+(?:\.\d+)?\b'), HighlightStyles.numberStyle),
];
