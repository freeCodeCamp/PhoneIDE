import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/editor/file_explorer/file_explorer.dart';

// ignore: must_be_immutable
class DirectoryIDE extends StatefulWidget {
  DirectoryIDE(
      {Key? key,
      required this.fileExplorer,
      required this.directoryName,
      required this.directoryPath,
      required this.directoryContent,
      this.directoryOpen = false,
      this.isParentDirectory = true})
      : super(key: key);

  String directoryName;

  final String directoryPath;
  final List directoryContent;
  final FileExplorer fileExplorer;

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
    return ListView(
      shrinkWrap: true,
      children: [
        ListTile(
          leading: const Icon(Icons.folder),
          title: Text(widget.directoryName),
          trailing: widget.directoryOpen
              ? const Icon(Icons.arrow_drop_up)
              : const Icon(Icons.arrow_drop_down),
          onTap: () {
            setState(() {
              widget.directoryOpen = !widget.directoryOpen;
            });

            widget.fileExplorer.setParentDirectory = widget.directoryName;
            widget.fileExplorer.setExplorerTree = widget.directoryPath;
          },
        ),
        ListView.builder(
            shrinkWrap: true,
            itemCount:
                widget.directoryOpen ? widget.directoryContent.length : 0,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.only(left: 25),
                child: widget.directoryContent[index],
              );
            })
      ],
    );
  }
}
