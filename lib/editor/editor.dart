import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show BoxHeightStyle;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:phone_ide/controller/custom_text_controller.dart';
import 'package:phone_ide/editor/editor_diagnostic.dart';
import 'package:phone_ide/editor/editor_options.dart';
import 'package:phone_ide/highlighting/textmate_highlighter_registry.dart';
import 'package:phone_ide/models/textfield_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Editor extends StatefulWidget {
  Editor({
    super.key,
    required this.options,
    required this.defaultLanguage,
    required this.defaultValue,
    required this.path,
    this.diagnostics = const [],
  });

  final StreamController<String> onTextChange =
      StreamController<String>.broadcast();
  final StreamController<TextFieldData> textfieldData =
      StreamController<TextFieldData>.broadcast();
  final StreamController<String> editableRegion =
      StreamController<String>.broadcast();
  final EditorOptions options;
  final String defaultValue;
  final String defaultLanguage;
  final String path;
  final List<EditorDiagnostic> diagnostics;

  @override
  EditorState createState() => EditorState();
}

class EditorState extends State<Editor> {
  final ScrollController scrollController = ScrollController();
  final ScrollController horizontalController = ScrollController();
  final ScrollController linebarController = ScrollController();
  final TextEditingControllerIDE beforeController = TextEditingControllerIDE();
  final TextEditingControllerIDE inController = TextEditingControllerIDE();
  final TextEditingControllerIDE afterController = TextEditingControllerIDE();
  final _focusNodes = {
    for (final position in RegionPosition.values) position: FocusNode()
  };
  late StreamSubscription<TextFieldData> _textfieldDataSub;
  bool isLoading = true;
  bool _hasBefore = false;
  bool _hasAfter = false;
  bool _emptyInner = false;
  int _initialization = 0;
  RegionPosition _activePosition = RegionPosition.inner;
  String _lastText = '';

  TextEditingControllerIDE _controller(RegionPosition position) =>
      switch (position) {
        RegionPosition.before => beforeController,
        RegionPosition.inner => inController,
        RegionPosition.after => afterController,
      };

  List<RegionPosition> get _positions => [
        if (_hasBefore) RegionPosition.before,
        RegionPosition.inner,
        if (_hasAfter) RegionPosition.after,
      ];

  Iterable<RegionPosition> get _sourcePositions => _positions.where(
        (position) => position != RegionPosition.inner || !_emptyInner,
      );
  String get _sourceText =>
      _sourcePositions.map((p) => _controller(p).text).join('\n');
  int? _fileLine(int visualLine) {
    if (!_emptyInner) return visualLine;
    final insertion = _firstLine(RegionPosition.inner);
    if (visualLine == insertion) return null;
    return visualLine > insertion ? visualLine - 1 : visualLine;
  }

  int _lineCount(RegionPosition position) =>
      _controller(position).text.split('\n').length;
  int get _numLines =>
      _positions.fold(0, (count, position) => count + _lineCount(position));
  int _firstLine(RegionPosition position) {
    var line = 1;
    for (final part in _positions) {
      if (part == position) break;
      line += _lineCount(part);
    }
    return line;
  }

  @override
  void initState() {
    super.initState();
    _bindStream();
    for (final position in RegionPosition.values) {
      _controller(position).addListener(_selectionChanged);
      _focusNodes[position]!.addListener(() {
        if (_focusNodes[position]!.hasFocus) {
          setState(() => _activePosition = position);
          handleCurrentFocusedTextfieldController(position);
        }
      });
    }
    scrollController.addListener(_syncGutter);
    _initializeEditor();
  }

  void _bindStream() {
    _textfieldDataSub = widget.textfieldData.stream.listen((event) {
      if (!mounted || _controller(event.position) != event.controller) return;
      handleTextChange(event.controller.text, event.position,
          widget.options.regionOptions != null);
    });
  }

