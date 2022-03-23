import 'dart:async';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/controller/file_controller.dart';
import 'dart:developer' as dev;

// ignore: must_be_immutable
class FileExplorer extends StatefulWidget {
  FileExplorer({Key? key, this.parentDirectory = "/"}) : super(key: key);

  late FileController fc;

  String parentDirectory;

  Future<List>? explorerTree;

  Future<List> getInitialTree() async {
    return fc.listProjects(await fc.initProjectsDirectory());
  }

  final _controller = StreamController<bool>.broadcast();
  StreamController<bool> get controller => _controller;

  @override
  State<StatefulWidget> createState() => FileExplorerState();
}

class FileExplorerState extends State<FileExplorer> {
  @override
  void initState() {
    super.initState();
    widget.controller.sink.add(false);
    widget.controller.stream.listen((event) {
      if (event) {
        setState(() {
          widget.explorerTree = widget.getInitialTree();
        });
      }
    });
    widget.fc = FileController(fileExplorer: widget);
    widget.explorerTree = widget.getInitialTree();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
        stream: widget._controller.stream,
        builder: (context, snapshot) {
          dev.log(snapshot.data.toString());
          return FutureBuilder(
              future: widget.explorerTree,
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
                return Container();
              });
        });
  }
}
