import 'dart:async';
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
  final String challengeId;
  final String ext;
  final String content;
  final bool hasRegion;

  FileStreamEvent({
    required this.challengeId,
    required this.ext,
    required this.content,
    required this.hasRegion,
  });
}

// ignore: must_be_immutable
class Editor extends StatefulWidget with IEditor {
  Editor({
    Key? key,
    this.openedFile,
    required this.options,
    required this.language,
  }) : super(key: key);

  // the coding language in the editor

  String language;

  // an instance of the current file

  FileIDE? openedFile;

  // A stream where the text in the editor is changable

  StreamController<FileIDE> fileTextStream =
      StreamController<FileIDE>.broadcast();

  // A stream where you can listen to the changes made in the editor
  StreamController<String> onTextChange = StreamController<String>.broadcast();

  // options of the editor

  EditorOptions options = EditorOptions();

  @override
  State<StatefulWidget> createState() => EditorState();
}

class EditorState extends State<Editor> {
  ScrollController scrollController = ScrollController();
  ScrollController horizontalController = ScrollController();
  ScrollController linebarController = ScrollController();

  TextEditingControllerIDE beforeController = TextEditingControllerIDE();
  TextEditingControllerIDE inController = TextEditingControllerIDE();
  TextEditingController afterController = TextEditingControllerIDE();

  // current amount of lines in the eidtor

  int _currNumLines = 1;

  // the initial width of the line count bar
  double _initialWidth = 28;

  @override
  void initState() {
    super.initState();

    String fileContent = widget.openedFile?.content ?? '';

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (widget.options.hasRegion) {
        handleEditableRegionFields();
      }
    });

    Future.delayed(const Duration(seconds: 0), () {
      double offset = fileContent
              .split('\n')
              .sublist(0, widget.options.region!.start - 1)
              .length *
          getTextHeight();
      scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      scrollController.addListener(() {
        linebarController.jumpTo(scrollController.offset);
      });

      handlePossibleExecutingEvents();
    });

    TextEditingControllerIDE.language = widget.language;
  }

  void handlePossibleExecutingEvents() async {
    String lines =
        beforeController.text + inController.text + afterController.text;

    setState(() {
      _currNumLines = lines.split('\n').length + 3;
    });
  }

  double getTextHeight() {
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

  handleEditableRegionFields([FileIDE? file]) async {
    String fileContent = file?.content ?? widget.openedFile?.content ?? '';
    String fileId = file?.id ?? widget.openedFile!.id;
    bool hasRegion = file?.hasRegion ?? widget.options.hasRegion;

    if (fileContent != '' && hasRegion) {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      int regionEnd;

      if (prefs.get(fileId) != null) {
        regionEnd = int.parse(prefs.getString(fileId) ?? '');
      } else {
        regionEnd = widget.options.region!.end;
      }

      if (fileContent.split('\n').length > 1) {
        String beforeEditableRegionText = fileContent
            .split("\n")
            .sublist(0, widget.options.region!.end)
            .join("\n");

        String inEditableRegionText = fileContent
            .split("\n")
            .sublist(widget.options.region!.start, regionEnd - 1)
            .join("\n");

        String afterEditableRegionText = fileContent
            .split("\n")
            .sublist(regionEnd - 1, fileContent.split("\n").length)
            .join("\n");

        beforeController.text = beforeEditableRegionText;
        inController.text = inEditableRegionText;
        afterController.text = afterEditableRegionText;
      }
    } else {
      inController.text = fileContent;
    }

    setState(() {
      _currNumLines = fileContent.split("\n").length;
    });
  }

  handleRegionCaching() {
    inController.addListener(() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      int beforeRegionLines = beforeController.text.split('\n').length;
      int inRegionLines = inController.text.split('\n').length + 1;

      int newRegionLines = beforeRegionLines + inRegionLines;

      if (prefs.get(widget.openedFile!.id) != null) {
        String cached = prefs.getString(widget.openedFile!.id) ?? '0';

        int oldRegionLines = int.parse(cached);

        if (oldRegionLines != newRegionLines) {
          prefs.setString(
            widget.openedFile!.id,
            newRegionLines.toString(),
          );
        }
      } else {
        prefs.setString(
          widget.openedFile!.id,
          newRegionLines.toString(),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    widget.fileTextStream.stream.listen((file) {
      if (!file.hasRegion) {
        inController.text = file.content;
      } else {
        handleEditableRegionFields(file);
      }

      TextEditingControllerIDE.language = file.ext;
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
        if (widget.options.hasRegion)
          Expanded(
            child: editorViewWithRegion(context),
          )
        else
          Expanded(
            child: editorView(
              context,
            ),
          )
      ],
    );
  }

  Widget editorViewWithRegion(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 0),
      scrollDirection: Axis.horizontal,
      controller: horizontalController,
      children: [
        SizedBox(
          height: 1000,
          width: widget.options.minHeight,
          child: ListView(
            padding: const EdgeInsets.only(top: 0),
            controller: scrollController,
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            children: [
              SizedBox(
                width: widget.options.minHeight,
                child: TextField(
                  controller: beforeController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    fillColor: widget.options.editorBackgroundColor,
                    filled: true,
                    isDense: true,
                    contentPadding: const EdgeInsets.only(top: 10, left: 10),
                  ),
                  enabled: false,
                  maxLines: null,
                  style: const TextStyle(fontSize: 18),
                  scrollPadding: const EdgeInsets.all(0),
                ),
              ),
              Container(
                width: widget.options.minHeight,
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      width: 5,
                      color: widget.options.region!.condition
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                ),
                child: TextField(
                  controller: inController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    fillColor: widget.options.tabBarColor,
                    filled: true,
                    isDense: true,
                    contentPadding: const EdgeInsets.only(left: 10),
                  ),
                  onChanged: (String event) async {
                    handlePossibleExecutingEvents();

                    String text = beforeController.text +
                        '\n' +
                        event +
                        '\n' +
                        afterController.text;

                    widget.onTextChange.add(text);
                  },
                  maxLines: null,
                  scrollPadding: const EdgeInsets.all(0),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              SizedBox(
                width: widget.options.minHeight,
                child: TextField(
                  controller: afterController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    filled: true,
                    fillColor: widget.options.editorBackgroundColor,
                    contentPadding: const EdgeInsets.only(left: 10),
                    isDense: true,
                  ),
                  enabled: false,
                  maxLines: null,
                  style: const TextStyle(fontSize: 18),
                  scrollPadding: const EdgeInsets.all(0),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget editorView(context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      controller: horizontalController,
      children: [
        SizedBox(
          height: 1000,
          width: widget.options.minHeight,
          child: ListView(
            controller: scrollController,
            shrinkWrap: true,
            children: [
              SizedBox(
                width: widget.options.minHeight,
                child: TextField(
                  controller: inController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    fillColor: widget.options.editorBackgroundColor,
                    filled: true,
                    isDense: true,
                    contentPadding: const EdgeInsets.only(left: 10, top: 10),
                  ),
                  onChanged: (String event) async {
                    handlePossibleExecutingEvents();

                    String text = beforeController.text +
                        '\n' +
                        event +
                        '\n' +
                        afterController.text;

                    widget.onTextChange.add(text);
                  },
                  maxLines: null,
                  scrollPadding: const EdgeInsets.all(0),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        )
      ],
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
                        _initialWidth = getTextHeight() + 2;
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