  @override
  void didUpdateWidget(Editor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.textfieldData != oldWidget.textfieldData) {
      unawaited(_textfieldDataSub.cancel());
      _bindStream();
    }
    if (widget.path != oldWidget.path ||
        widget.defaultValue != oldWidget.defaultValue ||
        widget.options.regionOptions?.start !=
            oldWidget.options.regionOptions?.start ||
        widget.options.regionOptions?.end !=
            oldWidget.options.regionOptions?.end) {
      isLoading = true;
      _initializeEditor();
    }
    _applySyntaxTheme();
  }

  void _applySyntaxTheme() {
    for (final position in RegionPosition.values) {
      _controller(position)
        ..language = widget.defaultLanguage
        ..syntaxTheme = widget.options.syntaxTheme;
    }
  }

  void _selectionChanged() {
    if (mounted) setState(() {});
  }

  void _syncGutter() {
    if (scrollController.hasClients && linebarController.hasClients) {
      linebarController.jumpTo(scrollController.offset
          .clamp(0.0, linebarController.position.maxScrollExtent));
    }
  }

  @override
  void dispose() {
    unawaited(_textfieldDataSub.cancel());
    for (final position in RegionPosition.values) {
      _controller(position).removeListener(_selectionChanged);
      _controller(position).dispose();
      _focusNodes[position]!.dispose();
    }
    scrollController.dispose();
    horizontalController.dispose();
    linebarController.dispose();
    super.dispose();
  }

  Future<SharedPreferences?> _getPreferencesSafe() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (error) {
      debugPrint('phone_ide: SharedPreferences unavailable: $error');
      return null;
    }
  }

  Future<void> _initializeEditor() async {
    final generation = ++_initialization;
    await TextMateHighlighterRegistry.instance.initialize();
    final prefs = await _getPreferencesSafe();
    if (!mounted || generation != _initialization) return;
    final lines = widget.defaultValue.split('\n');
    final region = widget.options.regionOptions;
    if (region == null) {
      _hasBefore = _hasAfter = _emptyInner = false;
      beforeController.clear();
      afterController.clear();
      inController.text = widget.defaultValue;
    } else {
      final cached = prefs?.getString(widget.path)?.split(':');
      final start = (cached != null && cached.length == 2
              ? int.tryParse(cached[0])
              : null) ??
          region.start ??
          0;
      final end = (cached != null && cached.length == 2
              ? int.tryParse(cached[1])
              : null) ??
          region.end ??
          lines.length + 1;
      final from = start.clamp(0, lines.length);
      final to = (end - 1).clamp(from, lines.length);
      _emptyInner = to == from;
      _hasBefore = from > 0;
      _hasAfter = to < lines.length;
      beforeController.text = lines.take(from).join('\n');
      inController.text = lines.sublist(from, to).join('\n');
      afterController.text = lines.skip(to).join('\n');
    }
    _lastText = _sourceText;
    _applySyntaxTheme();
    setState(() => isLoading = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _initialization) return;
      if (scrollController.hasClients) {
        final target =
            (_firstLine(RegionPosition.inner) - 1) * getTextHeight(context);
        scrollController.jumpTo(
            target.clamp(0.0, scrollController.position.maxScrollExtent));
      }
      if (horizontalController.hasClients) horizontalController.jumpTo(0);
    });
  }

  Future<void> handleRegionCaching(String event, RegionPosition region) async {
    final path = widget.path;
    final before = _hasBefore ? _lineCount(RegionPosition.before) : 0;
    final end =
        before + (_emptyInner ? 0 : _lineCount(RegionPosition.inner)) + 1;
    final prefs = await _getPreferencesSafe();
    await prefs?.setString(path, '$before:$end');
  }

  void handleTextChange(String event, RegionPosition region, bool hasRegion) {
    if (!mounted) return;
    if (_emptyInner && inController.text.isNotEmpty) _emptyInner = false;
    final text = _sourceText;
    // Focus notifications use the same public stream as toolbar insertions.
    // Only actual edits should be saved or invalidate the host's test results.
    if (text == _lastText) return;
    _lastText = text;
    if (hasRegion && region != RegionPosition.after) {
      unawaited(handleRegionCaching(event, region));
    }
    if (region == RegionPosition.inner) widget.editableRegion.add(event);
    widget.onTextChange.add(text);
    setState(() {});
  }

  void handleCurrentFocusedTextfieldController(RegionPosition position) {
    if (!mounted) return;
    widget.textfieldData.add(
        TextFieldData(controller: _controller(position), position: position));
  }

  double getTextHeight(BuildContext context, {double? fontSize}) =>
      MediaQuery.textScalerOf(context)
          .scale(fontSize ?? widget.options.fontSize) *
      widget.options.lineHeight;
  double getFontSize(BuildContext context, {double? fontSize}) =>
      MediaQuery.textScalerOf(context)
          .scale(fontSize ?? widget.options.fontSize);

  TextStyle get _style => TextStyle(
        fontFamily: widget.options.fontFamily,
        fontSize: widget.options.fontSize,
        height: widget.options.lineHeight,
        color: widget.options.textColor,
        letterSpacing: 0,
        wordSpacing: 0,
        fontWeight: FontWeight.w400,
      );
  StrutStyle get _strut =>
      StrutStyle.fromTextStyle(_style, forceStrutHeight: true);

  double _textWidth(String text, {TextStyle? style}) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style ?? _style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      strutStyle: _strut,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  int? get _activeLine {
    final controller = _controller(_activePosition);
    if (!controller.selection.isValid) return null;
    final offset =
        controller.selection.extentOffset.clamp(0, controller.text.length);
    return _firstLine(_activePosition) +
        '\n'.allMatches(controller.text.substring(0, offset)).length;
  }

  List<EditorDiagnostic> get _diagnostics {
    final lines = _sourceText.split('\n');
    final insertion = _firstLine(RegionPosition.inner);
    return [
      for (final diagnostic in widget.diagnostics)
        if (diagnostic.line > 0 &&
            diagnostic.line <= lines.length &&
            diagnostic.column > 0 &&
            diagnostic.column <= lines[diagnostic.line - 1].length + 1 &&
            diagnostic.length >= 0)
          EditorDiagnostic(
            line: _emptyInner && diagnostic.line >= insertion
                ? diagnostic.line + 1
                : diagnostic.line,
            column: diagnostic.column,
            length: diagnostic.length,
            message: diagnostic.message,
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    final options = widget.options;
    final rowHeight = getTextHeight(context);
    final numberWidth = _textWidth(math.max(99, _numLines).toString());
    final gutterWidth = math.max(options.linebarWidth, numberWidth + 8);
    final diagnostics = _diagnostics;
    final selection = Theme.of(context).textSelectionTheme;
    return TextSelectionTheme(
      data: selection.copyWith(
        cursorColor: options.cursorColor,
        selectionColor: options.selectionColor,
        selectionHandleColor: options.selectionHandleColor,
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final fullHeight = _numLines * rowHeight;
        final height = constraints.hasBoundedHeight
            ? options.takeFullHeight
                ? constraints.maxHeight
                : math.min(fullHeight, constraints.maxHeight)
            : fullHeight;
        final viewportWidth =
            constraints.maxWidth - (options.showLinebar ? gutterWidth : 0);
        var contentWidth = math.max(0.0, viewportWidth);
        var line = 1;
        for (final position in _positions) {
          for (final text in _controller(position).text.split('\n')) {
            var width = _textWidth(text).ceilToDouble() + 24;
            for (final diagnostic in diagnostics
                .where((d) => d.line == line && d.message.isNotEmpty)) {
              width = math.max(
                  width,
                  _textWidth(text) +
                      _textWidth(diagnostic.message,
                          style: _style.copyWith(
                              fontSize: options.fontSize * .85)) +
                      36);
            }
            contentWidth = math.max(contentWidth, width);
            line++;
          }
        }
        return SizedBox(
          height: height,
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (options.showLinebar)
              Container(
                key: const ValueKey('phone-ide-gutter'),
                width: gutterWidth,
                decoration: BoxDecoration(
                    color: options.linebarColor,
                    border: Border(
                        right: BorderSide(color: options.linebarBorderColor))),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  controller: linebarController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _numLines,
                  itemExtent: rowHeight,
                  itemBuilder: (_, index) {
                    final error = diagnostics.any((d) => d.line == index + 1);
                    return Align(
                      key: ValueKey('phone-ide-line-${index + 1}'),
                      alignment: Alignment.center,
                      child: Text(
                        '${_fileLine(index + 1) ?? ''}',
                        textDirection: TextDirection.ltr,
                        strutStyle: _strut,
                        style: _style.copyWith(
                            color: error
                                ? options.diagnosticColor
                                : options.linebarTextColor,
                            fontWeight:
                                error ? FontWeight.w700 : FontWeight.w400),
                      ),
                    );
                  },
                ),
              ),
            Expanded(
                child: ColoredBox(
              color: options.backgroundColor,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    gestureSettings: const DeviceGestureSettings(touchSlop: 8)),
                child: Scrollbar(
                  controller: horizontalController,
                  notificationPredicate: (notification) =>
                      notification.metrics.axis == Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: horizontalController,
                    child: SizedBox(
                        width: contentWidth,
                        child: ListView(
                          padding: EdgeInsets.zero,
                          controller: scrollController,
                          physics: const ClampingScrollPhysics(),
                          children: [
                            for (final position in _positions)
                              _editorField(position, diagnostics, rowHeight)
                          ],
                        )),
                  ),
                ),
              ),
            )),
          ]),
        );
      }),
    );
  }

  Widget _editorField(RegionPosition position,
      List<EditorDiagnostic> diagnostics, double rowHeight) {
    final options = widget.options;
    final firstLine = _firstLine(position);
    final controller = _controller(position);
    final lines = controller.text.split('\n');
    final active = _activeLine;
    final localDiagnostics = diagnostics
        .where((d) => d.line >= firstLine && d.line < firstLine + lines.length)
        .toList();
    final hasActive = active != null &&
        active >= firstLine &&
        active < firstLine + lines.length;
    final region =
        position == RegionPosition.inner ? options.regionOptions : null;
    final borderColor = region?.borderColor;
    final field = ColoredBox(
      color: region?.color ?? options.backgroundColor,
      child: CustomPaint(
        key: ValueKey('phone-ide-highlights-${position.name}'),
        painter: _DiagnosticPainter(
            diagnostics: localDiagnostics,
            lines: lines,
            firstLine: firstLine,
            rowHeight: rowHeight,
            options: options,
            textScaler: MediaQuery.textScalerOf(context),
            foreground: false,
            insertionLine:
                _emptyInner ? _firstLine(RegionPosition.inner) : null),
        foregroundPainter: _DiagnosticPainter(
            diagnostics: localDiagnostics,
            lines: lines,
            firstLine: firstLine,
            rowHeight: rowHeight,
            options: options,
            textScaler: MediaQuery.textScalerOf(context),
            foreground: true,
            insertionLine:
                _emptyInner ? _firstLine(RegionPosition.inner) : null),
        child: Stack(children: [
          if (hasActive &&
              (options.activeLineColor != null ||
                  options.activeLineBorderColor != null))
            Positioned(
              top: (active - firstLine) * rowHeight,
              left: 0,
              right: 0,
              height: rowHeight,
              child: IgnorePointer(
                  child: Container(
                key: const ValueKey('phone-ide-active-line'),
                decoration: BoxDecoration(
                  color: localDiagnostics.any((d) => d.line == active)
                      ? null
                      : options.activeLineColor,
                  border: Border(
                      left: BorderSide(
                          color: options.activeLineBorderColor ??
                              Colors.transparent,
                          width: 3)),
                ),
              )),
            ),
          TextField(
            focusNode: _focusNodes[position],
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
            strutStyle: _strut,
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
              contentPadding: EdgeInsets.only(left: 10, right: 10),
            ),
            maxLines: null,
            minLines: lines.length,
            style: _style,
            onChanged: (text) =>
                handleTextChange(text, position, options.regionOptions != null),
            onTap: () => handleCurrentFocusedTextfieldController(position),
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'[“”]'),
                  replacementString: '"'),
              FilteringTextInputFormatter.deny(RegExp(r'[‘’]'),
                  replacementString: "'"),
            ],
          ),
        ]),
      ),
    );
    return DecoratedBox(
      key: ValueKey('phone-ide-region-${position.name}'),
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: borderColor == null
            ? null
            : Border(left: BorderSide(color: borderColor, width: 3)),
      ),
      child: field,
    );
  }
}

