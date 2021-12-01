import 'package:flutter/material.dart';
import 'package:flutter_code_editor/controller/editor_view_controller.dart';
import 'package:flutter_code_editor/editor/editor.dart';
import 'package:flutter_code_editor/editor/preview/preview.dart';
import 'package:flutter_code_editor/enums/language.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Preview(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Preview extends StatefulWidget {
  const Preview({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => PreviewState();
}

class PreviewState extends State<Preview> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: EditorViewController(
        editor: Editor(
          language: Language.html,
        ),
        codePreview: CodePreview(),
      ),
    );
  }
}
