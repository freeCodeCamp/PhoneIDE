import 'package:flutter/material.dart';
import 'package:flutter_code_editor/controller/editor_view_controller.dart';
import 'package:flutter_code_editor/models/editor_options.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    EditorViewController controller = EditorViewController(
      options: const EditorOptions(canCloseFiles: false),
    );

    return MaterialApp(
      home: controller,
      debugShowCheckedModeBanner: false,
    );
  }
}
