import 'package:flutter/material.dart';
import 'package:flutter_code_editor/controller/file_controller.dart';
import 'package:flutter_code_editor/main.dart';
import 'package:flutter_code_editor/models/directory_model.dart';
import 'package:flutter_code_editor/models/file_dir_creation_model.dart';

class FileIDE extends StatefulWidget {
  FileIDE(
      {Key? key,
      required this.fileName,
      required this.filePath,
      required this.fileContent,
      this.parentDir})
      : super(key: key);

  final String fileName;
  final String filePath;
  final String fileContent;

  final DirectoryIDE? parentDir;

  bool isDeleting = false;

  @override
  State<StatefulWidget> createState() => FileIDEState();
}

class FileIDEState extends State<FileIDE> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          border: Border(left: BorderSide(width: 1, color: Colors.grey))),
      child: !widget.isDeleting
          ? ListTile(
              leading: const Icon(Icons.insert_drive_file),
              dense: true,
              title: Text(widget.fileName),
              onLongPress: () {
                setState(() {
                  widget.isDeleting = true;
                });
              },
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: ((BuildContext context) => EditorView(
                              file: widget,
                            ))));
              },
            )
          : FileDirCreationWidget(dirPath: widget.filePath),
    );
  }
}
