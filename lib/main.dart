// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_code_editor/controller/editor_view_controller.dart';
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
    EditorOptions options = EditorOptions(
      hasEditableRegion: true,
    );

    Editor editor = Editor(
      condition: true,
      regionStart: 3,
      regionEnd: 5,
      language: 'html',
      options: options,
      openedFile: FileIDE(
        content: '''<html>
  <body>
    <h1>CatPhotoApp</h1>
    <h2>Cat Photos</h2>
    <!-- TODO: Add link to cat photos -->
    <p>Click here to view more cat photos.</p>
  </body>
</html>''',
        name: '',
        id: 'js9dfhsk',
        ext: 'HTML',
        hasRegion: false,
      ),
    );

    return MaterialApp(
      home: Row(
        children: [
          Expanded(child: editor),
        ],
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
