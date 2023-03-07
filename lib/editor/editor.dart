import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_code_editor/controller/custom_text_controller/custom_text_controller.dart';
import 'package:flutter_code_editor/editor/linebar/linebar_helper.dart';
import 'package:flutter_code_editor/models/editor.dart';
import 'package:flutter_code_editor/models/editor_options.dart';
import 'package:flutter_code_editor/models/file_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';

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
    required this.options,
    this.regionStart = 1,
    this.regionEnd = 2,
    this.condition,
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

  // options of the editor

  EditorOptions options = EditorOptions();

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

  // current amount of lines in the eidtor

  int _currNumLines = 1;

  // the initial width of the line count bar
  double _initialWidth = 28;

  double _editableRegionHeight = 10;

  int newEditableRegionLines = 0;
  int lastTotalLines = 0;

  int lastEditableRegionIndex = 0;
  String lastEditableRegionLine = '';

  int linesBeforeEditableRegion = 0;

  double startRegionPadding = 0;
  double highestInset = 0;

  Timer? editableRegionUpdateTimer;

  List<String> lastEditableRegionLinesArr = [];
  List<String> newEditableRegionLinesArr = [];

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
      setInitialLineState(textController.text);
      setLastTotalLines(textController.text);
      if (widget.options.hasEditableRegion) {
        calculateEditableRegionPadding();
        setInitialRegionLines(textController.text);
        calculateEditableRegionHeight(textController.text);

        double offset = textController.text
                .split('\n')
                .sublist(0, widget.regionStart! - 1)
                .length *
            returnTextHeight();

        scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }));
  }

  void handlePossibleExecutingEvents(
    String event,
    TextEditingControllerIDE textController,
  ) async {
    setCurrentLineState(event);
    if (widget.options.hasEditableRegion) {
      setNewAmountOfEditableRegionLines(textController);
      calculateEditableRegionHeight(textController.text);
    }
  }

  void setCurrentLineState(String event) {
    setState(() {
      TextSpan span = TextSpan(text: event);

      TextPainter tp = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
      );

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

      TextPainter tp = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
      );

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
    List lines = editorText.split('\n');

    return lines.length > index ? lines[index] : '';
  }

  void setInitialRegionLines(String editorText) {
    setState(() {
      lastEditableRegionLine = getLineInRegion(
        editorText,
        widget.regionEnd! - 1,
      );
      lastEditableRegionIndex = widget.regionEnd! - 1;
      lastEditableRegionLinesArr = editorText
          .split('\n')
          .sublist(widget.regionStart!, widget.regionEnd! - 1);
      for (var i = 0; i < lastEditableRegionLinesArr.length; i++) {
        lastEditableRegionLinesArr[i] = lastEditableRegionLinesArr[i].trim();
      }
    });
  }

  void setNewAmountOfEditableRegionLines(TextEditingControllerIDE controller) {
    bool changeInEditableRegion = false;
    controller.text
        .split('\n')
        .sublist(widget.regionStart!, lastEditableRegionIndex)
        .forEach((element) {
      if (!lastEditableRegionLinesArr.contains(
        element.replaceAll(RegExp(r'(?<!\n)\s'), ''),
      )) {
        changeInEditableRegion = true;
      }
    });

    // Expand the region only if changes are done in editable region
    if (changeInEditableRegion) {
      // first line after the editable region
      String firstLineAfter = getLineInRegion(
        controller.text,
        lastEditableRegionIndex,
      );

      int newTotalLines = controller.text.split('\n').length;
      List newLines = controller.text.split('\n');

      // Check if the first line after the editable region has changed
      bool lineAreDiff = firstLineAfter != lastEditableRegionLine;

      // Handle editable region old and new
      int oldEditableRegion = widget.regionEnd! - widget.regionStart! - 1;
      int newEditableRegion = oldEditableRegion + newEditableRegionLines;

      // If the linecount is one and the last total lines is bigger than new total lines
      // then we should ignore the request to update the editable region
      if (newEditableRegion <= 1 && lastTotalLines > newTotalLines) {
        return;
      }

      // If the first line after the editable region is different from the last
      // line in the editable region then we should update the editable region with
      // an extra line.

      if (lineAreDiff && lastTotalLines < newTotalLines) {
        setState(() {
          newEditableRegionLines++;
          lastEditableRegionIndex++;
        });
      }

      // If the first line after the editable region is different from the last line in the editable
      // region and the last total lines is bigger than the new total lines then we should remove a
      // line from the editable region
      if (lineAreDiff && lastTotalLines > newTotalLines) {
        setState(() {
          newEditableRegionLines--;
          lastEditableRegionIndex--;
        });
      }

      if (!lineAreDiff && lastTotalLines > newTotalLines) {
        setState(() {
          newEditableRegionLines--;
          lastEditableRegionIndex--;
        });
      }

      // If the line after editable region is empty after pressing enter then we should add a line.
      if (newLines.length > lastEditableRegionIndex + 1
          ? newLines[lastEditableRegionIndex + 1] == ''
          : newLines[0] == '') {
        setState(() {
          newEditableRegionLines++;
          lastEditableRegionIndex++;
        });
      }

      // Set the last total lines to the new total lines
      setState(() {
        lastTotalLines = newTotalLines;
      });
    }
  }

  double returnTextHeight() {
    double systemFonstSize = MediaQuery.of(context).textScaleFactor;

    double fontSize = systemFonstSize > 1 ? 18 * systemFonstSize : 18;

    Size textHeight = Linebar.calculateTextSize(
      'L',
      style: TextStyle(
        color: widget.options.linebarTextColor,
        fontSize: fontSize,
      ),
      context: context,
    );

    return textHeight.height;
  }

  void calculateEditableRegionHeight(String text, [double scrollOfset = 0]) {
    // Handle editable region old and new
    int oldEditableRegion = widget.regionEnd! - widget.regionStart! - 1;
    int newEditableRegion = oldEditableRegion + newEditableRegionLines;

    List<String> lines = text.split('\n');
    int linesBefore = lines.sublist(0, widget.regionStart!).length;

    double paddingEnd = linesBefore * returnTextHeight() + 10;

    double reduceSize = scrollOfset < paddingEnd ? 0 : scrollOfset - paddingEnd;
    double newHeight = newEditableRegion * returnTextHeight() - reduceSize;

    _editableRegionHeight = newHeight <= 0 ? 1 : newHeight;
  }

  void removeEditableRegon() {
    setState(() {
      _editableRegionHeight = 0;
    });
  }

  void startEditableRegionUpdateTimer(
    String text, [
    double? scrollOfset = 0,
  ]) {
    const mil = Duration(milliseconds: 250);

    void setActualTimer() {
      editableRegionUpdateTimer = Timer(mil, () {
        double offset = scrollController.offset;

        calculateEditableRegionPadding(offset);

        calculateEditableRegionHeight(text, offset);
      });
    }

    if (widget.regionStart == null && widget.regionEnd == null) {
      return;
    }

    if (editableRegionUpdateTimer == null) {
      setActualTimer();
    } else if (!editableRegionUpdateTimer!.isActive) {
      setActualTimer();
    }
  }

  void calculateInset(double topInset) async {
    if (topInset >= highestInset && Platform.isAndroid) {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      if (prefs.getInt('highestInset') == null) {
        prefs.setInt('highestInset', topInset.toInt());
      } else {
        if (prefs.getInt('highestInset')! < topInset.toInt()) {
          prefs.setInt('highestInset', topInset.toInt());
        }
      }

      highestInset = prefs.getInt('highestInset')!.toDouble();
    }
  }

  void calculateEditableRegionPadding([
    double scrollOfset = 0,
  ]) async {
    double viewInset = MediaQuery.of(context).viewPadding.top;
    int regionStart = widget.regionStart! - (Platform.isAndroid ? 1 : 0);
    double textSize = returnTextHeight();

    double totalTextSize = regionStart * textSize;
    double newRegionPadding = totalTextSize + highestInset - scrollOfset;

    if (widget.regionStart != null) {
      setState(() {
        startRegionPadding = newRegionPadding < 0 ? 0 : newRegionPadding;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    widget.fileTextStream.stream.listen((event) {
      textController.text = event.content;
      TextEditingControllerIDE.language = event.ext;
      setCurrentLineState(event.content);
    });

    scrollController.addListener(() {
      startEditableRegionUpdateTimer(
        textController.text,
        scrollController.offset,
      );
    });

    return Row(
      children: [
        Container(
          constraints: BoxConstraints(
            minWidth: 1,
            maxWidth: _initialWidth,
          ),
          decoration: BoxDecoration(
            color: widget.options.linebarColor,
            border: const Border(
              right: BorderSide(
                color: Color.fromRGBO(0x88, 0x88, 0x88, 1),
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              top: 10,
            ),
            child: linecountBar(),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              if (widget.options.hasEditableRegion)
                Padding(
                  padding: EdgeInsets.only(
                    top: startRegionPadding,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(0x0a, 0x0a, 32, 1),
                      border: Border(
                        left: BorderSide(
                          width: 5,
                          color: widget.condition ?? false
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                    ),
                    height: _editableRegionHeight,
                    width: widget.options.minWidth,
                  ),
                ),
              IEdtorView(context),
            ],
          ),
        ),
      ],
    );
  }

  // ignore: non_constant_identifier_names
  Widget IEdtorView(BuildContext context) {
    return Container(
      color: widget.options.hasEditableRegion
          ? Colors.transparent
          : const Color.fromRGBO(0x1b, 0x1b, 0x32, 1),
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
                  child: TextField(
                    scrollPadding: EdgeInsets.zero,
                    controller: textController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(
                        left: 10,
                        top: 10,
                      ),
                    ),
                    scrollController: scrollController,
                    expands: true,
                    onChanged: (String event) async {
                      handlePossibleExecutingEvents(
                        event,
                        textController,
                      );
                      widget.onTextChange.add(event);
                    },
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: TextStyle(
                      color: widget.options.hasEditableRegion
                          ? widget.options.linebarTextColor
                          : Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  linecountBar() {
    return Column(
      children: [
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
                  SchedulerBinding.instance.addPostFrameCallback(
                    (timeStamp) {
                      setState(() {
                        _initialWidth = returnTextHeight() + 2;
                      });
                    },
                  );
                }
              },
              child: Text(
                i == 0 ? (1).toString() : (i + 1).toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: widget.options.linebarTextColor,
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
