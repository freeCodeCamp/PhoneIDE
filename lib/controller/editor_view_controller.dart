import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/editor/editor.dart';
import 'package:flutter_code_editor/editor/file_explorer/file_explorer.dart';
import 'package:flutter_code_editor/editor/preview/preview.dart';

class EditorViewController extends StatefulWidget {
  const EditorViewController(
      {Key? key,
      required this.editor,
      required this.codePreview,
      this.tabBarColor = const Color.fromRGBO(0x0a, 0x0a, 0x23, 1),
      this.tabBarLineColor = Colors.white})
      : super(key: key);

  final Editor editor;

  final CodePreview codePreview;

  final Color tabBarColor;

  final Color tabBarLineColor;

  @override
  State<StatefulWidget> createState() => EditorViewControllerState();
}

class EditorViewControllerState extends State<EditorViewController> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          drawer: const FileExplorer(),
          appBar: AppBar(
            backgroundColor: widget.tabBarColor,
            toolbarHeight: 10,
            bottom: const TabBar(tabs: [Text('editor'), Text('preview')]),
          ),
          body: TabBarView(
            children: [widget.editor, widget.codePreview],
          ),
        ));
  }
}
