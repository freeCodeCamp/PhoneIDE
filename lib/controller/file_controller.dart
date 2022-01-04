import 'dart:io';

import 'package:flutter_code_editor/editor/file_explorer/file_explorer.dart';
import 'package:flutter_code_editor/models/directory_model.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as dev;

class FileController {
  FileController({required this.fileExplorer});

  FileExplorer fileExplorer;

  Future<String> initProjectsDirectory() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();

    final Directory _appDocDirFolder = Directory('${appDocDir.path}/projects');

    if (!await _appDocDirFolder.exists()) {
      final Directory _appDocDirNewFolder =
          await _appDocDirFolder.create(recursive: true);
      return _appDocDirNewFolder.path;
    }

    return _appDocDirFolder.path;
  }

  Future<List> listProjects(String path) async {
    final List<FileSystemEntity> projectPaths = Directory(path).listSync();
    List<dynamic> projects = [];

    for (int i = 0; i < projectPaths.length; i++) {
      String path = projectPaths[i].path;

      if (await Directory(path).exists()) {
        projects.add(DirectoryIDE(
            fileExplorer: fileExplorer,
            directoryName: path.split("").last,
            directoryPath: path,
            directoryContent: []));
      } else {
        dev.log(projectPaths[i].path + " is not a directory");
      }
    }

    return projects;
  }
}
