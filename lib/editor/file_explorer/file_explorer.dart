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

  void updateTree() {
    controller.sink.add(getInitialTree());
  }

  final _controller = StreamController<Future<List>>.broadcast();
  StreamController<Future<List>> get controller => _controller;

  @override
  State<StatefulWidget> createState() => FileExplorerState();
}

class FileExplorerState extends State<FileExplorer> {
  @override
  void initState() {
    super.initState();
    widget.fc = FileController(fileExplorer: widget);
    widget.updateTree();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Future<List>>(
        stream: widget._controller.stream,
        builder: (context, snapshot) {
          return FutureBuilder(
              future: snapshot.data,
              builder: (BuildContext context, AsyncSnapshot dataSnapshot) {
                if (dataSnapshot.hasData) {
                  List content = dataSnapshot.data;
                  return ListView.builder(
                      itemCount: content.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Column(
                          children: [content[index]],
                        );
                      });
                } else {
                  widget.updateTree();
                }
                return Container();
              });
        });
  }
}
