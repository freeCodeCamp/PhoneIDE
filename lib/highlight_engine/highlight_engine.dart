import 'package:flutter/painting.dart';
import 'package:phone_ide/highlight_engine/highlight_rules.dart';

class HighlightEngine {
  // Use styles from HighlightStyles
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

  /// Highlights the given source code and returns a TextSpan containing styled children.
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
        }
        if (_handleScriptOpen(line, children)) {
          inScriptBlock = true;
          continue;
        }
        if (_handleStyleOrScriptClose(line, children)) {
          inStyleBlock = false;
          inScriptBlock = false;
          cssBracesCount = 0;
          continue;
        }
        children.addAll(_highlightLine(line, htmlRules));
        children.add(TextSpan(text: '\n', style: defaultStyle));
      } else if (inStyleBlock) {
        if (_handleStyleClose(line, children, cssBracesCount)) {
          inStyleBlock = false;
          cssBracesCount = 0;
          continue;
        }
        final activeRules =
            (cssBracesCount == 0) ? cssSelectorRules : cssPropertyRules;
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
    // Remove final newline TextSpan if present
    if (children.isNotEmpty && children.last.toPlainText() == '\n') {
      children.removeLast();
    }
    return TextSpan(style: defaultStyle, children: children);
  }

  // Helper for opening <style> tag
  bool _handleStyleOpen(String line, List<TextSpan> children) {
    final styleOpen = RegExp(r'<\s*style\b', caseSensitive: false);
    final styleClose = RegExp(r'<\s*/\s*style\s*>', caseSensitive: false);
    if (styleOpen.hasMatch(line)) {
      if (styleClose.hasMatch(line)) {
        int openTagEnd = line.toLowerCase().indexOf('>');
        int closeTagStart = line.toLowerCase().indexOf('</style');
        if (openTagEnd != -1 && closeTagStart != -1) {
          String openingTag = line.substring(0, openTagEnd + 1);
          String cssContent = line.substring(openTagEnd + 1, closeTagStart);
          String closingTag = line.substring(closeTagStart);
          children.addAll(_highlightLine(openingTag, htmlRules));
          if (cssContent.isNotEmpty) {
            children.addAll(_highlightLine(cssContent, cssPropertyRules));
          }
          children.addAll(_highlightLine(closingTag, htmlRules));
          children.add(TextSpan(text: '\n', style: defaultStyle));
          return false;
        }
      } else {
        children.addAll(_highlightLine(line, htmlRules));
        children.add(TextSpan(text: '\n', style: defaultStyle));
        return true;
      }
    }
    return false;
  }

  // Helper for opening <script> tag
  bool _handleScriptOpen(String line, List<TextSpan> children) {
    final scriptOpen = RegExp(r'<\s*script\b', caseSensitive: false);
    final scriptClose = RegExp(r'<\s*/\s*script\s*>', caseSensitive: false);
    if (scriptOpen.hasMatch(line)) {
      if (scriptClose.hasMatch(line)) {
        int openTagEnd = line.toLowerCase().indexOf('>');
        int closeTagStart = line.toLowerCase().indexOf('</script');
        if (openTagEnd != -1 && closeTagStart != -1) {
          String openingTag = line.substring(0, openTagEnd + 1);
          String jsContent = line.substring(openTagEnd + 1, closeTagStart);
          String closingTag = line.substring(closeTagStart);
          children.addAll(_highlightLine(openingTag, htmlRules));
          if (jsContent.isNotEmpty) {
            children.addAll(_highlightLine(jsContent, jsRules));
          }
          children.addAll(_highlightLine(closingTag, htmlRules));
          children.add(TextSpan(text: '\n', style: defaultStyle));
          return false;
        }
      } else {
        children.addAll(_highlightLine(line, htmlRules));
        children.add(TextSpan(text: '\n', style: defaultStyle));
        return true;
      }
    }
    return false;
  }

  // Helper for closing <style> or <script> tags
  bool _handleStyleOrScriptClose(String line, List<TextSpan> children) {
    final styleClose = RegExp(r'<\s*/\s*style\s*>', caseSensitive: false);
    final scriptClose = RegExp(r'<\s*/\s*script\s*>', caseSensitive: false);
    if (styleClose.hasMatch(line) || scriptClose.hasMatch(line)) {
      children.addAll(_highlightLine(line, htmlRules));
      children.add(TextSpan(text: '\n', style: defaultStyle));
      return true;
    }
    return false;
  }

  // Helper for closing </style> tag
  bool _handleStyleClose(
      String line, List<TextSpan> children, int cssBracesCount) {
    final styleClose = RegExp(r'<\s*/\s*style\s*>', caseSensitive: false);
    if (styleClose.hasMatch(line)) {
      int closeTagIndex = line.toLowerCase().indexOf('</style');
      String cssPart = line.substring(0, closeTagIndex);
      String closingTag = line.substring(closeTagIndex);
      if (cssPart.isNotEmpty) {
        final activeRules =
            (cssBracesCount == 0) ? cssSelectorRules : cssPropertyRules;
        children.addAll(_highlightLine(cssPart, activeRules));
      }
      children.addAll(_highlightLine(closingTag, htmlRules));
      children.add(TextSpan(text: '\n', style: defaultStyle));
      return true;
    }
    return false;
  }

  // Helper for closing </script> tag
  bool _handleScriptClose(String line, List<TextSpan> children) {
    final scriptClose = RegExp(r'<\s*/\s*script\s*>', caseSensitive: false);
    if (scriptClose.hasMatch(line)) {
      int closeTagIndex = line.toLowerCase().indexOf('</script');
      String jsPart = line.substring(0, closeTagIndex);
      String closingTag = line.substring(closeTagIndex);
      if (jsPart.isNotEmpty) {
        children.addAll(_highlightLine(jsPart, jsRules));
      }
      children.addAll(_highlightLine(closingTag, htmlRules));
      children.add(TextSpan(text: '\n', style: defaultStyle));
      return true;
    }
    return false;
  }

  /// Highlights a single line of code with the given rules, returning a list of TextSpans.
  List<TextSpan> _highlightLine(String line, List<HighlightRule> rules) {
    List<TextSpan> spans = [];
    String buffer = '';
    int i = 0;
    while (i < line.length) {
      bool tokenMatched = false;
      for (final rule in rules) {
        final Match? m = rule.regex.matchAsPrefix(line, i);
        if (m != null) {
          String token = m[0]!;
          // Special handling: style="...": Highlight CSS inside the attribute
          if (rule.style == attrNameStyle && token.toLowerCase() == 'style') {
            // Flush any text before "style"
            if (buffer.isNotEmpty) {
              spans.add(TextSpan(text: buffer, style: defaultStyle));
              buffer = '';
            }
            // Add the "style" attribute name
            spans.add(TextSpan(text: token, style: attrNameStyle));
            i += token.length;
            // Capture '=' and any whitespace
            while (i < line.length && line[i].trim().isEmpty) {
              buffer += line[i++];
            }
            if (i < line.length && line[i] == '=') {
              buffer += line[i++];
            }
            while (i < line.length && line[i].trim().isEmpty) {
              buffer += line[i++];
            }
            // Now at the opening quote of the style attribute's value
            if (i < line.length && (line[i] == '"' || line[i] == '\'')) {
              String quote = line[i];
              buffer += quote;
              i++;
              // Highlight CSS content inside the quotes
              while (i < line.length && line[i] != quote) {
                bool innerMatched = false;
                for (final innerRule in cssPropertyRules) {
                  final Match? innerM = innerRule.regex.matchAsPrefix(line, i);
                  if (innerM != null) {
                    String innerToken = innerM[0]!;
                    if (buffer.isNotEmpty) {
                      spans.add(TextSpan(text: buffer, style: defaultStyle));
                      buffer = '';
                    }
                    spans.add(
                        TextSpan(text: innerToken, style: innerRule.style));
                    i += innerToken.length;
                    innerMatched = true;
                    break;
                  }
                }
                if (!innerMatched) {
                  buffer += line[i++];
                }
              }
              // Add closing quote
              if (i < line.length && line[i] == quote) {
                buffer += line[i++];
              }
            }
            tokenMatched = true;
          } else {
            // Regular token match
            if (buffer.isNotEmpty) {
              spans.add(TextSpan(text: buffer, style: defaultStyle));
              buffer = '';
            }
            spans.add(TextSpan(text: token, style: rule.style));
            i += token.length;
            tokenMatched = true;
          }
          if (tokenMatched) break; // exit loop after handling a rule match
        }
      }
      if (!tokenMatched) {
        // No regex rule matched at this position; treat character as plain text
        buffer += line[i++];
      }
    }
    // Flush any remaining text as default style
    if (buffer.isNotEmpty) {
      spans.add(TextSpan(text: buffer, style: defaultStyle));
    }
    return spans;
  }
}
