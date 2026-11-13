part of 'editor.dart';

const _contentPadding = 10.0;
const _caretClearance = 4.0;
const _gutterPadding = 8.0;
const _minimumGutterNumber = 99;
const _leadingBorderWidth = 3.0;
const _messageGap = 16.0;
const _messageFontScale = .85;
const _editorTouchSlop = 8.0;

TextPainter _layoutText(
        String text, TextStyle style, TextScaler scaler, StrutStyle strut) =>
    TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      strutStyle: strut,
    )..layout();

double _measureText(
    String text, TextStyle style, TextScaler scaler, StrutStyle strut) {
  final painter = _layoutText(text, style, scaler, strut);
  final width = painter.width;
  painter.dispose();
  return width;
}

TextStyle _messageStyle(TextStyle style) =>
    style.copyWith(fontSize: style.fontSize! * _messageFontScale);

double _measureContentWidth(_EditorDocument document,
    List<_PlacedDiagnostic> diagnostics, TextStyle style, TextScaler scaler) {
  final strut = StrutStyle.fromTextStyle(style, forceStrutHeight: true);
  final messageStyle = _messageStyle(style);
  final messages = <int, _PlacedDiagnostic>{};
  for (final diagnostic in diagnostics) {
    if (diagnostic.message.isNotEmpty) {
      messages.putIfAbsent(diagnostic.visualLine, () => diagnostic);
    }
  }
  var width = 0.0;
  for (final region in document.regions) {
    for (var index = 0; index < region.lineCount; index++) {
      final lineWidth = _measureText(region.lines[index], style, scaler, strut);
      var extent =
          lineWidth.ceilToDouble() + _contentPadding * 2 + _caretClearance;
      final diagnostic = messages[region.firstLine + index];
      if (diagnostic != null) {
        extent = math.max(
            extent,
            _contentPadding +
                lineWidth +
                _messageGap +
                _measureText(diagnostic.message, messageStyle, scaler, strut) +
                _contentPadding);
      }
      width = math.max(width, extent);
    }
  }
  return width;
}

class _ContentWidthCache {
  _EditorDocument? _document;
  List<_PlacedDiagnostic> _diagnostics = const [];
  TextStyle? _style;
  TextScaler? _scaler;
  double _width = 0;

  double measure(_EditorDocument document, List<_PlacedDiagnostic> diagnostics,
      TextStyle style, TextScaler scaler) {
    if (!identical(document, _document) ||
        _style != style ||
        _scaler != scaler ||
        !listEquals(diagnostics, _diagnostics)) {
      _width = _measureContentWidth(document, diagnostics, style, scaler);
      _document = document;
      _diagnostics = diagnostics;
      _style = style;
      _scaler = scaler;
    }
    return _width;
  }
}

class _Gutter extends StatelessWidget {
  const _Gutter(
      {required this.document,
      required this.diagnostics,
      required this.controller,
      required this.width,
      required this.rowHeight,
      required this.style,
      required this.options});

  final _EditorDocument document;
  final List<_PlacedDiagnostic> diagnostics;
  final ScrollController controller;
  final double width;
  final double rowHeight;
  final TextStyle style;
  final EditorOptions options;

  @override
  Widget build(BuildContext context) {
    final errorLines = diagnostics.map((d) => d.visualLine).toSet();
    return ExcludeSemantics(
      child: Container(
        key: const ValueKey('phone-ide-gutter'),
        width: width,
        decoration: BoxDecoration(
            color: options.linebarColor,
            border:
                Border(right: BorderSide(color: options.linebarBorderColor))),
        child: ListView.builder(
          padding: EdgeInsets.zero,
          controller: controller,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: document.lineCount,
          itemExtent: rowHeight,
          itemBuilder: (_, index) {
            final error = errorLines.contains(index + 1);
            return Align(
              key: ValueKey('phone-ide-line-${index + 1}'),
              alignment: Alignment.center,
              child: Text('${document.toFileLine(index + 1) ?? ''}',
                  textDirection: TextDirection.ltr,
                  strutStyle:
                      StrutStyle.fromTextStyle(style, forceStrutHeight: true),
                  style: style.copyWith(
                      color: error
                          ? options.diagnosticColor
                          : options.linebarTextColor,
                      fontWeight: error ? FontWeight.w700 : FontWeight.w400)),
            );
          },
        ),
      ),
    );
  }
}

