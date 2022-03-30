import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/editor/editor.dart';
import 'package:flutter_code_editor/models/editor_options.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

class CodePreview extends StatefulWidget {
  const CodePreview({
    Key? key,
    required this.editor,
    this.options = const EditorOptions(),
    this.initialUrl = 'about:blank',
    this.allowJavaScript = true,
    this.userAgent = 'random',
  }) : super(key: key);

  // the initialUrl the preview should go to before the actual view is loaded

  final String initialUrl;

  // should the preview allow javascript

  final bool allowJavaScript;

  // which browser agent should be used

  final String userAgent;

  // an instance of the editor that is calling the preview widget

  final Editor editor;

  // an instance of the editor options

  final EditorOptions options;

  @override
  State<StatefulWidget> createState() => CodePreviewState();
}

class CodePreviewState extends State<CodePreview> {
  late WebViewController _controller;

  Future<void> _loadCodeFromAssets() async {
    String fileText = widget.editor.openedFile!.fileContent;

    Document document = parse(fileText);

    String viewPort =
        '<meta content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" name="viewport"></meta>';

    Document viewPortParsed = parse(viewPort);
    Node meta = viewPortParsed.getElementsByTagName('META')[0];

    document.getElementsByTagName('HEAD')[0].append(meta);

    for (String import in widget.options.customScripts) {
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
      javascriptChannels: {
        JavascriptChannel(
            name: 'first',
            onMessageReceived: (JavascriptMessage msg) {
              widget.editor.consoleStream.sink.add(msg.message);
            })
      },
      initialUrl: widget.initialUrl,
      userAgent: widget.userAgent,
      onWebViewCreated: (WebViewController controller) {
        _controller = controller;
        _loadCodeFromAssets();
      },
    );
  }
}
