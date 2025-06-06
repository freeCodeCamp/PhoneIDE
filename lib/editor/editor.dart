import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:phone_ide/controller/custom_text_controller.dart';
import 'package:phone_ide/editor/editor_options.dart';
import 'package:phone_ide/editor/linebar.dart';
import 'package:phone_ide/models/file.dart';
import 'package:phone_ide/models/textfield_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Editor extends StatefulWidget {
  Editor({
    Key? key,
    required this.options,
    required this.language,
  }) : super(key: key);

  // The coding language you want to enable syntax highlighting for.
  final String language;

  // Stream that enables you to change an emulated file in the editor.
  final StreamController<FileIDE> fileTextStream =
      StreamController<FileIDE>.broadcast();

  // Stream that holds the entire editor content.
  final StreamController<String> onTextChange =
      StreamController<String>.broadcast();

  // Stream that tells which controller the user is currently using. E.g.:
  // The crontroller before the editable region, the one for the region and the
  // one that comes after.

  final StreamController<TextFieldData> textfieldData =
      StreamController<TextFieldData>.broadcast();

  // Stream that holds the contents of the editable region.
  final StreamController<String> editableRegion =
      StreamController<String>.broadcast();

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

  String currentFileName = '';

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      linebarController.jumpTo(scrollController.offset);
    });
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
    linebarController.dispose();
  }

  bool isLoading = false;

  void updateLineCount(String event, RegionPosition region) async {
    late String lines;

    if (widget.options.hasRegion) {
      switch (region) {
        case RegionPosition.before:
          lines = event +
              (event.isNotEmpty ? '\n' : '') +
              inController.text +
              (afterController.text.isNotEmpty ? '\n' : '') +
              afterController.text;
          break;
        case RegionPosition.inner:
          lines = beforeController.text +
              (beforeController.text.isNotEmpty ? '\n' : '') +
              event +
              (afterController.text.isNotEmpty ? '\n' : '') +
              afterController.text;
          break;
        case RegionPosition.after:
          lines = beforeController.text +
              (beforeController.text.isNotEmpty ? '\n' : '') +
              inController.text +
              (event.isNotEmpty ? '\n' : '') +
              event;
          break;
      }
    }

    if (!widget.options.hasRegion) {
      lines = event;
    }

    setState(() {
      _currNumLines = lines.split('\n').length;
    });
  }

  double getTextHeight(BuildContext context, {double fontSize = 18}) {
    TextScaler textScaler = MediaQuery.of(context).textScaler;

    double calculatedFontSize = textScaler.scale(fontSize);

    Size textHeight = Linebar.calculateTextSize(
      'L',
      style: TextStyle(
        color: widget.options.linebarTextColor,
        fontSize: calculatedFontSize,
        fontFamily: widget.options.fontFamily,
      ),
      context: context,
    );

    return textHeight.height;
  }

  double getFontSize(BuildContext context, {double fontSize = 18}) {
    TextScaler textScaler = MediaQuery.of(context).textScaler;

    double calculatedFontSize = textScaler.scale(fontSize);

    return calculatedFontSize;
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

        if (file.content.split('\n').length > 7) {
          Future.delayed(const Duration(milliseconds: 250), () {
            double offset = fileContent
                    .split('\n')
                    .sublist(0, regionStart - 1 < 0 ? 0 : regionStart - 1)
                    .length *
                getTextHeight(context);
            scrollController.animateTo(
              offset,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          });
        }
      }

      if (scrollController.hasClients && linebarController.hasClients) {
        linebarController.jumpTo(0);
        scrollController.jumpTo(0);
      }
      isLoading = false;
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

      int lines = file.content.split('\n').length;

      if (lines >= 1) {
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

    updateLineCount(inController.text, RegionPosition.inner);
  }

  handleRegionCaching(FileIDE file, String event, RegionPosition region) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    late int beforeRegionLines;
    late int inRegionLines;
    late int newRegionlines;

    if (region == RegionPosition.before) {
      beforeRegionLines = event.split('\n').length;
      inRegionLines = inController.text.split('\n').length + 1;
      newRegionlines = inRegionLines + beforeRegionLines;
    } else if (region == RegionPosition.inner) {
      beforeRegionLines = beforeController.text.split('\n').length;
      inRegionLines = event.split('\n').length + 1;
      newRegionlines = inRegionLines + beforeRegionLines;
    }

    prefs.setString(
      file.id,
      '$beforeRegionLines:$newRegionlines',
    );
  }

  handleTextChange(String event, RegionPosition region, bool hasRegion) {
    updateLineCount(event, region);

    late String text;

    switch (region) {
      case RegionPosition.before:
        text = '$event\n${inController.text}\n${afterController.text}';
        break;
      case RegionPosition.inner:
        if (hasRegion) {
          text = '${beforeController.text}\n$event\n${afterController.text}';
        } else {
          text = event;
        }
        widget.editableRegion.sink.add(event);
        break;
      case RegionPosition.after:
        text = '${beforeController.text}\n${inController.text}\n$event';
        break;
    }

    widget.onTextChange.sink.add(text);
  }

  handleCurrentFocusedTextfieldController(RegionPosition position) {
    if (position == RegionPosition.before) {
      widget.textfieldData.sink.add(
        TextFieldData(
          controller: beforeController,
          position: RegionPosition.before,
        ),
      );
    } else if (position == RegionPosition.inner) {
      widget.textfieldData.sink.add(
        TextFieldData(
          controller: inController,
          position: RegionPosition.inner,
        ),
      );
    } else if (position == RegionPosition.after) {
      widget.textfieldData.sink.add(
        TextFieldData(
          controller: afterController,
          position: RegionPosition.after,
        ),
      );
    }
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

            widget.textfieldData.stream.listen((event) {
              handleTextChange(
                event.controller.text,
                event.position,
                file!.hasRegion,
              );
            });

            if (file.name != currentFileName) {
              isLoading = true;
              handleFileInit(file);
              currentFileName = file.name;
            }

            TextEditingControllerIDE.language = file.ext;
          } else {
            return const Center(
              child: Text('Something went wrong'),
            );
          }

          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final mediaQueryData = MediaQuery.of(context);

          return MediaQuery(
            data: mediaQueryData.copyWith(
              textScaler: TextScaler.noScaling,
            ),
            child: Row(
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
                    child: MediaQuery(
                      data: const MediaQueryData(
                        gestureSettings: DeviceGestureSettings(touchSlop: 8.0),
                      ),
                      child: editorView(context, file),
                    ),
                  ),
                )
              ],
            ),
          );
        }

        return const Center(child: Text('open file'));
      },
    );
  }

  Widget editorView(BuildContext context, FileIDE file) {
    return ListView(
      padding: const EdgeInsets.only(top: 0),
      physics: const ClampingScrollPhysics(),
      scrollDirection: Axis.horizontal,
      controller: horizontalController,
      children: [
        SizedBox(
          height: 1000,
          width: 2500,
          child: ListView(
            padding: widget.options.hasRegion
                ? const EdgeInsets.only(top: 10)
                : const EdgeInsets.only(top: 0),
            physics: const ClampingScrollPhysics(),
            controller: scrollController,
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            children: [
              if (file.hasRegion && beforeController.text.isNotEmpty)
                editorField(context, file, RegionPosition.before),
              editorField(context, file, RegionPosition.inner),
              if (file.hasRegion && afterController.text.isNotEmpty)
                editorField(context, file, RegionPosition.after),
            ],
          ),
        )
      ],
    );
  }

  TextField editorField(
    BuildContext context,
    FileIDE file,
    RegionPosition position,
  ) {
    TextEditingController returnCorrectController(RegionPosition position) {
      switch (position) {
        case RegionPosition.before:
          return beforeController;
        case RegionPosition.inner:
          return inController;
        case RegionPosition.after:
          return afterController;
      }
    }

    return TextField(
      smartQuotesType: SmartQuotesType.disabled,
      smartDashesType: SmartDashesType.disabled,
      controller: returnCorrectController(position),
      decoration: InputDecoration(
        border: InputBorder.none,
        filled: true,
        fillColor: file.hasRegion && position == RegionPosition.inner
            ? file.region.color
            : widget.options.editorBackgroundColor,
        contentPadding: const EdgeInsets.only(
          left: 10,
        ),
        isDense: true,
      ),
      maxLines: null,
      style: TextStyle(
        fontSize: getFontSize(context, fontSize: 18),
        fontFamily: widget.options.fontFamily,
        color: Colors.white.withValues(alpha: 0.87),
      ),
      onChanged: (String event) {
        if (file.hasRegion && position != RegionPosition.after) {
          handleRegionCaching(file, event, position);
        }

        handleTextChange(
          event,
          position,
          file.hasRegion,
        );
      },
      onTap: () {
        handleCurrentFocusedTextfieldController(position);
      },
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(r'[“”]'),
            replacementString: '"'),
        FilteringTextInputFormatter.deny(RegExp(r'[‘’]'),
            replacementString: "'")
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
            itemBuilder: (_, i) {
              TextEditingController lineController = TextEditingController();
              lineController.text = (i + 1).toString();
              return Linebar(
                calculateBarWidth: () {
                  if (i + 1 > 9) {
                    SchedulerBinding.instance.addPostFrameCallback(
                      (timeStamp) {
                        setState(() {
                          _initialWidth = getTextHeight(context) +
                              (8 * (i + 1).toString().length);
                        });
                      },
                    );
                  }
                },
                child: TextField(
                  readOnly: true,
                  enableInteractiveSelection: false,
                  controller: lineController,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: getFontSize(context, fontSize: 18),
                    fontWeight: FontWeight.w500,
                    fontFamily: widget.options.fontFamily,
                    color: widget.options.linebarTextColor,
                  ),
                  maxLines: null,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }
}
