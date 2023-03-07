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
  ScrollController horizontalController = ScrollController();
  ScrollController linebarController = ScrollController();

  TextEditingControllerIDE beforeController = TextEditingControllerIDE();
  TextEditingControllerIDE inController = TextEditingControllerIDE();
  TextEditingController afterController = TextEditingControllerIDE();

  List<String> patternMatches = [];

  @override
  void initState() {
    super.initState();

    String fileContent = widget.openedFile?.fileContent ?? '';

    if (fileContent != '') {
      String beforeEditableRegionText =
          fileContent.split("\n").sublist(0, widget.regionStart!).join("\n");

      String inEditableRegionText = fileContent
          .split("\n")
          .sublist(widget.regionStart!, widget.regionEnd! - 1)
          .join("\n");

      String afterEditableRegionText = fileContent
          .split("\n")
          .sublist(widget.regionEnd! - 1, fileContent.split("\n").length - 1)
          .join("\n");

      beforeController.text = beforeEditableRegionText;
      inController.text = inEditableRegionText;
      afterController.text = afterEditableRegionText;
    }

    TextEditingControllerIDE.language = widget.language;
  }

  @override
  Widget build(BuildContext context) {
    widget.fileTextStream.stream.listen((event) {
      // textController.text = event.content;
      TextEditingControllerIDE.language = event.ext;
      // setCurrentLineState(event.content);
    });

    return IEdtorView(context);
  }

  // ignore: non_constant_identifier_names
  Widget IEdtorView(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      controller: horizontalController,
      shrinkWrap: true,
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
                  controller: beforeController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    fillColor: widget.options.editorBackgroundColor,
                    filled: true,
                  ),
                  enabled: false,
                  maxLines: null,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              SizedBox(
                width: widget.options.minHeight,
                child: TextField(
                  controller: inController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    fillColor: widget.options.tabBarColor,
                    filled: true,
                  ),
                  maxLines: null,
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
                  ),
                  enabled: false,
                  maxLines: null,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

//   linecountBar() {
//     return Column(
//       children: [
//         Flexible(
//           child: ListView.builder(
//             padding: EdgeInsets.zero,
//             shrinkWrap: true,
//             controller: linebarController,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: _currNumLines == 0 ? 1 : _currNumLines,
//             itemBuilder: (_, i) => Linebar(
//               calculateBarWidth: () {
//                 if (i + 1 > 9) {
//                   SchedulerBinding.instance.addPostFrameCallback(
//                     (timeStamp) {
//                       setState(() {
//                         _initialWidth = returnTextHeight() + 2;
//                       });
//                     },
//                   );
//                 }
//               },
//               child: Text(
//                 i == 0 ? (1).toString() : (i + 1).toString(),
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w500,
//                   color: widget.options.linebarTextColor,
//                 ),
//               ),
//             ),
//           ),
//         )
//       ],
//     );
//   }
}
