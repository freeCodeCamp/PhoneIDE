import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_ide/highlighting/textmate_highlighter_registry.dart';
import 'package:phone_ide/models/textfield_data.dart';
import 'package:phone_ide/phone_ide.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _editorKey = ValueKey('layout-editor');
const _captureKey = ValueKey('layout-capture');
const _hostFill = Color(0xFFFF00FF);
const _hostBorder = Color(0xFF00FF00);
const _lightCode = Color(0xFFFFFFFF);
const _darkCode = Color(0xFF251E42);
const _activeFill = Color(0x33FFCC00);
const _activeBorder = Color(0xFF7654CC);
const _diagnosticFill = Color(0xFFFACCCC);
const _diagnosticInk = Color(0xFFCC2244);

Finder get _fields => find.byType(TextField);
Finder _fieldFor(TextEditingController controller) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.controller == controller,
    );

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

EditorOptions _options({
  bool dark = false,
  EditorRegionOptions? region,
  bool editable = true,
}) =>
    EditorOptions(
      backgroundColor: dark ? _darkCode : _lightCode,
      linebarColor: dark ? const Color(0xFF2F2752) : const Color(0xFFFFF1D6),
      linebarTextColor:
          dark ? const Color(0xFFCFC6E6) : const Color(0xFF5E5470),
      textColor: dark ? const Color(0xFFFFF8EC) : const Color(0xFF2B2140),
      cursorColor: const Color(0xFF5B4BDB),
      selectionColor: const Color(0x665B4BDB),
      selectionHandleColor: const Color(0xFF5B4BDB),
      linebarBorderColor: const Color(0xFF3D3466),
      activeLineColor: _activeFill,
      activeLineBorderColor: _activeBorder,
      diagnosticColor: _diagnosticInk,
      diagnosticBackgroundColor: _diagnosticFill,
      fontFamily: 'RobotoMono',
      fontSize: 14,
      lineHeight: 1.5,
      linebarWidth: 28,
      isEditable: editable,
      regionOptions: region,
    );

class _Host extends StatefulWidget {
  const _Host({
    super.key,
    required this.code,
    this.dark = false,
    this.scale = 1,
    this.region,
    this.editable = true,
    this.diagnostics = const [],
  });

  final String code;
  final bool dark;
  final double scale;
  final EditorRegionOptions? region;
  final bool editable;
  final List<EditorDiagnostic> diagnostics;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late bool dark = widget.dark;
  late List<EditorDiagnostic> diagnostics = widget.diagnostics;

  void switchTheme() => setState(() => dark = !dark);
  void setDiagnostics(List<EditorDiagnostic> value) =>
      setState(() => diagnostics = value);

