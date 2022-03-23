import 'package:flutter/material.dart';
import 'package:flutter_code_editor/controller/file_controller.dart';
import 'package:flutter_code_editor/editor/file_explorer/file_explorer.dart';
import 'package:flutter_code_editor/models/directory_model.dart';

class FileDirCreationWidget extends StatefulWidget {
  FileDirCreationWidget(
      {Key? key, required this.dir, required this.fileExplorer})
      : super(key: key);
  bool isCreatingFile = false;
  bool isCreatingDirectory = false;

  FileExplorer fileExplorer;

  final textController = TextEditingController();

  DirectoryIDE dir;

  @override
  State<StatefulWidget> createState() => _FileDirCreationWidgetState();
}

class _FileDirCreationWidgetState extends State<FileDirCreationWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        !widget.isCreatingDirectory
            ? Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Create Directory'),
                    tileColor: Colors.lightBlue,
                    onTap: () {
                      setState(() {
                        widget.isCreatingDirectory = true;
                        widget.isCreatingFile = false;
                      });
                    },
                  ),
                ],
              )
            : Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: inputField(context, false)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text('Create'),
                          tileColor: Colors.green,
                          onTap: () {
                            createNewDirOrFile(
                                false, widget.textController.text);

                            setState(() {
                              widget.isCreatingDirectory = false;
                            });
                          },
                        ),
                      )
                    ],
                  ),
                ],
              ),
        !widget.isCreatingFile
            ? ListTile(
                leading: const Icon(Icons.add),
                title: const Text(
                  'Create File',
                ),
                tileColor: Colors.lightBlue,
                onTap: () {
                  setState(() {
                    widget.isCreatingDirectory = false;
                    widget.isCreatingFile = true;
                  });
                },
              )
            : inputField(context, true)
      ],
    );
  }

  void createNewDirOrFile(bool isFile, String name) {
    if (isFile) {
      FileController.createFile(widget.dir.directoryPath, name);
    } else {
      FileController.createNewDir(widget.dir.directoryPath, name);
    }

    widget.fileExplorer.updateTree();
  }

  Widget inputField(BuildContext context, bool isCreatingFile) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: TextField(
        controller: widget.textController,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: 'Enter a ${isCreatingFile ? 'File' : 'Directory'} name',
        ),
        onSubmitted: (name) {
          createNewDirOrFile(isCreatingFile, name);
          setState(() {
            widget.isCreatingDirectory = false;
            widget.isCreatingFile = false;
          });
        },
      ),
    );
  }
}
