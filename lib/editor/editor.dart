import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:phone_ide/controller/custom_text_controller.dart';
import 'package:phone_ide/editor/linebar.dart';
import 'package:phone_ide/editor/editor_options.dart';

class Editor extends StatefulWidget {
  Editor({
    Key? key,
    required this.options,
    required this.regionOptions,
    required this.content,
    required this.language,
  }) : super(key: key);

  // the coding language in the editor
  final String language;

  final String content;

  // options of the editor
  final EditorOptions options;

  final EditorRegionOptions regionOptions;

  // A stream where you can listen to the changes made in the editor
  final StreamController<String> onTextChange =
      StreamController<String>.broadcast();

  @override
  State<StatefulWidget> createState() => EditorState();
}

class EditorState extends State<Editor> {
  ScrollController scrollController = ScrollController();
  ScrollController horizontalController = ScrollController();
  ScrollController linebarController = ScrollController();

  late TextEditingControllerIDE beforeController;
  late TextEditingControllerIDE inController;
  late TextEditingControllerIDE afterController;

  int _currNumLines = 1;

  double _initialWidth = 28;

  String currentFileId = '';

  @override
  void initState() {
    super.initState();

    handleFileInit();

    beforeController = TextEditingControllerIDE(
      language: widget.language,
    );
    inController = TextEditingControllerIDE(
      language: widget.language,
    );
    afterController = TextEditingControllerIDE(
      language: widget.language,
    );
  }

  void updateLineCount(String event, String region) async {
    late String lines;

    if (widget.options.hasRegion) {
      switch (region) {
        case 'BEFORE':
          lines = event +
              (event.isNotEmpty ? '\n' : '') +
              inController.text +
              (afterController.text.isNotEmpty ? '\n' : '') +
              afterController.text;
          break;
        case 'IN':
          lines = beforeController.text +
              (beforeController.text.isNotEmpty ? '\n' : '') +
              event +
              (afterController.text.isNotEmpty ? '\n' : '') +
              afterController.text;
          break;
        case 'AFTER':
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

  handleFileInit() async {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      handleRegionFields();

      if (widget.options.hasRegion) {
        int regionStart = widget.regionOptions.start;

        if (widget.content.split('\n').length > 7) {
          Future.delayed(const Duration(seconds: 0), () {
            double offset = widget.content
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
      scrollController.addListener(() {
        linebarController.jumpTo(scrollController.offset);
      });
    });
  }

  handleRegionFields() async {
    if (widget.options.hasRegion) {
      int regionStart = widget.regionOptions.start;
      int regionEnd = widget.regionOptions.end;

      if (widget.content.split('\n').length > 1) {
        String beforeEditableRegionText =
            widget.content.split('\n').sublist(0, regionStart).join('\n');

        String inEditableRegionText = widget.content
            .split('\n')
            .sublist(regionStart, regionEnd - 1)
            .join('\n');

        String afterEditableRegionText = widget.content
            .split('\n')
            .sublist(regionEnd - 1, widget.content.split('\n').length)
            .join('\n');
        beforeController.text = beforeEditableRegionText;
        inController.text = inEditableRegionText;
        afterController.text = afterEditableRegionText;
      }
    } else {
      beforeController.text = '';
      inController.text = widget.content;
      afterController.text = '';
    }

    setState(() {
      _currNumLines = widget.content.split('\n').length;
    });
  }

  handleTextChange(String event, String region) {
    updateLineCount(event, region);

    late String text;

    switch (region) {
      case 'BEFORE':
        text = '$event\n${inController.text}\n${afterController.text}';
        break;
      case 'IN':
        text = '${beforeController.text}\n$event\n${afterController.text}';
        break;
      case 'AFTER':
        text = '${beforeController.text}\n${inController.text}\n$event';
        break;
    }

    widget.onTextChange.sink.add(text);
  }

  @override
  Widget build(BuildContext context) {
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
            child: MediaQuery(
              data: const MediaQueryData(
                gestureSettings: DeviceGestureSettings(touchSlop: 8.0),
              ),
              child: editorView(context),
            ),
          ),
        )
      ],
    );
  }

  Widget editorView(BuildContext context) {
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
              if (widget.options.hasRegion && beforeController.text.isNotEmpty)
                TextField(
                  smartQuotesType: SmartQuotesType.disabled,
                  smartDashesType: SmartDashesType.disabled,
                  controller: beforeController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    fillColor: widget.options.editorBackgroundColor,
                    filled: true,
                    isDense: true,
                    contentPadding: const EdgeInsets.only(
                      left: 10,
                    ),
                  ),
                  maxLines: null,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.87),
                  ),
                  onChanged: (String event) {
                    handleTextChange(event, 'BEFORE');
                  },
                ),
              TextField(
                smartQuotesType: SmartQuotesType.disabled,
                smartDashesType: SmartDashesType.disabled,
                controller: inController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  fillColor: widget.options.hasRegion
                      ? widget.regionOptions.color
                      : widget.options.editorBackgroundColor,
                  filled: true,
                  isDense: true,
                  contentPadding: EdgeInsets.only(
                    left: 10,
                    top: widget.options.hasRegion ? 0 : 10,
                  ),
                ),
                onChanged: (String event) {
                  handleTextChange(event, 'IN');
                },
                maxLines: null,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.87),
                ),
              ),
              if (widget.options.hasRegion && afterController.text.isNotEmpty)
                TextField(
                  smartQuotesType: SmartQuotesType.disabled,
                  smartDashesType: SmartDashesType.disabled,
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
                    handleTextChange(event, 'AFTER');
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
