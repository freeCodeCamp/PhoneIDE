## PhoneIDE

PhoneIDE is a powerful and flexible code editor designed for mobile devices, allowing developers to work on-the-go without sacrificing functionality or usability. With support for multiple coding languages, including Python, JavaScript, Ruby, and more, PhoneIDE is a versatile tool that can be used for a wide range of coding projects. Whether you're writing simple scripts or working on complex applications, PhoneIDE offers a range of features that make coding on a mobile device easier and more productive. With a user-friendly interface and robust set of tools, PhoneIDE is the ideal choice for developers who need a mobile code editor that can keep up with their busy lifestyles.

```Dart
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/editor/editor.dart';
import 'package:flutter_code_editor/models/editor_options.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
  
    Editor editor = Editor(
      language: 'html',
      options: options,
    );

    return MaterialApp(
      home: Row(
        children: [
          Expanded(child: editor),
        ],
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
```
