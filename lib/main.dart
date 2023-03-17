import 'package:flutter/material.dart';
import 'package:flutter_code_editor/phone_ide.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    EditorOptions options = EditorOptions(
      hasRegion: true,
      region: EditorRegionOptions(start: 3, end: 5),
    );

    Editor editor = Editor(
      language: 'html',
      options: options,
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
