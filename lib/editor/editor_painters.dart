part of 'editor.dart';

const _minimumUnderlineWidth = 6.0;
const _underlineBottomInset = 3.0;
const _waveAmplitude = 1.2;
const _waveStrokeWidth = 1.3;
const _waveLength = 6.0;
const _waveSampleStep = 1.0;

class _DiagnosticBackgroundPainter extends CustomPainter {
  const _DiagnosticBackgroundPainter(
      {required this.diagnostics,
      required this.firstLine,
      required this.rowHeight,
      required this.color});

  final List<_PlacedDiagnostic> diagnostics;
  final int firstLine;
  final double rowHeight;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (final line in diagnostics.map((d) => d.visualLine).toSet()) {
      canvas.drawRect(
          Rect.fromLTWH(
              0, (line - firstLine) * rowHeight, size.width, rowHeight),
          paint);
    }
  }

  @override
  bool shouldRepaint(_DiagnosticBackgroundPainter oldDelegate) =>
      firstLine != oldDelegate.firstLine ||
      rowHeight != oldDelegate.rowHeight ||
      color != oldDelegate.color ||
      !listEquals(diagnostics, oldDelegate.diagnostics);

  @override
  bool shouldRebuildSemantics(_DiagnosticBackgroundPainter oldDelegate) =>
      false;
}

class _DiagnosticForegroundPainter extends CustomPainter {
  const _DiagnosticForegroundPainter(
      {required this.diagnostics,
      required this.region,
      required this.rowHeight,
      required this.style,
      required this.strut,
      required this.textScaler,
      required this.color});

  final List<_PlacedDiagnostic> diagnostics;
  final _DocumentRegion region;
  final double rowHeight;
  final TextStyle style;
  final StrutStyle strut;
  final TextScaler textScaler;
  final Color color;

  double _width(String text) => _measureText(text, style, textScaler, strut);

  @override
  void paint(Canvas canvas, Size size) {
    final annotated = <int>{};
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _waveStrokeWidth;
    for (final diagnostic in diagnostics) {
      final line = diagnostic.visualLine - region.firstLine;
      final top = line * rowHeight;
      final text = region.lines[line];
      final from = (diagnostic.source.column - 1).clamp(0, text.length);
      final to = (from + diagnostic.source.length).clamp(from, text.length);
      final start = _contentPadding + _width(text.substring(0, from));
      final end = math.max(start + _minimumUnderlineWidth,
          _contentPadding + _width(text.substring(0, to)));
      final baseline = top + rowHeight - _underlineBottomInset;
      final path = Path()..moveTo(start, baseline);
      for (var x = start + _waveSampleStep; x <= end; x += _waveSampleStep) {
        path.lineTo(
            x,
            baseline +
                math.sin((x - start) * 2 * math.pi / _waveLength) *
                    _waveAmplitude);
      }
      canvas.drawPath(path, paint);
      if (diagnostic.message.isNotEmpty && annotated.add(line)) {
        final message = _layoutText(diagnostic.message,
            _messageStyle(style).copyWith(color: color), textScaler, strut);
        message.paint(
            canvas,
            Offset(_contentPadding + _width(text) + _messageGap,
                top + (rowHeight - message.height) / 2));
        message.dispose();
      }
    }
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder => (size) => [
        for (final diagnostic in diagnostics)
          CustomPainterSemantics(
              rect: Rect.fromLTWH(
                  0,
                  (diagnostic.visualLine - region.firstLine) * rowHeight,
                  size.width,
                  rowHeight),
              properties: SemanticsProperties(
                  label: 'Line ${diagnostic.source.line}: '
                      '${diagnostic.source.message.isEmpty ? 'Error' : diagnostic.source.message}',
                  textDirection: TextDirection.ltr)),
      ];

  @override
  bool shouldRepaint(_DiagnosticForegroundPainter oldDelegate) =>
      shouldRebuildSemantics(oldDelegate) ||
      color != oldDelegate.color ||
      style != oldDelegate.style ||
      strut != oldDelegate.strut ||
      textScaler != oldDelegate.textScaler ||
      !listEquals(region.lines, oldDelegate.region.lines);

  @override
  bool shouldRebuildSemantics(_DiagnosticForegroundPainter oldDelegate) =>
      region.firstLine != oldDelegate.region.firstLine ||
      rowHeight != oldDelegate.rowHeight ||
      !listEquals(diagnostics, oldDelegate.diagnostics);
}
