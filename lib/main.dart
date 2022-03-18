import 'package:flutter/material.dart';
import 'package:flutter_code_editor/controller/editor_view_controller.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: EditorViewController(
        codePreview: true,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