  @override
  Widget build(BuildContext context) {
    const border = OutlineInputBorder(
      borderSide: BorderSide(color: _hostBorder, width: 6),
      borderRadius: BorderRadius.all(Radius.circular(30)),
    );
    return MaterialApp(
      theme: ThemeData(
        brightness: dark ? Brightness.dark : Brightness.light,
        platform: TargetPlatform.linux,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
              letterSpacing: 3, wordSpacing: 5, fontWeight: FontWeight.w900),
          bodyMedium: TextStyle(
              letterSpacing: 3, wordSpacing: 5, fontWeight: FontWeight.w900),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: _hostFill,
          border: border,
          enabledBorder: border,
          focusedBorder: border,
          disabledBorder: border,
          errorBorder: border,
          focusedErrorBorder: border,
          contentPadding: EdgeInsets.all(32),
        ),
      ),
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(320, 240),
          textScaler: TextScaler.linear(widget.scale),
        ),
        child: Scaffold(
          body: SizedBox(
            width: 320,
            height: 240,
            child: RepaintBoundary(
              key: _captureKey,
              child: Editor(
                key: _editorKey,
                options: _options(
                  dark: dark,
                  region: widget.region,
                  editable: widget.editable,
                ),
                defaultLanguage: 'html',
                defaultValue: widget.code,
                path: 'layout.html',
                diagnostics: diagnostics,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<EditorState> _pump(
  WidgetTester tester, {
  String code = '<h1>Hello</h1>\n<p>World</p>',
  bool dark = false,
  double scale = 1,
  EditorRegionOptions? region,
  bool editable = true,
  List<EditorDiagnostic> diagnostics = const [],
  GlobalKey<_HostState>? hostKey,
}) async {
  await tester.pumpWidget(
    _Host(
      key: hostKey,
      code: code,
      dark: dark,
      scale: scale,
      region: region,
      editable: editable,
      diagnostics: diagnostics,
    ),
  );
  await _settle(tester);
  expect(find.byType(CircularProgressIndicator), findsNothing);
  return tester.state<EditorState>(find.byType(Editor));
}

Rect _codeGlyph(WidgetTester tester, Finder field, int offset) {
  final editable = tester
      .state<EditableTextState>(
        find.descendant(of: field, matching: find.byType(EditableText)),
      )
      .renderEditable;
  final box = editable
      .getBoxesForSelection(
        TextSelection(baseOffset: offset, extentOffset: offset + 1),
      )
      .single;
  return box.toRect().shift(editable.localToGlobal(Offset.zero));
}

Rect _gutterGlyph(WidgetTester tester, int line) {
  final paragraph = tester.renderObject<RenderParagraph>(
    find.descendant(of: find.text('$line'), matching: find.byType(RichText)),
  );
  final box = paragraph
      .getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: '$line'.length),
        boxHeightStyle: ui.BoxHeightStyle.strut,
      )
      .single;
  return box.toRect().shift(paragraph.localToGlobal(Offset.zero));
}

void _expectAligned(Rect code, Rect gutter) {
  expect(code.top, closeTo(gutter.top, 1));
  expect(code.bottom, closeTo(gutter.bottom, 1));
}

Future<List<Color>> _pixels(WidgetTester tester, List<Offset> points) async {
  return (await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_captureKey),
    );
    final image = await boundary.toImage();
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final colors = [
      for (final point in points)
        Color.fromARGB(
          bytes.getUint8(
              (point.dy.floor() * image.width + point.dx.floor()) * 4 + 3),
          bytes.getUint8(
              (point.dy.floor() * image.width + point.dx.floor()) * 4),
          bytes.getUint8(
              (point.dy.floor() * image.width + point.dx.floor()) * 4 + 1),
          bytes.getUint8(
              (point.dy.floor() * image.width + point.dx.floor()) * 4 + 2),
        ),
    ];
    image.dispose();
    return colors;
  }))!;
}

