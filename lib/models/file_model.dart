import 'package:flutter/material.dart';

class FileIDE extends StatefulWidget {
  const FileIDE(
      {Key? key,
      required this.fileName,
      required this.filePath,
      required this.fileContent})
      : super(key: key);

  final String fileName;
  final String filePath;
  final String fileContent;

  @override
  State<StatefulWidget> createState() => FileIDEState();
}

class FileIDEState extends State<FileIDE> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          border: Border(left: BorderSide(width: 1, color: Colors.grey))),
      child: ListTile(
        leading: const Icon(Icons.insert_drive_file),
        dense: true,
        title: Text(widget.fileName),
        onTap: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}
