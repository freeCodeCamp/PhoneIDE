import 'package:flutter/material.dart';
import 'package:flutter_code_editor/controller/editor_view_controller.dart';
import 'package:flutter_code_editor/controller/file_controller.dart';
import 'package:flutter_code_editor/editor/file_explorer/file_explorer.dart';

class FileIDE extends StatefulWidget {
  const FileIDE(
      {Key? key,
      required this.fileName,
      required this.filePath,
      required this.fileContent,
      required this.parentDirectory,
      required this.fileExplorer})
      : super(key: key);

  final String fileName;
  final String filePath;
  final String fileContent;
  final String parentDirectory;

  final FileExplorer? fileExplorer;

  @override
  State<StatefulWidget> createState() => FileIDEState();

  static Map<String, dynamic> fileToMap(FileIDE file) {
    Map<String, dynamic> fileMap = {
      "fileName": file.fileName,
      "fileContent": file.fileContent,
      "filePath": file.filePath,
      "parentDirectory": file.parentDirectory
    };

    return fileMap;
  }

  factory FileIDE.fromJSON(Map<String, dynamic> data) {
    return FileIDE(
      fileExplorer: null,
      fileContent: data["fileContent"],
      fileName: data["fileName"],
      filePath: data["filePath"],
      parentDirectory: data["parentDirectory"],
    );
  }
}

class FileIDEState extends State<FileIDE> {
  bool isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: const BoxDecoration(
            border: Border(left: BorderSide(width: 1, color: Colors.grey))),
        child: !isDeleting
            ? ListTile(
                leading: const Icon(Icons.insert_drive_file),
                dense: true,
                title: Text(widget.fileName),
                onLongPress: () {
                  setState(() {
                    isDeleting = true;
                  });
                },
                onTap: () {
                  Navigator.pop(context);

                  Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                          transitionDuration: Duration.zero,
                          pageBuilder: (context, animation1, animation2) =>
                              EditorViewController(
                                file: widget,
                                title: widget.fileName,
                              )));
                })
            : Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text('Delete'),
                          tileColor: Colors.red,
                          onTap: () {
                            FileController.deleteFile(widget.filePath);
                            widget.fileExplorer?.updateTree();
                            setState(() {
                              isDeleting = false;
                            });
                          },
                        ),
                      )
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text('Cancel'),
                          tileColor: Colors.green,
                          onTap: () {
                            setState(() {
                              isDeleting = false;
                            });
                          },
                        ),
                      )
                    ],
                  )
                ],
              ));
  }
}
