import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CodePreview extends StatefulWidget {
  const CodePreview({
    Key? key,
    this.initialUrl = 'about:blank',
    this.allowJavaScript = true,
    this.userAgent = 'random',
  });

  // the initialUrl the preview should go to before the actual view is loaded

  final String initialUrl;

  // should the preview allow javascript

  final bool allowJavaScript;

  // which browser agent should be used

  final String userAgent;

  @override
  State<StatefulWidget> createState() => CodePreviewState();
}

class CodePreviewState extends State<CodePreview> {
  late WebViewController _controller;

  Future<void> _loadCodeFromAssets() async {
    // String fileText = await FileController.readFile();

    // _controller.loadUrl(Uri.dataFromString(fileText,
    //         mimeType: 'text/html', encoding: Encoding.getByName('utf-8'))
    //     .toString());
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
