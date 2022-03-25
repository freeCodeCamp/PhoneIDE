import 'package:flutter/material.dart';

class EditorOptions {
  const EditorOptions({
    this.codePreview = true,
    this.useFileExplorer = true,
    this.tabBarLineColor = Colors.white,
    this.tabBarColor = const Color.fromRGBO(0x0a, 0x0a, 0x23, 1),
    this.scaffoldBackgrounColor = const Color.fromRGBO(0x3b, 0x3b, 0x4f, 1),
  });

  final bool codePreview;

  final Color tabBarColor;

  final Color tabBarLineColor;

  final Color scaffoldBackgrounColor;

  final bool useFileExplorer;
}
