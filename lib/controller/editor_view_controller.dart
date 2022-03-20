import 'package:flutter/material.dart';
import 'package:flutter_code_editor/editor/editor.dart';
import 'package:flutter_code_editor/editor/file_explorer/file_explorer.dart';
import 'package:flutter_code_editor/editor/preview/preview.dart';
import 'package:flutter_code_editor/enums/language.dart';
import 'package:flutter_code_editor/models/file_model.dart';

class EditorViewController extends StatefulWidget {
  EditorViewController(
      {Key? key,
      this.title = '',
      this.codePreview = true,
      this.tabBarColor = const Color.fromRGBO(0x0a, 0x0a, 0x23, 1),
      this.scaffoldBackgrounColor = const Color.fromRGBO(0x3b, 0x3b, 0x4f, 1),
      this.editor,
      this.file,
      this.tabBarLineColor = Colors.white})
      : super(key: key);

  final String title;

  final bool codePreview;

  final Color tabBarColor;

  final Color tabBarLineColor;

  final Color scaffoldBackgrounColor;

  final FileIDE? file;

  Editor? editor;

  @override
  State<StatefulWidget> createState() => EditorViewControllerState();
}

class EditorViewControllerState extends State<EditorViewController> {
  @override
  void initState() {
    super.initState();
    widget.editor = Editor(
      language: Language.html,
      openedFile: widget.file,
      onChange: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
            backgroundColor: widget.scaffoldBackgrounColor,
            drawer: Drawer(child: FileExplorer()),
            appBar: AppBar(
              leading: Builder(
                builder: (BuildContext context) => IconButton(
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    icon: const Icon(Icons.folder)),
              ),
              title: widget.title.isEmpty ? null : Text(widget.title),
              backgroundColor: widget.tabBarColor,
              toolbarHeight: 50,
              bottom: widget.editor?.openedFile != null && widget.codePreview
                  ? const TabBar(tabs: [Text('editor'), Text('preview')])
                  : null,
            ),
            body: widget.editor?.openedFile != null && widget.codePreview
                ? TabBarView(
                    children: [
                      widget.editor as Widget,
                      CodePreview(
                        filePath: widget.editor?.openedFile!.filePath as String,
                      )
                    ],
                  )
                : const Center(
                    child: Text('open file'),
                  )));
  }
}
