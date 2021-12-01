import 'dart:io';
import 'dart:developer' as dev;
import 'package:path_provider/path_provider.dart';

class FileController {
  static Future<String> initProjectsDirectory() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();

    final Directory _appDocDirFolder = Directory('${appDocDir.path}/projects');

    if (!await _appDocDirFolder.exists()) {
      final Directory _appDocDirNewFolder =
          await _appDocDirFolder.create(recursive: true);
      return _appDocDirNewFolder.path;
    }
    return _appDocDirFolder.path;
  }

  static Future<String> initProject(String projectName) async {
    String projectsDir = await initProjectsDirectory();

    final Directory _projectFolder = Directory('$projectsDir/$projectName');

    if (!await _projectFolder.exists()) {
      final Directory _newProjectFolder =
          await _projectFolder.create(recursive: true);
      dev.log(_projectFolder.path);
      return _newProjectFolder.path;
    }

    return _projectFolder.path;
  }

  static Future<String> createFile(
      String projectName, String fileName, String ext) async {
    String project = await initProject(projectName);

    File file = await File('$project/$fileName.$ext');

    if (!await file.exists()) {
      File file = await File('$project/$fileName.$ext').create(recursive: true);
      return file.path;
    }

    return file.path;
  }

  static Future<String> readFile() async {
    // createFile also provides a path to it.

    String filePath = await createFile('project', 'index', 'html');

    final File file = File(filePath);

    return await file.readAsString();
  }

  static Future<void> writeFile(String code) async {
    String filePath = await createFile('project', 'index', 'html');

    final File file = File(filePath);

    file.writeAsString(code);
  }
}
