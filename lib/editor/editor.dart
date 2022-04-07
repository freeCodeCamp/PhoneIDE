import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code_editor/controller/custom_text_controller/custom_text_controller.dart';
import 'package:flutter_code_editor/controller/file_controller.dart';
import 'package:flutter_code_editor/controller/language_controller/syntax/index.dart';
import 'package:flutter_code_editor/editor/linebar/linebar_helper.dart';
import 'package:flutter_code_editor/enums/syntax.dart';
import 'package:flutter_code_editor/models/editor.dart';
import 'package:flutter_code_editor/models/editor_options.dart';
import 'package:flutter_code_editor/models/file_model.dart';

// ignore: must_be_immutable
class Editor extends StatefulWidget with IEditor {
  Editor(
      {Key? key,
      required this.onChange,
      this.openedFile,
      this.options = const EditorOptions(),
      required this.textStream,
      required this.language})
      : super(key: key);

  // the coding language in the editor

  final Syntax language;

  // an instance of the current file

  final FileIDE? openedFile;

  // controller of text

  TextEditingControllerIDE? textController;

  // a function that executes when the state of the editor changes

  Function() onChange;

  // holds a copy of the last key events that happened

  RawKeyEvent? lastKeyEvent;

  // options of the editor

  late EditorOptions options;

  // a copy of the provided stream so it can be updated

  StreamController textStream;

  @override
  State<StatefulWidget> createState() => EditorState();
}

class EditorState extends State<Editor> {
  InputDecoration decoration = const InputDecoration(
      contentPadding: EdgeInsets.only(top: 20.0, left: 10, right: 10),
      border: InputBorder.none);

  ScrollController scrollController = ScrollController();
  ScrollController linebarController = ScrollController();

  final FocusNode _focusNode = FocusNode();

  List<String> patternMatches = [];

  @override
  void initState() {
    super.initState();

    scrollController.addListener(() {
      linebarController.jumpTo(scrollController.offset);
    });

    if (widget.openedFile != null) {
      Future.delayed(const Duration(seconds: 0), (() async {
        widget.textController = TextEditingControllerIDE(
            syntax: Syntax.JAVASCRIPT,
            theme: SyntaxTheme.vscodeDark(),
            code: widget.openedFile?.fileContent ?? '');
        setNewLinebarState(widget.textController?.text ?? '');
      }));
    }

    widget.options = const EditorOptions();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void handlePossibleExecutingEvents(String event) async {
    if (widget.openedFile != null && widget.options.useFileExplorer) {
      await FileController.writeFile(
          widget.openedFile!.filePath, widget.textController!.text);
    }

    // bool isTriggerKeyForHtmlDesktop = widget.language == Language.html &&
    //     widget.lastKeyEvent!.isShiftPressed &&
    //     widget.lastKeyEvent!.logicalKey == LogicalKeyboardKey.period;

    // bool isTriggerKeyForHtmlMobile = widget.language == Language.html &&
    //     widget.lastKeyEvent!.logicalKey == LogicalKeyboardKey.greater;

    // if (isTriggerKeyForHtmlDesktop || isTriggerKeyForHtmlMobile) {
    //   widget.replicateTags(patternMatches, widget.textController);
    // }

    setNewLinebarState(event);
  }

  void setNewLinebarState(String event) {
    setState(() {
      TextSpan span = TextSpan(text: event);
      TextPainter tp =
          TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout(
        maxWidth: widget.options.minWidth,
      );

      List lines = tp.computeLineMetrics();

      numLines = lines.length;
    });
    linebarController.jumpTo(linebarController.position.maxScrollExtent);
  }

  void handleKeyEvents(RawKeyEvent event) {
    setState(() {
      widget.lastKeyEvent = event;
    });
  }

  int numLines = 1;
  double initialWidth = 21;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            color: widget.options.linebarColor,
            constraints: BoxConstraints(minWidth: 10, maxWidth: initialWidth),
            child: Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: linecountBar(),
            )),
        Container(
          color: const Color.fromRGBO(0x1b, 0x1b, 0x32, 1),
          width: 5,
          height: MediaQuery.of(context).size.height,
        ),
        IEdtorView(context),
      ],
    );
  }

  // ignore: non_constant_identifier_names
  Widget IEdtorView(BuildContext context) {
    return Expanded(
      child: Container(
        color: const Color.fromRGBO(0x1b, 0x1b, 0x32, 1),
        height: MediaQuery.of(context).size.height,
        width: 1000,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: widget.options.minHeight,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              SizedBox(
                height: MediaQuery.of(context).size.height,
                width: widget.options.minWidth,
                child: RawKeyboardListener(
                  focusNode: _focusNode,
                  onKey: handleKeyEvents,
                  child: TextField(
                    controller: widget.textController,
                    decoration: decoration,
                    scrollController: scrollController,
                    onChanged: (String event) async {
                      handlePossibleExecutingEvents(event);
                      widget.textStream.sink.add(event);

                      widget.onChange();
                    },
                    expands: true,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: TextStyle(
                      color: widget.options.linebarTextColor,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Column linecountBar() {
    return Column(
      children: [
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            controller: linebarController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: numLines,
            itemBuilder: (_, i) => Linebar(
                calculateBarWidth: () {
                  if (i > 9) {
                    SchedulerBinding.instance!
                        .addPostFrameCallback((timeStamp) {
                      setState(() {
                        initialWidth = Linebar.calculateTextSize(i.toString(),
                            style: const TextStyle(
                                fontSize: 18, color: Colors.white),
                            context: context);
                      });
                    });
                  }
                },
                child: Text(
                  i.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                )),
          ),
        )
      ],
    );
  }
}
