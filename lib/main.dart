import 'package:flutter/material.dart';
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
    language: 'html',
    options: EditorOptions(
      hasRegion: true,
    ),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      editor.fileTextStream.add(
        FileIDE(
          id: '1',
          ext: 'HTML',
          name: 'index',
          content: '''
          <div>
            <h1> Hello World! </h1>
          </div>
        ''',
          hasRegion: true,
          region: EditorRegionOptions(start: 1, end: 3),
        ),
      );
    });
  }

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
                    editor.fileTextStream.add(FileIDE(
                      id: '2',
                      ext: 'HTML',
                      name: 'index',
                      content: '''
                        <div>
                          <h1> Hello World from file two! </h1>
                        </div>
                      ''',
                      hasRegion: true,
                      region: EditorRegionOptions(start: 1, end: 3),
                    ));
                  },
                  child: const Text('open another file'),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
