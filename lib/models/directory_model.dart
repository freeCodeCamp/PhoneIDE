import 'package:flutter/material.dart';
import 'package:flutter_code_editor/models/file_dir_creation_model.dart';

// ignore: must_be_immutable
class DirectoryIDE extends StatefulWidget {
  DirectoryIDE(
      {Key? key,
      required this.directoryName,
      required this.directoryPath,
      required this.directoryContent,
      this.directoryOpen = false,
      this.parentDirectory,
      this.isParentDirectory = true})
      : super(key: key);

  String directoryName;

  final String directoryPath;
  List directoryContent;
  final DirectoryIDE? parentDirectory;

  bool directoryOpen;
  bool isParentDirectory;

  String get getDirectoryName {
    return directoryName;
  }

  set setDirectoryName(String newDirectoryName) {
    directoryName = newDirectoryName;
  }

  String get getDirectoryPath {
    return directoryPath;
  }

  @override
  State<StatefulWidget> createState() => DirectoryIDEState();
}

class DirectoryIDEState extends State<DirectoryIDE> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          border: Border(left: BorderSide(width: 1, color: Colors.grey))),
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            leading: const Icon(Icons.folder),
            title: Text(widget.directoryName),
            trailing: widget.directoryOpen
                ? const Icon(Icons.arrow_drop_down)
                : const Icon(Icons.arrow_right),
            onTap: () {
              setState(() {
                widget.directoryOpen = !widget.directoryOpen;
              });
            },
          ),
          ListView.builder(
              shrinkWrap: true,
              itemCount:
                  widget.directoryOpen ? widget.directoryContent.length : 0,
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: widget.directoryContent[index],
                );
              })
        ],
      ),
    );
  }
}
