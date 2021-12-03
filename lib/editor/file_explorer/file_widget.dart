import 'package:flutter/material.dart';

class FileWidget extends StatefulWidget {
  const FileWidget(
      {Key? key,
      this.openDirectory = false,
      required this.directoriesWithFiles})
      : super(key: key);

  // is the current directory open or not

  final bool openDirectory;

  // the directories in the projects folder

  final List directoriesWithFiles;

  @override
  State<StatefulWidget> createState() => FileWidgetState();
}

class FileWidgetState extends State<FileWidget> {
  @override
  Widget build(BuildContext context) {
    List<Widget> fileTree = [];
    List projects = widget.directoriesWithFiles;

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
}
