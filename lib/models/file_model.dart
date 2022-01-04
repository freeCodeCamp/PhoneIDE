import 'package:flutter/cupertino.dart';

class FileIDE extends StatefulWidget {
  FileIDE(
      {Key? key,
      required this.fileName,
      required this.filePath,
      required this.fileContent})
      : super(key: key);

  String fileName;
  String filePath;
  String fileContent;

  @override
  State<StatefulWidget> createState() => FileIDEState();
}

class FileIDEState extends State<FileIDE> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
