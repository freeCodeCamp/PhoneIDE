import 'package:flutter/material.dart';
import 'dart:developer' as dev;

class FileWidget extends StatefulWidget {
  FileWidget(
      {Key? key,
      this.directoryOpen = false,
      this.parentDirectory,
      this.childDirectories,
      this.files = const [],
      required this.directoryName})
      : super(key: key);

  bool directoryOpen;

  final List? parentDirectory;

  final List? childDirectories;

  final List files;

  final String directoryName;

  @override
  State<StatefulWidget> createState() => FileWidgetState();
}

class FileWidgetState extends State<FileWidget> {
  @override
  Widget build(BuildContext context) {
    ListTile returnFiles() {
      for (int i = 0; i < widget.files.length; i++) {
        dev.log(widget.files.toString());
        return ListTile(
          leading: const Icon(Icons.file_copy),
          title: Text(widget.files[i]),
        );
      }

      return const ListTile();
    }

    return ListView(
      shrinkWrap: true,
      children: [
        ListTile(
          leading: const Icon(Icons.folder),
          title: Text(widget.directoryName),
          trailing: widget.directoryOpen
              ? const Icon(Icons.arrow_drop_down_sharp)
              : const Icon(Icons.arrow_drop_up_sharp),
          onTap: () {
            setState(() {
              widget.directoryOpen = !widget.directoryOpen;
            });
          },
        ),
        widget.directoryOpen ? returnFiles() : Container()
      ],
    );
  }
}
