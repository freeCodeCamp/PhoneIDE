import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:phone_ide/controller/custom_text_controller/custom_text_controller.dart';
import 'package:phone_ide/editor/linebar.dart';
import 'package:phone_ide/editor/editor_options.dart';
import 'package:phone_ide/models/file.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Editor extends StatefulWidget {
  Editor({
    Key? key,
    required this.options,
    required this.language,
  }) : super(key: key);

  // the coding language in the editor

  String language;

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
  TextEditingControllerIDE afterController = TextEditingControllerIDE();

  int _currNumLines = 1;

  double _initialWidth = 28;

  String currentFileId = '';

  @override
  void initState() {
    super.initState();
  }

  void updateLineCount(FileIDE file, String event, String region) async {
    late String lines;
    switch (region) {
      case 'BEFORE':
        lines = event + '\n' + inController.text + '\n' + afterController.text;
        break;
      case 'IN':
        lines =
            beforeController.text + '\n' + event + '\n' + afterController.text;
        break;
      case 'AFTER':
        lines = beforeController.text + '\n' + inController.text + '\n' + event;
        break;
    }

    setState(() {
      _currNumLines = lines.split('\n').length;
    });
  }

  double getTextHeight(BuildContext context, {double fontSize = 18}) {
    double systemFontSize = MediaQuery.of(context).textScaleFactor;

    double calculatedFontSize =
        systemFontSize > 1 ? fontSize * systemFontSize : fontSize;

    Size textHeight = Linebar.calculateTextSize(
      'L',
      style: TextStyle(
        color: widget.options.linebarTextColor,
        fontSize: calculatedFontSize,
      ),
      context: context,
    );

    return textHeight.height;
  }

  handleFileInit(FileIDE file) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String fileContent = file.content;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      handleRegionFields(file);

      if (file.hasRegion) {
        int regionStart = file.region.start!;
        if (prefs.get(file.id) != null) {
          regionStart =
              int.parse(prefs.getString(file.id)?.split(':')[0] ?? '');
        }

        Future.delayed(const Duration(seconds: 0), () {
          double offset =
              fileContent.split('\n').sublist(0, regionStart - 1).length *
                  getTextHeight(context);
          scrollController.animateTo(
            offset,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );

          scrollController.addListener(() {
            linebarController.jumpTo(scrollController.offset);
          });
        });
      }
    });

    TextEditingControllerIDE.language = widget.language;
  }

  handleRegionFields(FileIDE file) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (file.hasRegion) {
      int regionStart = file.region.start!;
      int regionEnd = file.region.end!;

      if (prefs.get(file.id) != null) {
        regionStart = int.parse(prefs.getString(file.id)?.split(':')[0] ?? '');
        regionEnd = int.parse(prefs.getString(file.id)?.split(':')[1] ?? '');
      }

      if (file.content.split('\n').length > 1) {
        String beforeEditableRegionText =
            file.content.split("\n").sublist(0, regionStart).join("\n");

        String inEditableRegionText = file.content
            .split("\n")
            .sublist(regionStart, regionEnd - 1)
            .join("\n");

        String afterEditableRegionText = file.content
            .split("\n")
            .sublist(regionEnd - 1, file.content.split("\n").length)
            .join("\n");
        beforeController.text = beforeEditableRegionText;
        inController.text = inEditableRegionText;
        afterController.text = afterEditableRegionText;
      }
    } else {
      beforeController.text = '';
      inController.text = file.content;
      afterController.text = '';
    }

    setState(() {
      _currNumLines = file.content.split("\n").length;
    });
  }

  handleRegionCaching(FileIDE file, String event, String region) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    late int beforeRegionLines;
    late int inRegionLines;
    late int newRegionlines;

    if (region == 'BEFORE') {
      beforeRegionLines = event.split('\n').length;
      inRegionLines = inController.text.split('\n').length + 1;
      newRegionlines = inRegionLines + beforeRegionLines;
    } else if (region == 'IN') {
      beforeRegionLines = beforeController.text.split('\n').length;
      inRegionLines = event.split('\n').length + 1;
      newRegionlines = inRegionLines + beforeRegionLines;
    }

    prefs.setString(
      file.id,
      '$beforeRegionLines:$newRegionlines',
    );
  }

  handleTextChange(FileIDE file, String event, String region) {
    updateLineCount(file, event, region);

    if (file.hasRegion && region != 'AFTER') {
      handleRegionCaching(file, event, region);
    }

    late String text;

    switch (region) {
      case 'BEFORE':
        text = event + '\n' + inController.text + '\n' + afterController.text;
        break;
      case 'IN':
        text =
            beforeController.text + '\n' + event + '\n' + afterController.text;
        break;
      case 'AFTER':
        text = beforeController.text + '\n' + inController.text + '\n' + event;
        break;
    }

    widget.onTextChange.sink.add(text);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FileIDE>(
      stream: widget.fileTextStream.stream,
      builder: (context, snapshot) {
        FileIDE? file;

        if (snapshot.hasData) {
          if (snapshot.data is FileIDE) {
            file = snapshot.data as FileIDE;

            if (file.id != currentFileId) {
              handleFileInit(file);
              currentFileId = file.id;
            }

            TextEditingControllerIDE.language = file.ext;
          } else {
            return const Center(
              child: Text('Something went wrong'),
            );
          }

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
                child: Container(
                  color: widget.options.editorBackgroundColor,
                  child: editorView(context, file),
                ),
              )
            ],
          );
        }

        return const Center(child: Text('open file'));
      },
    );
  }

  Widget editorView(BuildContext context, FileIDE file) {
    return ListView(
      padding: const EdgeInsets.only(top: 0),
      scrollDirection: Axis.horizontal,
      controller: horizontalController,
      children: [
        SizedBox(
          height: 1000,
          width: widget.options.minHeight,
          child: ListView(
            padding: const EdgeInsets.only(
              top: 0,
            ),
            controller: scrollController,
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            children: [
              if (file.hasRegion)
                SizedBox(
                  width: widget.options.minHeight,
                  child: TextField(
                    controller: beforeController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      fillColor: widget.options.editorBackgroundColor,
                      filled: true,
                      isDense: true,
                      contentPadding: const EdgeInsets.only(
                        top: 10,
                        left: 10,
                      ),
                    ),
                    maxLines: null,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.87),
                    ),
                    onChanged: (String event) {
                      handleTextChange(file, event, 'BEFORE');
                    },
                  ),
                ),
              Container(
                width: widget.options.minHeight,
                decoration: file.hasRegion
                    ? BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            width: 5,
                            color: file.region.condition
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                      )
                    : null,
                child: TextField(
                  controller: inController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    fillColor: file.hasRegion
                        ? file.region.color
                        : widget.options.editorBackgroundColor,
                    filled: true,
                    isDense: true,
                    contentPadding: EdgeInsets.only(
                      left: 10,
                      top: file.hasRegion ? 0 : 10,
                    ),
                  ),
                  onChanged: (String event) {
                    handleTextChange(file, event, 'IN');
                  },
                  maxLines: null,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.87),
                  ),
                ),
              ),
              if (file.hasRegion)
                SizedBox(
                  width: widget.options.minHeight,
                  child: TextField(
                    controller: afterController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      filled: true,
                      fillColor: widget.options.editorBackgroundColor,
                      contentPadding: const EdgeInsets.only(
                        left: 10,
                      ),
                      isDense: true,
                    ),
                    maxLines: null,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.87),
                    ),
                    onChanged: (String event) {
                      handleTextChange(file, event, 'AFTER');
                    },
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
                        _initialWidth = getTextHeight(context) + 8;
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
