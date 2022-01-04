import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/controller/file_controller.dart';
import 'package:flutter_code_editor/models/directory_model.dart';

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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: DirectoryIDE(
                directoryName: "Hello",
                directoryPath: "/",
                directoryContent: const []),
          ),
        ],
      ),
    );
  }
}
