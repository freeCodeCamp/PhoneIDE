import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/controller/file_controller.dart';
import 'package:flutter_code_editor/editor/file_explorer/file_widget.dart';

class FileExplorer extends StatefulWidget {
  const FileExplorer({Key? key}) : super(key: key);
  @override
  State<StatefulWidget> createState() => FileExplorerState();
}

class FileExplorerState extends State<FileExplorer> {
  @override
  void initState() {
    super.initState();
    FileController.listProjectWithFiles();
  }

  List<Widget> fileTree = <Widget>[];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          FutureBuilder<Map<String, dynamic>>(
              future: FileController.listProjectWithFiles(),
              builder: (BuildContext context, snapshot) {
                if (snapshot.hasData) {
                  fileTree = [];
                  Map<String, dynamic> projects = snapshot.data ?? {};

                  for (int i = 0; i < projects.keys.length; i++) {
                    var directoryKeys = projects.keys.toList()[i];
                    var fileKeys = projects[directoryKeys].keys.toList();

                    fileTree.add(FileWidget(
                        directoryName: directoryKeys, files: fileKeys ?? []));
                  }
                  return ListView(
                    shrinkWrap: true,
                    children: fileTree,
                  );
                }
                return Container();
              })
        ],
      ),
    );
  }
}
