import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:phone_ide/controller/custom_text_controller.dart';
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
  final String language;

  // A stream where the text in the editor is changable
  final StreamController<FileIDE> fileTextStream =
      StreamController<FileIDE>.broadcast();

  // A stream where you can listen to the changes made in the editor
  final StreamController<String> onTextChange =
      StreamController<String>.broadcast();

  // options of the editor
  final EditorOptions options;

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
  double _height = 0;

  String currentFileId = '';

  updateLineCount(double? totalHeight) async {
    totalHeight = totalHeight ?? 48;
    _height = totalHeight;
    double totalLines = totalHeight / getTextHeight(context);

    double totalHeightWithoutPadding = totalHeight - totalLines * 3;
    double totalLinesWithoutPadding =
        totalHeightWithoutPadding / getTextHeight(context);

    setState(() {
      _currNumLines = totalLinesWithoutPadding.toInt() + 1;
    });
  }

  getLineWidth(BuildContext context) {
    String text = beforeController.text +
        '\n' +
        inController.text +
        '\n' +
        afterController.text;

    Size textSize = Linebar.calculateTextSize(
      text[0],
      style: TextStyle(
        color: widget.options.linebarTextColor,
      ),
      context: context,
      maxWidth: context.size?.width ?? 0,
    );

    List<bool> includesNewLine = [];

    List<String> countNewLines(List<String> textArr) {
      bool needsToRecurse = false;
      for (int i = 0; i < textArr.length; i++) {
        if (textArr[i].length > 35) {
          List<String> words = textArr[i].split(' ');

          int emptySpace = 0;
          int totalLength = 0;
          String wordBeforeCutting = '';

          for (int j = 0; j < words.length; j++) {
            if (words[j] == '') {
              emptySpace++;
            } else {
              if ((totalLength += words[j].length + emptySpace) >= 35) {
                wordBeforeCutting = words[j];

                textArr.insert(
                  i + 1,
                  wordBeforeCutting + textArr[i].split(wordBeforeCutting)[1],
                );

                textArr[i] = textArr[i].split(wordBeforeCutting)[0];

                needsToRecurse = true;
              }
              emptySpace = 0;
            }
          }
        }
      }

      if (needsToRecurse) {
        countNewLines(textArr);
      } else {
        return textArr;
      }

      return textArr;
    }

    List<String> textLines = countNewLines(text.split('\n'));
    log(textLines.toString());
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
        });
      }
      scrollController.addListener(() {
        linebarController.jumpTo(scrollController.offset);
      });
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
            file.content.split('\n').sublist(0, regionStart).join('\n');

        String inEditableRegionText = file.content
            .split('\n')
            .sublist(regionStart, regionEnd - 1)
            .join('\n');

        String afterEditableRegionText = file.content
            .split('\n')
            .sublist(regionEnd - 1, file.content.split('\n').length)
            .join('\n');
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
      _currNumLines = file.content.split('\n').length;
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

  handleTextChange(FileIDE file, String code, String region) {
    if (file.hasRegion && region != 'AFTER') {
      handleRegionCaching(file, code, region);
    }

    late String text;

    switch (region) {
      case 'BEFORE':
        text = code + '\n' + inController.text + '\n' + afterController.text;
        break;
      case 'IN':
        text =
            beforeController.text + '\n' + code + '\n' + afterController.text;
        break;
      case 'AFTER':
        text = beforeController.text + '\n' + inController.text + '\n' + code;
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
                child: linecountBar(),
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
      padding: const EdgeInsets.only(
        top: 0,
      ),
      scrollDirection: Axis.horizontal,
      physics: widget.options.wrap
          ? const NeverScrollableScrollPhysics()
          : const ScrollPhysics(),
      controller: horizontalController,
      children: [
        SizedBox(
          height: 1000,
          width: widget.options.wrap ? MediaQuery.of(context).size.width : 2500,
          child: ListView(
            padding: widget.options.editorPadding,
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            shrinkWrap: true,
            children: [
              LayoutBuilder(
                builder: (localContext, constraints) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (localContext.size?.height != _height) {
                      updateLineCount(localContext.size?.height);
                    }
                  });

                  return Column(
                    children: [
                      if (file.hasRegion)
                        TextField(
                          smartQuotesType: SmartQuotesType.disabled,
                          smartDashesType: SmartDashesType.disabled,
                          controller: beforeController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            fillColor: widget.options.editorBackgroundColor,
                            filled: true,
                            isDense: true,
                            contentPadding: EdgeInsets.only(
                              left: 10,
                              right: widget.options.wrap ? _initialWidth : 0,
                            ),
                          ),
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.87),
                          ),
                          onChanged: (String code) {
                            handleTextChange(file, code, 'BEFORE');
                            getLineWidth(localContext);
                          },
                        ),
                      Container(
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
                          smartQuotesType: SmartQuotesType.disabled,
                          smartDashesType: SmartDashesType.disabled,
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
                              right: widget.options.wrap ? _initialWidth : 0,
                              top: file.hasRegion ? 0 : 10,
                            ),
                          ),
                          onChanged: (String code) {
                            handleTextChange(file, code, 'IN');
                          },
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.87),
                          ),
                        ),
                      ),
                      if (file.hasRegion)
                        TextField(
                          smartQuotesType: SmartQuotesType.disabled,
                          smartDashesType: SmartDashesType.disabled,
                          controller: afterController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            filled: true,
                            fillColor: widget.options.editorBackgroundColor,
                            contentPadding: EdgeInsets.only(
                              left: 10,
                              right: widget.options.wrap ? _initialWidth : 0,
                            ),
                            isDense: true,
                          ),
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.87),
                          ),
                          onChanged: (String code) {
                            handleTextChange(file, code, 'AFTER');
                          },
                        )
                    ],
                  );
                },
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
            padding: const EdgeInsets.only(top: 10),
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
