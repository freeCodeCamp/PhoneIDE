import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_code_editor/controller/file_controller.dart';
import 'package:flutter_code_editor/controller/language_controller.dart';
import 'package:flutter_code_editor/editor/linebar/linebar_helper.dart';
import 'package:flutter_code_editor/enums/language.dart';
import 'package:flutter_code_editor/model/editor.dart';
import 'package:rich_text_controller/rich_text_controller.dart';

// ignore: must_be_immutable
class Editor extends StatefulWidget with IEditor {
  Editor(
      {Key? key,
      this.minHeight = 500,
      this.minWidth = 500,
      this.color = const Color.fromRGBO(0x2a, 0x2a, 0x40, 1),
      this.linebarColor = const Color.fromRGBO(0x3b, 0x3b, 0x4f, 1),
      this.linebarTextColor = Colors.white,
      required this.onChange,
      required this.textController,
      required this.language})
      : super(key: key);

  // minimum height of the editor

  final double minHeight;

  // minimum width of the editor

  final double minWidth;

  // color of the editor

  final Color color;

  // Color of the linebar

  final Color linebarColor;

  // Color of the text in the linebar

  final Color linebarTextColor;

  // the coding language in the editor

  final Language language;

  // controller of text

  RichTextController? textController;

  Function() onChange;

  @override
  State<StatefulWidget> createState() => EditorState();
}

class EditorState extends State<Editor> {
  InputDecoration decoration = const InputDecoration(
      contentPadding: EdgeInsets.only(top: 20.0, left: 10, right: 10),
      border: InputBorder.none);

  ScrollController scrollController = ScrollController();
  ScrollController linebarController = ScrollController();

  @override
  void initState() {
    super.initState();

    // when user scrolls the editor keep the line numbers aligned with the editor

    scrollController.addListener(() {
      linebarController.jumpTo(scrollController.offset);
    });

    // FileController.listProjects();

    // Future.delayed(Duration.zero, () async {
    //   controller?.text = await FileController.readFile();
    // });

    widget.textController = RichTextController(
        onMatch: (List<String> matches) {
          print('object');
        },
        patternMatchMap:
            LanguageController.provideLanguageMap(widget.language));
  }

  int numLines = 1;
  double initialWidth = 21;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            color: widget.linebarColor,
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
            width: 1000,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              SizedBox(
                height: MediaQuery.of(context).size.height,
                width: 1000,
                child: TextField(
                  controller: controller,
                  decoration: decoration,
                  scrollController: editor,
                  onChanged: (String e) {
                    setState(() {
                      numLines = '\n'.allMatches(e).length + 1;
                    });
                    linebarController
                        .jumpTo(linebarController.position.maxScrollExtent);

                    // FileController.writeFile(controller?.text as String);
                  },
                  expands: true,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: TextStyle(
                    color: widget.linebarTextColor,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
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
