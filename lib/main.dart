import 'package:flutter/material.dart';
import 'package:flutter_code_editor/phone_ide.dart';

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
  void initFile() {
    editor.fileTextStream.add(
      FileIDE(
        id: '1',
        ext: 'HTML',
        name: 'index',
        content: '<h1> Hello World! </h1>',
        hasRegion: true,
        region: EditorRegionOptions(start: 1, end: 2),
      ),
    );
  }

  Editor editor = Editor(
    language: 'html',
    options: EditorOptions(
      hasRegion: true,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: editor.fileTextStream.stream,
      builder: (context, snapshot) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Expanded(child: editor),
                ElevatedButton(
                  onPressed: () {
                    initFile();
                  },
                  child: const Text('open file'),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
