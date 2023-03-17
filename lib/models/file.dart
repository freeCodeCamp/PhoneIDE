import 'package:flutter/material.dart';
import 'package:flutter_code_editor/editor/editor_options.dart';

class FileIDE {
  const FileIDE({
    Key? key,
    required this.id,
    required this.ext,
    required this.name,
    required this.content,
    required this.hasRegion,
    required this.region,
  });

  final String id;
  final String ext;
  final String name;
  final String content;
  final bool hasRegion;
  final EditorRegionOptions region;
}