Future<void> _shot(WidgetTester tester, String name) async {
  const directory = String.fromEnvironment('UI_SCREENSHOT_DIR');
  if (directory.isEmpty) return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_captureKey),
    );
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    final file = File('$directory/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await (FontLoader('RobotoMono')
          ..addFont(rootBundle.load('assets/fonts/RobotoMono-Regular.ttf')))
        .load();
    await TextMateHighlighterRegistry.instance.initialize();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  for (final dark in [false, true]) {
    for (final editable in [false, true]) {
      testWidgets(
          'host field decoration does not leak dark=$dark editable=$editable',
          (tester) async {
        final state = await _pump(tester, dark: dark, editable: editable);
        expect(_fields, findsOneWidget);
        expect(find.text('1'), findsOneWidget);
        final field = tester.widget<TextField>(_fields);
        final decoration = tester
            .widget<InputDecorator>(
              find.descendant(
                  of: _fields, matching: find.byType(InputDecorator)),
            )
            .decoration;
        for (final border in [
          decoration.border,
          decoration.enabledBorder,
          decoration.focusedBorder,
          decoration.disabledBorder,
          decoration.errorBorder,
          decoration.focusedErrorBorder,
        ]) {
          expect(border, InputBorder.none);
        }
        if (decoration.filled == true) {
          expect(decoration.fillColor, dark ? _darkCode : _lightCode);
        }
        expect(field.style!.color, state.widget.options.textColor);
        expect(field.cursorColor, state.widget.options.cursorColor);
        field.focusNode!.requestFocus();
        await _settle(tester);
        final text = tester.widget<EditableText>(find.byType(EditableText));
        expect(text.selectionColor, state.widget.options.selectionColor);
        expect(text.style.letterSpacing, 0);
        expect(text.style.wordSpacing, 0);
        expect(text.style.fontWeight, FontWeight.w400);
        await _shot(tester, 'phoneide-dark$dark-editable$editable');
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('gutter and code rows align at text scale $scale',
        (tester) async {
      final code = List.generate(20, (i) => 'row ${i + 1}').join('\n');
      final state = await _pump(tester, code: code, scale: scale);
      final field = _fieldFor(state.inController);
      final gutterWidth = tester.getTopLeft(field).dx -
          tester.getTopLeft(find.byType(Editor)).dx;
      if (scale == 1) expect(gutterWidth, 28);
      _expectAligned(_codeGlyph(tester, field, 0), _gutterGlyph(tester, 1));
      _expectAligned(_codeGlyph(tester, field, 6), _gutterGlyph(tester, 2));
      state.scrollController
          .jumpTo(state.scrollController.position.maxScrollExtent);
      await tester.pump();
      expect(state.linebarController.offset, state.scrollController.offset);
      final number = _gutterGlyph(tester, 20);
      expect(number.left, greaterThanOrEqualTo(0));
      expect(number.right, lessThanOrEqualTo(gutterWidth));
      await _shot(tester, 'phoneide-gutter-scale$scale');
      expect(tester.takeException(), isNull);
    });

    testWidgets('three-digit gutter expands without clipping at scale $scale',
        (tester) async {
      final code = List.generate(120, (i) => 'row ${i + 1}').join('\n');
      final state = await _pump(tester, code: code, scale: scale);
      state.scrollController
          .jumpTo(state.scrollController.position.maxScrollExtent);
      await tester.pump();
      final field = _fieldFor(state.inController);
      final gutterWidth = tester.getTopLeft(field).dx -
          tester.getTopLeft(find.byType(Editor)).dx;
      expect(gutterWidth, greaterThan(28));
      final number = _gutterGlyph(tester, 120);
      expect(number.left, greaterThanOrEqualTo(0));
      expect(number.right, lessThanOrEqualTo(gutterWidth));
      _expectAligned(
        _codeGlyph(tester, field, code.lastIndexOf('row 120')),
        number,
      );
      await _shot(tester, 'phoneide-three-digit-gutter-scale$scale');
      expect(tester.takeException(), isNull);
    });

    testWidgets('editable regions retain the gutter row rhythm at scale $scale',
        (tester) async {
      const code = 'before 1\nbefore 2\ninside 1\ninside 2\nafter 1\nafter 2';
      final state = await _pump(
        tester,
        code: code,
        scale: scale,
        region: EditorRegionOptions(start: 2, end: 5),
      );
      expect(_fields, findsNWidgets(3));
      _expectAligned(
        _codeGlyph(tester, _fieldFor(state.beforeController), 0),
        _gutterGlyph(tester, 1),
      );
      _expectAligned(
        _codeGlyph(tester, _fieldFor(state.inController), 0),
        _gutterGlyph(tester, 3),
      );
      state.scrollController
          .jumpTo(state.scrollController.position.maxScrollExtent);
      await tester.pump();
      _expectAligned(
        _codeGlyph(tester, _fieldFor(state.afterController), 0),
        _gutterGlyph(tester, 5),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('horizontal scrolling moves code while gutter stays fixed',
      (tester) async {
    final state = await _pump(tester, code: 'A${' long line' * 100}\nB');
    final field = _fieldFor(state.inController);
    final codeBefore = _codeGlyph(tester, field, 0);
    final gutterBefore = _gutterGlyph(tester, 1);
    state.horizontalController.jumpTo(250);
    await tester.pump();
    expect(
        _codeGlyph(tester, field, 0).left, closeTo(codeBefore.left - 250, 1));
    expect(_gutterGlyph(tester, 1), gutterBefore);
    expect(tester.takeException(), isNull);
  });

  testWidgets('typing and undo emit the current source', (tester) async {
    final state = await _pump(tester, code: 'original');
    final changes = <String>[];
    final edits = state.widget.onTextChange.stream.listen(changes.add);
    addTearDown(edits.cancel);
    await tester.showKeyboard(_fieldFor(state.inController));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.enterText(_fieldFor(state.inController), 'edited');
    await _settle(tester);
    expect(changes.last, 'edited');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await _settle(tester);
    expect(state.inController.text, 'original');
    expect(changes.last, 'original');
    expect(tester.takeException(), isNull);
  });

  testWidgets('active row follows selection and retains the last caret on blur',
      (tester) async {
    final state = await _pump(tester, code: 'first\nsecond');
    final field = _fieldFor(state.inController);
    final first = _codeGlyph(tester, field, 0);
    final second = _codeGlyph(tester, field, 6);
    final x = tester.getTopLeft(field).dx + 1;
    final points = [Offset(x, first.center.dy), Offset(x, second.center.dy)];
    await tester.showKeyboard(field);
    state.inController.selection = const TextSelection.collapsed(offset: 0);
    await tester.pump();
    expect(await _pixels(tester, points), [_activeBorder, _lightCode]);
    state.inController.selection = const TextSelection.collapsed(offset: 6);
    await tester.pump();
    expect(await _pixels(tester, points), [_lightCode, _activeBorder]);
    await _shot(tester, 'phoneide-active-row');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(await _pixels(tester, points), [_lightCode, _activeBorder]);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets(
        'diagnostics mark the source row and clear without changing code dark=$dark',
        (tester) async {
      final hostKey = GlobalKey<_HostState>();
      final background = dark ? _darkCode : _lightCode;
      final state = await _pump(
        tester,
        hostKey: hostKey,
        dark: dark,
        code: 'alpha\nbeta',
        diagnostics: const [
          EditorDiagnostic(line: 2, column: 2, length: 2, message: 'Fix this'),
          EditorDiagnostic(line: 20, message: 'Outside this file'),
          EditorDiagnostic(line: 1, column: 20, message: 'Outside this line'),
        ],
      );
      expect(_fields, findsOneWidget);
      expect(tester.widget<Text>(find.text('2')).style!.color, _diagnosticInk);
      expect(tester.widget<Text>(find.text('2')).style!.fontWeight,
          FontWeight.w700);
      expect(tester.widget<Text>(find.text('1')).style!.color,
          state.widget.options.linebarTextColor);
      expect(
          await _pixels(tester, [const Offset(250, 10), const Offset(250, 31)]),
          [background, _diagnosticFill]);
      final underline = [
        for (var x = 47.0; x < 65; x++)
          for (var y = 37.0; y < 42; y++) Offset(x, y),
      ];
      final message = [
        for (var x = 90.0; x < 150; x += 2)
          for (var y = 24.0; y < 39; y += 2) Offset(x, y),
      ];
      bool hasDiagnosticInk(List<Color> colors) =>
          colors.any((color) => color.r - color.g > .35);
      expect(hasDiagnosticInk(await _pixels(tester, underline)), isTrue);
      expect(hasDiagnosticInk(await _pixels(tester, message)), isTrue);
      await _shot(tester, 'phoneide-diagnostics-dark$dark');
      hostKey.currentState!.setDiagnostics(const []);
      await tester.pump();
      expect(state.inController.text, 'alpha\nbeta');
      expect(await _pixels(tester, [const Offset(250, 31)]), [background]);
      expect(hasDiagnosticInk(await _pixels(tester, underline)), isFalse);
      expect(hasDiagnosticInk(await _pixels(tester, message)), isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('theme updates keep code and reconnect current widget streams',
      (tester) async {
    final hostKey = GlobalKey<_HostState>();
    final state = await _pump(tester, hostKey: hostKey, code: 'original');
    await tester.enterText(_fieldFor(state.inController), 'unsaved edit');
    await _settle(tester);
    hostKey.currentState!.switchTheme();
    await _settle(tester);
    expect(tester.state<EditorState>(find.byType(Editor)), same(state));
    expect(state.inController.text, 'unsaved edit');
    expect(tester.widget<TextField>(_fields).style!.color,
        const Color(0xFFFFF8EC));
    final changes = <String>[];
    final regions = <String>[];
    final focus = <TextFieldData>[];
    final subscriptions = <StreamSubscription<Object?>>[
      state.widget.onTextChange.stream.listen(changes.add),
      state.widget.editableRegion.stream.listen(regions.add),
      state.widget.textfieldData.stream.listen(focus.add),
    ];
    addTearDown(() async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    });
    await tester.tapAt(tester.getTopLeft(_fields) + const Offset(15, 10));
    await tester.enterText(_fields, 'updated after theme');
    await _settle(tester);
    expect(changes.last, 'updated after theme');
    expect(regions.last, 'updated after theme');
    expect(focus.last.controller, same(state.inController));
    final data = focus.last;
    data.controller.text = '${data.controller.text})';
    state.widget.textfieldData.add(data);
    await _settle(tester);
    expect(changes.last, 'updated after theme)');
    expect(regions.last, 'updated after theme)');
    expect(tester.takeException(), isNull);
  });

  testWidgets('focus is inert but toolbar text updates emit the source',
      (tester) async {
    final state = await _pump(tester, code: 'original');
    final changes = <String>[];
    final regions = <String>[];
    final focus = <TextFieldData>[];
    final subscriptions = <StreamSubscription<Object?>>[
      state.widget.onTextChange.stream.listen(changes.add),
      state.widget.editableRegion.stream.listen(regions.add),
      state.widget.textfieldData.stream.listen(focus.add),
    ];
    addTearDown(() async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    });
    await tester.tapAt(tester.getTopLeft(_fields) + const Offset(15, 10));
    await _settle(tester);
    expect(focus, isNotEmpty);
    expect(changes, isEmpty);
    expect(regions, isEmpty);
    final data = focus.last;
    data.controller.text = '${data.controller.text})';
    state.widget.textfieldData.add(data);
    await _settle(tester);
    expect(changes, ['original)']);
    expect(regions, ['original)']);
    expect(tester.takeException(), isNull);
  });

  for (final code in ['\ninside\nafter', 'before\ninside\n']) {
    testWidgets(
        'blank region boundary rows are preserved for ${code.codeUnits}',
        (tester) async {
      final state = await _pump(
        tester,
        code: code,
        region: EditorRegionOptions(start: 1, end: 3),
      );
      expect(find.text('3'), findsOneWidget);
      _expectAligned(
        _codeGlyph(tester, _fieldFor(state.inController), 0),
        _gutterGlyph(tester, 2),
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final atEnd in [false, true]) {
    testWidgets('an empty editable region accepts insertion atEnd=$atEnd',
        (tester) async {
      final state = await _pump(
        tester,
        code: 'before\nafter',
        region: EditorRegionOptions(start: atEnd ? 2 : 1, end: atEnd ? 3 : 2),
      );
      expect(state.beforeController.text, atEnd ? 'before\nafter' : 'before');
      expect(state.inController.text, isEmpty);
      expect(state.afterController.text, atEnd ? '' : 'after');
      expect(find.text('3'), findsNothing);
      final changes = <String>[];
      final subscription = state.widget.onTextChange.stream.listen(changes.add);
      addTearDown(subscription.cancel);
      await tester.enterText(_fieldFor(state.inController), 'inserted');
      await _settle(tester);
      expect(changes.last,
          atEnd ? 'before\nafter\ninserted' : 'before\ninserted\nafter');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('untouched empty regions stay absent from source and cache',
      (tester) async {
    final state = await _pump(
      tester,
      code: 'before\nafter',
      region: EditorRegionOptions(start: 1, end: 2),
    );
    final changes = <String>[];
    final subscription = state.widget.onTextChange.stream.listen(changes.add);
    addTearDown(subscription.cancel);
    await tester.enterText(_fieldFor(state.beforeController), 'before\nmore');
    await _settle(tester);
    expect(changes.last, 'before\nmore\nafter');
    expect(state.inController.text, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('layout.html'), '2:3');
    await tester.enterText(_fieldFor(state.inController), 'inserted');
    await _settle(tester);
    expect(changes.last, 'before\nmore\ninserted\nafter');
    expect(prefs.getString('layout.html'), '2:4');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'diagnostics after an empty insertion row retain source positions',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final region = EditorRegionOptions(start: 1, end: 2);
      final state = await _pump(
        tester,
        code: 'before\nafter',
        region: region,
        diagnostics: const [
          EditorDiagnostic(line: 2, length: 5, message: 'Expected a value'),
        ],
      );
      expect(find.text('3'), findsNothing);
      _expectAligned(
        _codeGlyph(tester, _fieldFor(state.afterController), 0),
        _gutterGlyph(tester, 2),
      );
      expect(
        await _pixels(tester, [const Offset(250, 31), const Offset(250, 52)]),
        [region.color, _diagnosticFill],
      );
      expect(find.semantics.byLabel('Line 2: Expected a value'), findsOne);
      await _shot(tester, 'phoneide-empty-region-diagnostic');
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('removing a focused editor releases its owned resources',
      (tester) async {
    final state = await _pump(tester);
    final editor = state.widget;
    await tester.showKeyboard(_fields);
    await tester.pumpWidget(const SizedBox.shrink());
    await _settle(tester);
    expect(() => state.inController.addListener(() {}), throwsFlutterError);
    expect(() => state.scrollController.addListener(() {}), throwsFlutterError);
    await editor.onTextChange.close();
    await editor.editableRegion.close();
    await editor.textfieldData.close();
    expect(tester.takeException(), isNull);
  });

  testWidgets('removing an editor before initialization completes is safe',
      (tester) async {
    await tester.pumpWidget(const _Host(code: 'loading'));
    await tester.pumpWidget(const SizedBox.shrink());
    await _settle(tester);
    expect(tester.takeException(), isNull);
  });
}
