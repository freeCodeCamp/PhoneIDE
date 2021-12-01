import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/controller/file_controller.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CodePreview extends StatefulWidget {
  const CodePreview({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => CodePreviewState();
}

class CodePreviewState extends State<CodePreview> {
  late WebViewController _controller;

  Future<void> _loadCodeFromAssets() async {
    String fileText = await FileController.readFile();

    _controller.loadUrl(Uri.dataFromString(fileText,
            mimeType: 'text/html', encoding: Encoding.getByName('utf-8'))
        .toString());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.redAccent[700],
      child: WebView(
        javascriptMode: JavascriptMode.unrestricted,
        initialUrl: 'about:blank',
        onWebViewCreated: (WebViewController controller) {
          _controller = controller;
          _loadCodeFromAssets();
        },
      ),
    );
  }
}
