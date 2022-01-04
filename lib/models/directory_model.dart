import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class DirectoryIDE extends StatefulWidget {
  DirectoryIDE(
      {Key? key,
      required this.directoryName,
      required this.directoryPath,
      required this.directoryContent,
      this.directoryOpen = false,
      this.isParentDirectory = true})
      : super(key: key);

  final String directoryName;
  final String directoryPath;
  final List directoryContent;
  bool directoryOpen;
  bool isParentDirectory;

  String get getDirectoryName {
    return directoryName;
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
          },
        )
      ],
    );
  }
}
