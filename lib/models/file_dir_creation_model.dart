import 'package:flutter/material.dart';
import 'package:flutter_code_editor/controller/file_controller.dart';
import 'package:flutter_code_editor/models/directory_model.dart';

class FileDirCreationWidget extends StatefulWidget {
  FileDirCreationWidget({
    Key? key,
    required this.dir,
  }) : super(key: key);
  bool isCreatingFile = false;
  bool isCreatingDirectory = false;

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
            ? ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Create Directory'),
                tileColor: Colors.lightBlue,
                onTap: () {
                  setState(() {
                    widget.isCreatingDirectory = true;
                    widget.isCreatingFile = false;
                  });
                },
              )
            : inputField(context, false),
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

  Widget inputField(BuildContext context, bool isCreatingFile) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: TextField(
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: 'Enter a ${isCreatingFile ? 'File' : 'Directory'} name',
        ),
        onSubmitted: (name) {
          if (isCreatingFile) {
            FileController.createFile(widget.dir.directoryPath, name);
          } else {
            FileController.createNewDir(widget.dir.directoryPath, name);
          }

          setState(() {
            widget.isCreatingDirectory = false;
            widget.isCreatingFile = false;
          });
        },
      ),
    );
  }
}
