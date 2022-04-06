import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/editor/editor.dart';
import 'package:flutter_code_editor/editor/file_explorer/file_explorer.dart';
import 'package:flutter_code_editor/editor/preview/preview.dart';
import 'package:flutter_code_editor/enums/language.dart';
import 'package:flutter_code_editor/models/editor_options.dart';
import 'package:flutter_code_editor/models/file_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: must_be_immutable
class EditorViewController extends StatefulWidget {
  EditorViewController({
    Key? key,
    this.title = '',
    this.recentlyOpenedFiles = const [],
    this.options = const EditorOptions(),
    this.file,
  }) : super(key: key);

  List<FileIDE> recentlyOpenedFiles;
  final String title;
  final FileIDE? file;
  final EditorOptions options;

  // a stream of the javascript that is executed inside the code preview

  StreamController consoleStream = StreamController<dynamic>.broadcast();

  // a stream of the latest text in the editor

  StreamController editorTextStream = StreamController<String>.broadcast();

  @override
  State<StatefulWidget> createState() => EditorViewControllerState();
}

class EditorViewControllerState extends State<EditorViewController> {
  Editor? editor;

  @override
  void initState() {
    super.initState();
    editor = Editor(
      language: Language.html,
      openedFile: widget.file,
      textStream: widget.editorTextStream,
      onChange: () {},
    );

    setRecentlyOpenedFilesInDir();
  }

  List<FileIDE> cachedFileStringToFile(List<String> stringFileList) {
    List<FileIDE> files = [];

    for (var file in stringFileList) {
      var fileToJson = json.decode(file);

      files.add(FileIDE.fromJSON(fileToJson));
    }

    return files;
  }

  Future<void> setRecentlyOpenedFilesInDir() async {
    setState(() {
      widget.recentlyOpenedFiles = [];
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (widget.file == null) return;

    String key = (widget.file?.parentDirectory as String) + '-recently-opened';

    List<String> recentlyOpenedFiles = [];

    List<String>? cache = prefs.getStringList(key);

    recentlyOpenedFiles
        .add(json.encode(FileIDE.fileToMap(widget.file as FileIDE)));

    cache?.forEach((file) {
      if (!recentlyOpenedFiles.contains(file)) {
        recentlyOpenedFiles.add(file);
      }
    });

    prefs.setStringList(key, recentlyOpenedFiles);

    setState(() {
      widget.recentlyOpenedFiles = cachedFileStringToFile(recentlyOpenedFiles);
    });
  }

  Future<void> removeRecentlyOpenedFile(String fileToClose) async {
    setState(() {
      widget.recentlyOpenedFiles = [];
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = (widget.file?.parentDirectory as String) + '-recently-opened';

    if (prefs.getStringList(key) != null) {
      List<String>? fileStrings = prefs.getStringList(key);

      if (fileStrings == null) return;

      for (int i = 0; i < fileStrings.length; i++) {
        var fileObject = json.decode(fileStrings[i]);

        FileIDE file = FileIDE.fromJSON(fileObject);

        if (file.fileName == fileToClose) {
          fileStrings.removeAt(i);

          prefs.setStringList(key, fileStrings);

          setState(() {
            widget.recentlyOpenedFiles = cachedFileStringToFile(fileStrings);
          });

          break;
        }
      }
      pushNewView(widget.recentlyOpenedFiles[0]);
    }
  }

  bool fileIsFocused(String fileName) {
    return fileName == widget.file?.fileName;
  }

  int getActualTabLength() {
    int tabs = 1;
    widget.options.codePreview ? tabs = tabs + 1 : tabs = tabs;

    tabs = widget.options.customViews.length + tabs;

    return tabs;
  }

  void pushNewView(FileIDE tappedFile) {
    if (tappedFile.fileName == widget.file?.fileName) return;

    Navigator.pushReplacement(
        context,
        PageRouteBuilder(
            transitionDuration: Duration.zero,
            pageBuilder: (context, animation1, animation2) =>
                EditorViewController(
                  file: tappedFile,
                  options: widget.options,
                )));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
            backgroundColor: widget.options.scaffoldBackgrounColor,
            drawer: widget.options.useFileExplorer
                ? Drawer(child: FileExplorer())
                : null,
            appBar: AppBar(
              title: Text(widget.file?.parentDirectory ?? ''),
              leading: Builder(
                builder: (BuildContext context) => IconButton(
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    icon: const Icon(Icons.folder)),
              ),
              backgroundColor: widget.options.tabBarColor,
              toolbarHeight: 50,
            ),
            body: editor?.openedFile != null && widget.options.codePreview
                ? DefaultTabController(
                    length: getActualTabLength(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          color: widget.options.tabBarColor,
                          height: 50,
                          child: fileTabBar(),
                        ),
                        Container(
                          height: 35,
                          color: widget.options.tabBarColor,
                          child: TabBar(tabs: <Text>[
                            for (int i = 0;
                                i < widget.options.customViewNames.length;
                                i++)
                              widget.options.customViewNames[i],
                            const Text('editor'),
                            const Text('preview'),
                          ]),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              for (int i = 0;
                                  i < widget.options.customViews.length;
                                  i++)
                                widget.options.customViews[i],
                              editor as Widget,
                              CodePreview(
                                editor: editor as Editor,
                                options: widget.options,
                                consoleStream: widget.consoleStream,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ))
                : const Center(
                    child: Text('open file'),
                  )));
  }

  ListView fileTabBar() {
    if (widget.recentlyOpenedFiles.isEmpty) {
      setRecentlyOpenedFilesInDir();
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      scrollDirection: Axis.horizontal,
      itemCount: widget.recentlyOpenedFiles.length,
      itemBuilder: (context, index) => Container(
        height: 25,
        constraints: const BoxConstraints(
          minWidth: 150,
        ),
        child: Container(
          padding: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
              border: fileIsFocused(widget.recentlyOpenedFiles[index].fileName)
                  ? const Border(
                      right: BorderSide(width: 2, color: Colors.white),
                      top: BorderSide(width: 2, color: Colors.white))
                  : const Border(
                      bottom: BorderSide(width: 2, color: Colors.white))),
          child: TextButton(
            onPressed: () {
              pushNewView(widget.recentlyOpenedFiles[index]);
            },
            style: TextButton.styleFrom(
                backgroundColor:
                    !fileIsFocused(widget.recentlyOpenedFiles[index].fileName)
                        ? widget.options.scaffoldBackgrounColor
                        : widget.options.tabBarColor,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.zero),
                )),
            child: Row(
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 75),
                  child: Text(
                    widget.recentlyOpenedFiles[index].fileName,
                    maxLines: 1,
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                widget.recentlyOpenedFiles.length > 1
                    ? IconButton(
                        onPressed: () {
                          removeRecentlyOpenedFile(
                              widget.recentlyOpenedFiles[index].fileName);
                        },
                        icon: const Icon(
                          Icons.cancel_outlined,
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.only(left: 16))
                    : Container()
              ],
            ),
          ),
        ),
      ),
    );
  }
}
