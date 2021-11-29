import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_code_editor/enums/language.dart';
import 'package:rich_text_controller/rich_text_controller.dart';

class Editor extends StatefulWidget {
  const Editor(
      {Key? key,
      this.minHeight = 500,
      this.minWidth = 500,
      this.color = const Color.fromRGBO(0x2a, 0x2a, 0x40, 1),
      this.linebarColor = const Color.fromRGBO(0x3b, 0x3b, 0x4f, 1),
      this.linebarTextColor = Colors.white,
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

  @override
  State<StatefulWidget> createState() => EditorState();
}

class EditorState extends State<Editor> {
  InputDecoration decoration = const InputDecoration(
      contentPadding: EdgeInsets.only(top: 20.0, left: 10, right: 10),
      border: InputBorder.none);

  RichTextController? controller;

  ScrollController linebarController = ScrollController();
  ScrollController editor = ScrollController();

  @override
  void initState() {
    super.initState();

    // when user scrolls the editor keep the line numbers aligned with the editor

    editor.addListener(() {
      linebarController.jumpTo(editor.offset);
    });

    controller = RichTextController(
        onMatch: (List<String> matches) {
          print('object');
        },
        patternMatchMap: <RegExp, TextStyle>{
          RegExp('<\/?([a-z]{1,10})([0-9]{0,2})\>?'):
              const TextStyle(color: Colors.yellow),
          RegExp('<'): const TextStyle(color: Colors.yellow),
          RegExp('>'): const TextStyle(color: Colors.yellow),
          RegExp('"([a-zA-Z0-9\-\.\=\,\:\/]*"*)'):
              TextStyle(color: Colors.orange[300]),
          RegExp('([A-Za-z\-]*)\='): TextStyle(color: Colors.green[300])
        });
  }

  int numLines = 1;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            color: widget.linebarColor,
            constraints: const BoxConstraints(minWidth: 15, maxWidth: 50),
            child: Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: linecountBar(),
            )),
        Container(
          color: const Color.fromRGBO(0x1b, 0x1b, 0x32, 1),
          width: 5,
          height: MediaQuery.of(context).size.height,
        ),
        Expanded(
          child: Container(
            color: const Color.fromRGBO(0x1b, 0x1b, 0x32, 1),
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
            ]),
          ),
        ),
      ],
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
            itemBuilder: (_, i) {
              return Text(
                i.toString(),
                style: const TextStyle(fontSize: 18, color: Colors.white),
              );
            },
          ),
        )
      ],
    );
  }
}
