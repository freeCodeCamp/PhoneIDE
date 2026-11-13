part of 'editor.dart';

class _DocumentRegion {
  _DocumentRegion(this.position, this.text, this.firstLine)
      : lines = List.unmodifiable(text.split('\n')) {
    var offset = 0;
    final offsets = <int>[];
    for (final line in lines) {
      offsets.add(offset);
      offset += line.length + 1;
    }
    lineOffsets = List.unmodifiable(offsets);
  }

  final RegionPosition position;
  final String text;
  final int firstLine;
  final List<String> lines;
  late final List<int> lineOffsets;
  int get lineCount => lines.length;

  int lineAtOffset(int offset) {
    var low = 0;
    var high = lineOffsets.length;
    while (low + 1 < high) {
      final middle = (low + high) ~/ 2;
      if (lineOffsets[middle] <= offset) {
        low = middle;
      } else {
        high = middle;
      }
    }
    return firstLine + low;
  }
}

class _EditorDocument {
  _EditorDocument(Map<RegionPosition, String> parts,
      {required bool emptyInner}) {
    var firstLine = 1;
    final sections = <_DocumentRegion>[];
    for (final part in parts.entries) {
      final region = _DocumentRegion(part.key, part.value, firstLine);
      sections.add(region);
      firstLine += region.lineCount;
    }
    regions = List.unmodifiable(sections);
    lineCount = firstLine - 1;
    insertionLine = emptyInner ? region(RegionPosition.inner).firstLine : null;
    sourceLines = List.unmodifiable([
      for (final region in regions)
        if (!emptyInner || region.position != RegionPosition.inner)
          ...region.lines,
    ]);
    sourceText = sourceLines.join('\n');
  }

  late final List<_DocumentRegion> regions;
  late final int lineCount;
  late final int? insertionLine;
  late final List<String> sourceLines;
  late final String sourceText;

  _DocumentRegion region(RegionPosition position) =>
      regions.firstWhere((region) => region.position == position);

  int? toFileLine(int visualLine) {
    final insertion = insertionLine;
    if (insertion == null || visualLine < insertion) return visualLine;
    return visualLine == insertion ? null : visualLine - 1;
  }

  int toVisualLine(int fileLine) =>
      insertionLine != null && fileLine >= insertionLine!
          ? fileLine + 1
          : fileLine;

  List<_PlacedDiagnostic> placeDiagnostics(
          List<EditorDiagnostic> diagnostics) =>
      List.unmodifiable([
        for (final diagnostic in diagnostics)
          if (diagnostic.line > 0 &&
              diagnostic.line <= sourceLines.length &&
              diagnostic.column > 0 &&
              diagnostic.column <=
                  sourceLines[diagnostic.line - 1].length + 1 &&
              diagnostic.length >= 0)
            _PlacedDiagnostic(diagnostic, toVisualLine(diagnostic.line)),
      ]);
}

class _PlacedDiagnostic {
  const _PlacedDiagnostic(this.source, this.visualLine);

  final EditorDiagnostic source;
  final int visualLine;
  String get message => source.message.replaceAll('\n', ' ');

  @override
  bool operator ==(Object other) =>
      other is _PlacedDiagnostic &&
      visualLine == other.visualLine &&
      source.line == other.source.line &&
      source.column == other.source.column &&
      source.length == other.source.length &&
      source.message == other.source.message;

  @override
  int get hashCode => Object.hash(
      visualLine, source.line, source.column, source.length, source.message);
}
