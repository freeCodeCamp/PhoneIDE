import 'package:flutter/material.dart';
import 'package:phone_ide/editor/editor_options.dart';

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

  // [id] is the id of the file.

  final String id;

  // [ext] is the extension of the file.

  final String ext;

  // [name] is the name of the file.

  final String name;

  // [content] is the content of the file.

  final String content;

  // [hasRegion] is whether the file has a region.

  final bool hasRegion;

  // [region] is the region of the file.

  final EditorRegionOptions region;
}
