import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/controller/file_controller.dart';

// ignore: must_be_immutable
class FileExplorer extends StatefulWidget {
  FileExplorer({Key? key, this.parentDirectory = "/"}) : super(key: key);

  late FileController fc;

  String parentDirectory;

  Future<List>? _explorerTree;

  Future<List> getInitialTree() async {
    return fc.listProjects(await fc.initProjectsDirectory());
  }

  @override
  State<StatefulWidget> createState() => FileExplorerState();
}

class FileExplorerState extends State<FileExplorer> {
  @override
  void initState() {
    super.initState();
    widget.fc = FileController(fileExplorer: widget);
    widget._explorerTree = widget.getInitialTree();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: widget._explorerTree,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            List content = snapshot.data;
            return ListView.builder(
                itemCount: content.length,
                itemBuilder: (BuildContext context, int index) {
                  return Column(
                    children: [content[index]],
                  );
                });
          }
          return const CircularProgressIndicator();
        });
  }
}
