import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/models/file_model.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:html/parser.dart' show parse, parseFragment;
import 'package:html/dom.dart';
import 'dart:developer' as dev;

class CodePreview extends StatefulWidget {
  const CodePreview({
    Key? key,
    required this.file,
    this.initialUrl = 'about:blank',
    this.allowJavaScript = true,
    this.userAgent = 'random',
    this.customScript = const [],
  }) : super(key: key);

  // the initialUrl the preview should go to before the actual view is loaded

  final String initialUrl;

  // should the preview allow javascript

  final bool allowJavaScript;

  // which browser agent should be used

  final String userAgent;

  // used to temporarly create file

  final FileIDE file;

  // custom javaScript to add in browser view

  final List<String> customScript;

  @override
  State<StatefulWidget> createState() => CodePreviewState();
}

class CodePreviewState extends State<CodePreview> {
  late WebViewController _controller;

  Future<void> _loadCodeFromAssets() async {
    String fileText = widget.file.fileContent;

    Document document = parse(fileText);

    String viewPort =
        '<meta content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" name="viewport"></meta>';

    Document viewPortParsed = parse(viewPort);
    Node meta = viewPortParsed.getElementsByTagName('META')[0];

    document.getElementsByTagName('HEAD')[0].append(meta);

    for (String import in widget.customScript) {
      Document importDocument = parse(import);

      Node script = importDocument.getElementsByTagName('SCRIPT')[0];
      document.getElementsByTagName('HEAD')[0].append(script);
    }

    _controller.loadUrl(Uri.dataFromString(document.outerHtml,
            mimeType: 'text/html', encoding: Encoding.getByName('utf-8'))
        .toString());
  }

  @override
  Widget build(BuildContext context) {
    return WebView(
      javascriptMode: widget.allowJavaScript
          ? JavascriptMode.unrestricted
          : JavascriptMode.disabled,
      initialUrl: widget.initialUrl,
      userAgent: widget.userAgent,
      onWebViewCreated: (WebViewController controller) {
        _controller = controller;
        _loadCodeFromAssets();
      },
    );
  }
}
