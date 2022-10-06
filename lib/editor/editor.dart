import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_code_editor/controller/custom_text_controller/custom_text_controller.dart';
import 'package:flutter_code_editor/editor/linebar/linebar_helper.dart';
import 'package:flutter_code_editor/models/editor.dart';
import 'package:flutter_code_editor/models/editor_options.dart';
import 'package:flutter_code_editor/models/file_model.dart';

class FileStreamEvent {
  final String ext;
  final String content;

  FileStreamEvent({required this.ext, required this.content});
}

// ignore: must_be_immutable
class Editor extends StatefulWidget with IEditor {
  Editor({
    Key? key,
    this.openedFile,
    this.options = const EditorOptions(),
    required this.language,
  }) : super(key: key);

  // the coding language in the editor

  String language;

  // an instance of the current file

  FileIDE? openedFile;

  // A stream where the text in the editor is changable

  StreamController<FileStreamEvent> fileTextStream =
      StreamController<FileStreamEvent>.broadcast();

  // A stream where you can listen to the changes made in the editor
  StreamController<String> onTextChange = StreamController<String>.broadcast();

  // holds a copy of the last key events that happened

  RawKeyEvent? lastKeyEvent;

  // options of the editor

  EditorOptions options;

  @override
  State<StatefulWidget> createState() => EditorState();
}

class EditorState extends State<Editor> {
  ScrollController scrollController = ScrollController();
  ScrollController linebarController = ScrollController();

  TextEditingControllerIDE textController = TextEditingControllerIDE();

  // number of lines on the line count bar
  int _numLines = 1;

  // the initial width of the line count bar
  double _initialWidth = 28;

  final FocusNode _focusNode = FocusNode();

  List<String> patternMatches = [];

  @override
  void initState() {
    super.initState();
    TextEditingControllerIDE.language = widget.language;

    scrollController.addListener(() {
      linebarController.jumpTo(scrollController.offset);
    });

    Future.delayed(Duration.zero, (() async {
      textController.text = widget.openedFile?.fileContent ?? '';
      setNewLinebarState(textController.text);
    }));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void handlePossibleExecutingEvents(String event) async {
    // if (widget.openedFile != null && widget.options.useFileExplorer) {
    //   await FileController.writeFile(
    //       widget.openedFile!.filePath, widget.textController!.text);
    // }

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

      _numLines = lines.length;
    });
  }

  void handleKeyEvents(RawKeyEvent event) {
    setState(() {
      widget.lastKeyEvent = event;
    });
  }

  @override
  Widget build(BuildContext context) {
    widget.fileTextStream.stream.listen((event) {
      textController.text = event.content;
      setNewLinebarState(event.content);
      TextEditingControllerIDE.language = event.ext;
    });

    return Row(
      children: [
        Container(
            constraints: BoxConstraints(minWidth: 1, maxWidth: _initialWidth),
            decoration: BoxDecoration(
              color: widget.options.linebarColor,
              border: const Border(
                right: BorderSide(
                  color: Color.fromRGBO(0x88, 0x88, 0x88, 1),
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: linecountBar(),
            )),
        IEdtorView(context),
      ],
    );
  }

  // ignore: non_constant_identifier_names
  Widget IEdtorView(BuildContext context) {
    return Expanded(
      child: Container(
        color: widget.options.linebarColor,
        height: MediaQuery.of(context).size.height,
        width: 1000,
        child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            children: [
              SizedBox(
                height: 300,
                width: widget.options.minHeight,
                child: ListView(
                    padding: EdgeInsets.zero,
                    scrollDirection: Axis.horizontal,
                    children: [
                      SizedBox(
                        height: 300,
                        width: widget.options.minWidth,
                        child: RawKeyboardListener(
                          focusNode: _focusNode,
                          onKey: handleKeyEvents,
                          child: TextField(
                            scrollPadding: EdgeInsets.zero,
                            controller: textController,
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.only(
                                    left: 10,
                                    top:
                                        MediaQuery.of(context).viewPadding.top +
                                            10)),
                            scrollController: scrollController,
                            expands: true,
                            onChanged: (String event) async {
                              handlePossibleExecutingEvents(event);
                              widget.onTextChange.add(event);
                            },
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

  linecountBar() {
    return Column(
      children: [
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            controller: linebarController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _numLines == 0 ? 1 : _numLines,
            itemBuilder: (_, i) => Linebar(
                calculateBarWidth: () {
                  if (i + 1 > 9) {
                    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                      setState(() {
                        _initialWidth = Linebar.calculateTextSize(
                            (i + 1).toString(),
                            style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontFamily: 'RobotoMono'),
                            context: context) + 2;
                      });
                    });
                  }
                },
                child: Text(
                  i == 0 ? (1).toString() : (i + 1).toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color.fromRGBO(0x88, 0x88, 0x88, 1),
                  ),
                )),
          ),
        )
      ],
    );
  }
}