class _ActiveLine extends StatelessWidget {
  const _ActiveLine(
      {required this.line,
      required this.region,
      required this.rowHeight,
      required this.diagnostics,
      required this.color,
      required this.borderColor});

  final ValueListenable<int?> line;
  final _DocumentRegion region;
  final double rowHeight;
  final List<_PlacedDiagnostic> diagnostics;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int?>(
        valueListenable: line,
        builder: (_, active, __) {
          if (active == null ||
              active < region.firstLine ||
              active >= region.firstLine + region.lineCount ||
              (color == null && borderColor == null)) {
            return const SizedBox.shrink();
          }
          return Positioned(
            top: (active - region.firstLine) * rowHeight,
            left: 0,
            right: 0,
            height: rowHeight,
            child: IgnorePointer(
                child: Container(
              key: const ValueKey('phone-ide-active-line'),
              decoration: BoxDecoration(
                  color: diagnostics.any((d) => d.visualLine == active)
                      ? null
                      : color,
                  border: Border(
                      left: BorderSide(
                          color: borderColor ?? Colors.transparent,
                          width: _leadingBorderWidth))),
            )),
          );
        },
      );
}

class _CodeField extends StatelessWidget {
  const _CodeField(
      {required this.region,
      required this.controller,
      required this.focusNode,
      required this.options,
      required this.style,
      required this.rowHeight,
      required this.activeLine,
      required this.diagnostics,
      required this.onChanged,
      required this.onTap});

  final _DocumentRegion region;
  final TextEditingControllerIDE controller;
  final FocusNode focusNode;
  final EditorOptions options;
  final TextStyle style;
  final double rowHeight;
  final ValueListenable<int?> activeLine;
  final List<_PlacedDiagnostic> diagnostics;
  final ValueChanged<String> onChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final regionOptions =
        region.position == RegionPosition.inner ? options.regionOptions : null;
    final strut = StrutStyle.fromTextStyle(style, forceStrutHeight: true);
    final border = regionOptions?.borderColor;
    return DecoratedBox(
      key: ValueKey('phone-ide-region-${region.position.name}'),
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
          border: border == null
              ? null
              : Border(
                  left: BorderSide(color: border, width: _leadingBorderWidth))),
      child: ColoredBox(
        color: regionOptions?.color ?? options.backgroundColor,
        child: CustomPaint(
          key: ValueKey('phone-ide-highlights-${region.position.name}'),
          painter: _DiagnosticBackgroundPainter(
              diagnostics: diagnostics,
              firstLine: region.firstLine,
              rowHeight: rowHeight,
              color: options.diagnosticBackgroundColor),
          foregroundPainter: _DiagnosticForegroundPainter(
              diagnostics: diagnostics,
              region: region,
              rowHeight: rowHeight,
              style: style,
              strut: strut,
              textScaler: MediaQuery.textScalerOf(context),
              color: options.diagnosticColor),
          child: Stack(children: [
            _ActiveLine(
                line: activeLine,
                region: region,
                rowHeight: rowHeight,
                diagnostics: diagnostics,
                color: options.activeLineColor,
                borderColor: options.activeLineBorderColor),
            TextField(
              focusNode: focusNode,
              controller: controller,
              readOnly: !options.isEditable,
              smartQuotesType: SmartQuotesType.disabled,
              smartDashesType: SmartDashesType.disabled,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.multiline,
              textDirection: TextDirection.ltr,
              cursorColor: options.cursorColor,
              selectionHeightStyle: BoxHeightStyle.strut,
              strutStyle: strut,
              decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  filled: false,
                  fillColor: Colors.transparent,
                  isCollapsed: true,
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: _contentPadding)),
              maxLines: null,
              minLines: region.lineCount,
              style: style,
              onChanged: onChanged,
              onTap: onTap,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'[“”]'),
                    replacementString: '"'),
                FilteringTextInputFormatter.deny(RegExp(r'[‘’]'),
                    replacementString: "'"),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}
