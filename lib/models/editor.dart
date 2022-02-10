import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rich_text_controller/rich_text_controller.dart';

mixin IEditor {
  void returnEditorValue(String text) {}

  /// Takes a text controller and returns the current position of the cursor.

  int getCursorPosition(RichTextController? controller) {
    return controller!.selection.baseOffset;
  }

  Future<List<dynamic>> getCachedTags(String openedFile) async {
    final localDirectory = await getApplicationDocumentsDirectory();

    String location = '${localDirectory.path}/$openedFile.json';

    File file = File(location);

    bool fileExists = await file.exists();

    if (!fileExists) {
      file.createSync();
    } else {
      return await jsonDecode(file.readAsStringSync())['tags'];
    }

    return [];
  }

  Future<bool> writeNewTagCache(List tags, String openedFile) async {
    final localDirectory = await getApplicationDocumentsDirectory();

    String location = '${localDirectory.path}/$openedFile.json';

    File file = File(location);

    bool fileExists = await file.exists();

    List tagCopy = tags.map((e) => '"$e"').toList();

    String json = '{"tags": ${tagCopy.toString()}}';

    if (!fileExists) {
      file.createSync();
      file.writeAsString(json);
    } else {
      file.writeAsString(json);
    }

    return false;
  }

  bool shouldReplicateTag(List<String> tags, String newtag) {
    int closingTags = 0;
    int openTags = 0;

    RegExp matchClosingTag = RegExp("<\/{1}[a-z0-9]*>");

    for (String tag in tags) {
      bool isClosedTag = matchClosingTag.hasMatch(tag);

      if (tag == newtag && !isClosedTag) {
        openTags++;
      }

      if (isClosedTag) {
        closingTags++;
      }
    }

    if (openTags > closingTags) {
      return true;
    }

    return false;
  }

  void replicateTags(List<String> match, RichTextController? controller) async {
    List<String> tags = [];

    RegExp pattern = RegExp('<("[^"\n]*"|\'[^\'\n]*\'|[^\'"\n>])*>');
    Iterable<RegExpMatch> match = pattern.allMatches(controller!.text);

    final int cursorPos = controller.selection.base.offset;

    List cachedTags = await getCachedTags('helloworld');

    for (var tag in match) {
      tags.add(tag.group(0) as String);
    }

    outerloop:
    for (int i = 0; i < tags.length; i++) {
      if (tags.length == cachedTags.length) break;

      if (cachedTags.isEmpty) {
        if (shouldReplicateTag(tags, tags[i])) {
          controller.value = controller.value.copyWith(
              text: controller.text.replaceRange(max(cursorPos, 0),
                  max(cursorPos, 0), '</${tags[i].split("<")[1]}'),
              selection: TextSelection.fromPosition(
                  TextPosition(offset: max(cursorPos, 0))));
        }
      }

      for (int j = 0; j < cachedTags.length; j++) {
        if (cachedTags[j] != tags[i]) {
          if (shouldReplicateTag(tags, tags[i])) {
            controller.value = controller.value.copyWith(
                text: controller.text.replaceRange(max(cursorPos, 0),
                    max(cursorPos, 0), '</${tags[i].split("<")[1]}'),
                selection: TextSelection.fromPosition(
                    TextPosition(offset: max(cursorPos, 0))));
          }
          break;
        }
      }
    }

    writeNewTagCache(tags, 'helloworld');
  }
}
