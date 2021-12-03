import 'dart:io';
import 'dart:developer' as dev;
import 'package:path_provider/path_provider.dart';

class FileController {
  // called when user has no projects directory

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

  // this will create a new project file when requested

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

  // this will create a new file in a certain directory

  static Future<String> createFile(
      String projectName, String fileName, String ext) async {
    String project = await initProject(projectName);

    File file = File('$project/$fileName.$ext');

    if (!await file.exists()) {
      File file = await File('$project/$fileName.$ext').create(recursive: true);
      return file.path;
    }

    return file.path;
  }

  // this will read a file in a certain directory the file name and directory
  // will be provided by the project tree.

  static Future<String> readFile() async {
    // createFile also provides a path to it.

    String filePath = await createFile('project', 'index', 'html');

    final File file = File(filePath);

    return await file.readAsString();
  }

  // this will write new values to a file in a certain directory when requested

  static Future<void> writeFile(String code) async {
    String filePath = await createFile('project', 'index', 'html');

    final File file = File(filePath);

    file.writeAsString(code);
  }

  static Future<List<String>> listProjects() async {
    String path = await initProjectsDirectory();

    final List<FileSystemEntity> projectPaths = Directory(path).listSync();

    List<String> projects = [];

    for (int i = 0; i < projectPaths.length; i++) {
      projects.add(projectPaths[i].path.split("/").last);
    }

    return projects;
  }

  static Future<Map<String, dynamic>> listProjectWithFiles() async {
    String projectFolder = await initProjectsDirectory();

    List<String> projects = await listProjects();

    Map<String, dynamic> fileTree = {};

    for (int i = 0; i < projects.length; i++) {
      List<FileSystemEntity> filesInDir =
          Directory('$projectFolder/${projects[i]}').listSync();

      fileTree[projects[i]] = {};

      for (int j = 0; j < filesInDir.length; j++) {
        var fileName = filesInDir[j].path.split("/").last;
        fileTree[projects[i]][fileName] = fileName;
      }
    }

    return fileTree;
  }
}
