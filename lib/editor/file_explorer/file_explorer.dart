import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/controller/file_controller.dart';
import 'dart:developer' as dev;

// ignore: must_be_immutable
class FileExplorer extends StatefulWidget {
  FileExplorer({Key? key, this.parentDirectory = "/"}) : super(key: key);

  late FileController fc;

  String parentDirectory;

  List historyCache = [];

  late Future<List> _explorerTree;

  set setParentDirectory(String newParentDirectory) {
    parentDirectory = newParentDirectory;
  }

  @override
  State<StatefulWidget> createState() => FileExplorerState();
}

class FileExplorerState extends State<FileExplorer> {
  @override
  void initState() {
    super.initState();
    widget.fc = FileController(fileExplorer: widget);
    Future.delayed(
        Duration.zero,
        () async => {
              widget._explorerTree = widget.fc
                  .listProjects(await widget.fc.initProjectsDirectory())
            });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        builder: (BuildContext context, AsyncSnapshot snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const CircularProgressIndicator();
      }

      if (snapshot.connectionState == ConnectionState.done) {
        if (snapshot.hasError) {
          return const Text('an error occured while fetching your projects');
        }

        if (snapshot.hasData) {
          return const Text('snapshot has data');
        }
      }

      return Text('State: ${snapshot.connectionState}');
    });
  }
}
