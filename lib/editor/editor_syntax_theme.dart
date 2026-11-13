import 'package:flutter/material.dart';

/// Token colors for one editor, independent of other editors and the app theme.
@immutable
class EditorSyntaxTheme {
  const EditorSyntaxTheme({
    required this.foreground,
    required this.comment,
    required this.keyword,
    required this.string,
    required this.number,
    required this.type,
    required this.function,
    required this.tag,
    required this.attribute,
    required this.operator,
    required this.punctuation,
    required this.variable,
  });

  final Color foreground;
  final Color comment;
  final Color keyword;
  final Color string;
  final Color number;
  final Color type;
  final Color function;
  final Color tag;
  final Color attribute;
  final Color operator;
  final Color punctuation;
  final Color variable;

  @override
  bool operator ==(Object other) =>
      other is EditorSyntaxTheme &&
      foreground == other.foreground &&
      comment == other.comment &&
      keyword == other.keyword &&
      string == other.string &&
      number == other.number &&
      type == other.type &&
      function == other.function &&
      tag == other.tag &&
      attribute == other.attribute &&
      operator == other.operator &&
      punctuation == other.punctuation &&
      variable == other.variable;

  @override
  int get hashCode => Object.hash(
        foreground,
        comment,
        keyword,
        string,
        number,
        type,
        function,
        tag,
        attribute,
        operator,
        punctuation,
        variable,
      );
}
