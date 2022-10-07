import 'package:flutter/material.dart';

class EditorOptions {
  EditorOptions(
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
      this.hasEditableRegion = false});

  bool codePreview;

  bool canCloseFiles;

  Color tabBarColor;

  Color tabBarLineColor;

  bool showTabBar;

  Color scaffoldBackgrounColor;

  bool useFileExplorer;

  List<Widget> customViews;

  List<Text> customViewNames;

  List<String> importScripts;

  List<String> bodyScripts;

  double minHeight;

  double minWidth;

  Color editorBackgroundColor;

  Color linebarColor;

  Color linebarTextColor;

  bool showAppBar;

  bool hasEditableRegion;
}
