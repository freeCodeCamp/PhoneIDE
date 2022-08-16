// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_code_editor/controller/editor_view_controller.dart';
import 'package:flutter_code_editor/controller/language_controller/syntax/index.dart';
import 'package:flutter_code_editor/editor/editor.dart';
import 'package:flutter_code_editor/models/editor_options.dart';
import 'package:flutter_code_editor/models/file_model.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Editor editor = Editor(
      language: Syntax.HTML,
      regionStart: 3,
      regionEnd: 6,
      openedFile: FileIDE(
        fileContent: '''<!DOCTYPE html>
<html>
<body>

<h1>This is heading 1</h1>
<h2>This is heading 2</h2>
<h3>This is heading 3</h3>
<h4>This is heading 4</h4>
<h5>This is heading 5</h5>
<h6>This is heading 6</h6>

</body>
</html> ''',
        fileExplorer: null,
        fileName: '',
        filePath: '',
        parentDirectory: '',
      ),
    );

    EditorViewController controller = EditorViewController(
        options: const EditorOptions(
          canCloseFiles: false,
          showAppBar: false,
          showTabBar: false,
        ),
        editor: editor);

    return MaterialApp(
      home: Row(
        children: [
          Expanded(child: controller),
        ],
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
