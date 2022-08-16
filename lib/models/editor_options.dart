import 'package:flutter/material.dart';

class EditorOptions {
  const EditorOptions(
      {this.codePreview = true,
      this.canCloseFiles = true,
      this.useFileExplorer = true,
      this.tabBarLineColor = Colors.white,
      this.showTabBar = true,
      this.showAppBar = true,
      this.customViews = const [],
      this.customViewNames = const [],
      this.importScripts = const [],
      this.bodyScripts = const [],
      this.tabBarColor = const Color.fromRGBO(0x0a, 0x0a, 0x23, 1),
      this.scaffoldBackgrounColor = const Color.fromRGBO(0x1b, 0x1b, 0x32, 1),
      this.minHeight = 2500,
      this.minWidth = 2500,
      this.editorBackgroundColor = const Color.fromRGBO(0x2a, 0x2a, 0x40, 1),
      this.linebarColor = const Color.fromRGBO(0x3b, 0x3b, 0x4f, 1),
      this.linebarTextColor = const Color.fromRGBO(0x88, 0x88, 0x88, 1),
      this.hasEditableRegion = true});

  final bool codePreview;

  final bool canCloseFiles;

  final Color tabBarColor;

  final Color tabBarLineColor;

  final bool showTabBar;

  final Color scaffoldBackgrounColor;

  final bool useFileExplorer;

  final List<Widget> customViews;

  final List<Text> customViewNames;

  final List<String> importScripts;

  final List<String> bodyScripts;

  final double minHeight;

  final double minWidth;

  final Color editorBackgroundColor;

  final Color linebarColor;

  final Color linebarTextColor;

  final bool showAppBar;

  final bool hasEditableRegion;
}