class _DiagnosticPainter extends CustomPainter {
  const _DiagnosticPainter(
      {required this.diagnostics,
      required this.lines,
      required this.firstLine,
      required this.rowHeight,
      required this.options,
      required this.textScaler,
      required this.foreground,
      this.insertionLine});
  final List<EditorDiagnostic> diagnostics;
  final List<String> lines;
  final int firstLine;
  final double rowHeight;
  final EditorOptions options;
  final TextScaler textScaler;
  final bool foreground;
  final int? insertionLine;

  TextPainter _text(String text, {bool message = false}) => TextPainter(
        text: TextSpan(
            text: text,
            style: TextStyle(
                fontFamily: options.fontFamily,
                fontSize: options.fontSize * (message ? .85 : 1),
                height: options.lineHeight,
                color: options.diagnosticColor,
                letterSpacing: 0,
                wordSpacing: 0,
                fontWeight: FontWeight.w400)),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout();

  double _width(String text) {
    final painter = _text(text);
    final width = painter.width;
    painter.dispose();
    return width;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final annotated = <int>{};
    for (final diagnostic in diagnostics) {
      final line = diagnostic.line - firstLine;
      final top = line * rowHeight;
      if (!foreground) {
        canvas.drawRect(Rect.fromLTWH(0, top, size.width, rowHeight),
            Paint()..color = options.diagnosticBackgroundColor);
        continue;
      }
      final text = lines[line];
      final from = (diagnostic.column - 1).clamp(0, text.length);
      final to = (from + diagnostic.length).clamp(from, text.length);
      final start = 10 + _width(text.substring(0, from));
      final end = math.max(start + 6, 10 + _width(text.substring(0, to)));
      final path = Path()..moveTo(start, top + rowHeight - 3);
      for (var x = start + 1; x <= end; x++) {
        path.lineTo(
            x, top + rowHeight - 3 + math.sin((x - start) * math.pi / 3) * 1.2);
      }
      canvas.drawPath(
          path,
          Paint()
            ..color = options.diagnosticColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.3);
      if (diagnostic.message.isNotEmpty && annotated.add(line)) {
        final message =
            _text(diagnostic.message.replaceAll('\n', ' '), message: true);
        message.paint(canvas,
            Offset(_width(text) + 26, top + (rowHeight - message.height) / 2));
        message.dispose();
      }
    }
  }

  @override
  SemanticsBuilderCallback? get semanticsBuilder => !foreground
      ? null
      : (size) => [
            for (final diagnostic in diagnostics)
              CustomPainterSemantics(
                rect: Rect.fromLTWH(
                    0,
                    (diagnostic.line - firstLine) * rowHeight,
                    size.width,
                    rowHeight),
                properties: SemanticsProperties(
                  label:
                      'Line ${insertionLine != null && diagnostic.line > insertionLine! ? diagnostic.line - 1 : diagnostic.line}: ${diagnostic.message.isEmpty ? 'Error' : diagnostic.message}',
                  textDirection: TextDirection.ltr,
                ),
              ),
          ];

  @override
  bool shouldRepaint(_DiagnosticPainter oldDelegate) => true;
}
