# Editor Widget

A versatile text editor widget for Flutter applications, supporting syntax highlighting, editable regions, and customizable appearance.

## Installation

Include the necessary imports in your Dart file:

```dart
import 'package:phone_ide/editor/editor.dart';
import 'package:phone_ide/editor/editor_options.dart';
```

## Usage

Here's a basic example of how to integrate the `Editor` widget into your Flutter app:

```dart
Editor(
  options: EditorOptions(
    backgroundColor: Colors.black,
    linebarColor: Colors.grey.shade800,
    linebarTextColor: Colors.white,
    showLinebar: true,
    takeFullHeight: true,
    fontFamily: 'Courier',
    regionOptions: EditorRegionOptions(
      start: 3,
      end: 10,
      color: Colors.grey.shade900,
    ),
  ),
  defaultLanguage: 'dart',
  defaultValue: '''
void main() {
  print('Hello, World!');
}
''',
  path: 'main.dart',
);
```

### Parameters

- **options** (`EditorOptions`): Customize appearance and behavior of the editor.
- **defaultLanguage** (`String`): Initial programming language setting (for syntax highlighting).
- **defaultValue** (`String`): Initial content displayed in the editor.
- **path** (`String`): Identifier for the file, typically the filename.

## Customizing the Editor

You can adjust the appearance by tweaking the `EditorOptions`:

```dart
EditorOptions(
  backgroundColor: Colors.blueGrey,
  linebarColor: Colors.black54,
  fontFamily: 'Monaco',
  isEditable: false,
);
```

## Listening to Text Changes

You can listen for changes in the editor content through the provided streams:

```dart
final editor = Editor(
  options: EditorOptions(),
  defaultLanguage: 'dart',
  defaultValue: '',
  path: 'script.dart',
);

editor.onTextChange.stream.listen((content) {
  print('Editor content changed: \$content');
});

editor.editableRegion.stream.listen((editableContent) {
  print('Editable region content: \$editableContent');
});
```

## License

This project is licensed under the MIT License.
