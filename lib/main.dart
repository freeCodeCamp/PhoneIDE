import 'package:flutter/material.dart';
import 'package:phone_ide/models/editor_language.dart';
import 'package:phone_ide/phone_ide.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: EditorView(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class EditorView extends StatefulWidget {
  const EditorView({
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => EditorViewState();
}

class EditorViewState extends State<EditorView> {
  Editor editor = Editor(
    defaultLanguage: EditorLanguage.html,
    defaultValue: '<h1> Hello World</h1>',
    path: 'index.html',
    options: EditorOptions(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: editor),
          ],
        ),
      ),
    );
  }
}
