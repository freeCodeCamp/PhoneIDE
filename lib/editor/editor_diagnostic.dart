import 'package:flutter/foundation.dart';

/// A source error supplied by the host, rather than inferred from test text.
///
/// [line] and [column] are one-based positions in the whole file; [length]
/// counts UTF-16 code units, as do Flutter text selections. Invalid/out-of-file
/// positions are ignored. A zero length marks an insertion point.
@immutable
class EditorDiagnostic {
  const EditorDiagnostic({
    required this.line,
    this.column = 1,
    this.length = 1,
    this.message = '',
  })  : assert(line > 0),
        assert(column > 0),
        assert(length >= 0);

  final int line;
  final int column;
  final int length;
  final String message;
}
