import 'package:flutter/material.dart';

class FileIDE {
  const FileIDE({
    Key? key,
    required this.id,
    required this.ext,
    required this.name,
    required this.content,
    required this.hasRegion,
  });

  final String id;
  final String ext;
  final String name;
  final String content;
  final bool hasRegion;
}
