import 'dart:async';
import 'dart:developer';

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
    this.regionStart = 1,
    this.regionEnd = 2,
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

  // start of the editable region

  int? regionStart;

  // end of the editable region

  int? regionEnd;

  // condition

  bool? condition;

  @override
  State<StatefulWidget> createState() => EditorState();
}

class EditorState extends State<Editor> {
  ScrollController scrollController = ScrollController();
  ScrollController linebarController = ScrollController();

  TextEditingControllerIDE textController = TextEditingControllerIDE();

  final FocusNode _focusNode = FocusNode();

  // current amount of lines in the eidtor

  int _currNumLines = 1;

  // the initial width of the line count bar
  double _initialWidth = 21;

  double _editableRegionHeight = 10;

  int newEditableRegionLines = 0;
  int lastTotalLines = 0;

  int lastEditableRegionIndex = 1;
  String lastEditableRegionLine = '';

  double startRegionPadding = 0;

  Timer? editableRegionUpdateTimer;

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
      calculateEditableRegionPadding();
      setInitialLineState(textController.text);
      setInitalReqionLines(textController.text);
      setLastTotalLines(textController.text);
      calculateEditableRegionHeight();
    }));
  }

  @override
  void dispose() {
    super.dispose();
    _focusNode.dispose();
  }

  void handlePossibleExecutingEvents(
      String event, TextEditingControllerIDE textController) async {
    setCurrentLineState(event);
    setNewAmountOfEditableReqionLines(textController);
    calculateEditableRegionHeight();
  }

  void setCurrentLineState(String event) {
    setState(() {
      TextSpan span = TextSpan(text: event);
      TextPainter tp =
          TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout(
        maxWidth: widget.options.minWidth,
      );

      List lines = tp.computeLineMetrics();

      _currNumLines = lines.length;
    });
  }

  void setInitialLineState(String event) {
    setState(() {
      TextSpan span = TextSpan(text: event);
      TextPainter tp =
          TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout(
        maxWidth: widget.options.minWidth,
      );

      List lines = tp.computeLineMetrics();

      _currNumLines = lines.length;
    });
  }

  void setLastTotalLines(String editorText) {
    setState(() {
      lastTotalLines = editorText.split('\n').length;
    });
  }

  String getLineInRegion(String editorText, int index) {
    List indecies = editorText.split('\n');

    return indecies[index] ?? '';
  }

  void setInitalReqionLines(String editorText) {
    setState(() {
      lastEditableRegionLine =
          getLineInRegion(editorText, widget.regionEnd! - 1);
      lastEditableRegionIndex = widget.regionEnd! - 1;
    });
  }

  void setNewAmountOfEditableReqionLines(TextEditingControllerIDE controller) {
    // first line after the editable region
    String firstLineAfter =
        getLineInRegion(controller.text, lastEditableRegionIndex);

    int newTotalLines = controller.text.split('\n').length;
    List newLines = controller.text.split('\n');

    if (firstLineAfter.isEmpty && lastEditableRegionLine.isEmpty) {
      if (lastTotalLines < newTotalLines) {
        setState(() {
          newEditableRegionLines++;
        });
      }

      if (lastTotalLines > newTotalLines) {
        setState(() {
          newEditableRegionLines--;
        });
      }
    }

    if (firstLineAfter != lastEditableRegionLine &&
        lastTotalLines < newTotalLines) {
      setState(() {
        newEditableRegionLines++;
        lastEditableRegionIndex++;
      });
    }

    if (firstLineAfter != lastEditableRegionLine &&
        lastTotalLines > newTotalLines) {
      setState(() {
        newEditableRegionLines--;
        lastEditableRegionIndex--;
      });
    }

    if (newLines[lastEditableRegionIndex + 1] == '') {
      setState(() {
        newEditableRegionLines++;
        lastEditableRegionIndex++;
      });
    }

    setState(() {
      lastTotalLines = newTotalLines;
    });
  }

  void calculateEditableRegionHeight() {
    int handleNumLines = _currNumLines == 0
        ? 1
        : widget.regionEnd! + 1 - widget.regionStart! + newEditableRegionLines;

    setState(() {
      _editableRegionHeight = Linebar.calculateTextSize('1',
                  style: TextStyle(
                    color: widget.options.linebarTextColor,
                    fontSize: 18,
                  ),
                  context: context)
              .height *
          handleNumLines;
    });
  }

  void removeEditableRegon() {
    setState(() {
      _editableRegionHeight = 0;
    });
  }

  void startEditableRegionUpdateTimer() {
    const mil = Duration(milliseconds: 500);

    void setActualTimer() {
      editableRegionUpdateTimer = Timer(mil, () {
        calculateEditableRegionPadding(scrollController.offset);

        if (_editableRegionHeight == 0) {
          calculateEditableRegionHeight();
        }

        if (startRegionPadding == 0) {
          removeEditableRegon();
        }
      });
    }

    if (editableRegionUpdateTimer == null) {
      setActualTimer();
    } else if (!editableRegionUpdateTimer!.isActive) {
      setActualTimer();
    }
  }

  void calculateEditableRegionPadding([double? scrollOfset = 0]) {
    double viewInset = MediaQuery.of(context).viewPadding.top + 10;
    int handleRegion = widget.regionStart! <= 1 ? 1 : widget.regionStart! - 1;
    double size = Linebar.calculateTextSize('1',
            style: TextStyle(
              color: widget.options.linebarTextColor,
              fontSize: 18,
            ),
            context: context)
        .height;

    double newRegionPadding =
        handleRegion * size + viewInset - (scrollOfset ?? 0);

    if (widget.regionStart != null) {
      setState(() {
        startRegionPadding = newRegionPadding < 0 ? 0 : newRegionPadding;
      });
    }
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
      TextEditingControllerIDE.language = event.ext;
      setCurrentLineState(event.content);
    });

    scrollController.addListener(() {
      startEditableRegionUpdateTimer();
    });

    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              widget.options.hasEditableRegion
                  ? Padding(
                      padding: EdgeInsets.only(top: startRegionPadding),
                      child: Container(
                        decoration: BoxDecoration(
                            color: const Color.fromRGBO(0x0a, 0x0a, 32, 1),
                            border: Border(
                                left: BorderSide(
                                    width: 27,
                                    color: widget.condition ?? false
                                        ? Colors.green
                                        : Colors.grey))),
                        height: _editableRegionHeight,
                        width: widget.options.minWidth,
                      ),
                    )
                  : Container(),
              Padding(
                padding: EdgeInsets.only(left: _initialWidth + 5),
                child: IEdtorView(context),
              ),
              Container(
                  color: widget.options.linebarColor,
                  width: _initialWidth,
                  child: linecountBar()),
            ],
          ),
        ),
      ],
    );
  }

  // ignore: non_constant_identifier_names
  Widget IEdtorView(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: 1000,
      child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 300,
              width: widget.options.minHeight,
              child: RawKeyboardListener(
                focusNode: _focusNode,
                onKey: handleKeyEvents,
                child: ListView(
                    padding: EdgeInsets.zero,
                    scrollDirection: Axis.horizontal,
                    children: [
                      SizedBox(
                        height: 300,
                        width: widget.options.minWidth,
                        child: Padding(
                          padding: EdgeInsets.only(
                              left: 10,
                              top: MediaQuery.of(context).viewPadding.top + 10),
                          child: TextField(
                            scrollPadding: EdgeInsets.zero,
                            controller: textController,
                            decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero),
                            scrollController: scrollController,
                            expands: true,
                            onChanged: (String event) async {
                              handlePossibleExecutingEvents(
                                  event, textController);
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
            ),
          ]),
    );
  }

  linecountBar() {
    return Column(
      children: [
        SizedBox(
            width: 10, height: MediaQuery.of(context).viewPadding.top + 10),
        Flexible(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            controller: linebarController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _currNumLines == 0 ? 1 : _currNumLines,
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
                                context: context)
                            .width;
                      });
                    });
                  }
                },
                child: Text(
                  i == 0 ? (1).toString() : (i + 1).toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: widget.options.linebarTextColor),
                )),
          ),
        )
      ],
    );
  }
}
