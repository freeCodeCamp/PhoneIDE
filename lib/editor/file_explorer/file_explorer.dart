import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/controller/file_controller.dart';

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

  @override
  Widget build(BuildContext context) {
    final fileTree = <Widget>[];

    return Drawer(
      child: Column(
        children: [
          FutureBuilder<List<List>>(
              future: FileController.listProjectWithFiles(),
              builder: (BuildContext context, snapshot) {
                if (snapshot.hasData) {
                  List projects = snapshot.data ?? [];

                  for (int i = 0; i < projects.length; i++) {
                    fileTree.add(ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text(projects[i][0]),
                    ));
                    for (int j = 1; j < projects[i].length; j++) {
                      fileTree.add(Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: ListTile(
                          title: Text(projects[i][j]),
                          leading: const Icon(Icons.file_copy_rounded),
                        ),
                      ));
                    }
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
