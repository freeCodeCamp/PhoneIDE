import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rich_text_controller/rich_text_controller.dart';
import 'dart:developer' as dev;

mixin IEditor {
  void returnEditorValue(String text) {}

  /// Takes a text controller and returns the current position of the cursor.

  int getCursorPosition(RichTextController? controller) {
    return controller!.selection.baseOffset;
  }

  Future<List<dynamic>> getCachedTags(String openedFile) async {
    final localDirectory = await getApplicationDocumentsDirectory();

    String location = '${localDirectory.path}/$openedFile.txt';

    File file = File(location);

    bool fileExists = await file.exists();

    if (!fileExists) {
      file.createSync();
    } else {
      return await jsonDecode(await file.readAsString());
    }

    return [];
  }

  Future<bool> writeNewTagCache(List tags, String openedFile) async {
    final localDirectory = await getApplicationDocumentsDirectory();

    String location = '${localDirectory.path}/$openedFile.txt';

    File file = File(location);

    bool fileExists = await file.exists();

    List tagCopy = tags.map((e) => '"$e"').toList();

    if (!fileExists) {
      file.createSync();
      file.writeAsString(tagCopy.toString());
    } else {
      file.writeAsString(tagCopy.toString());
    }

    return false;
  }

  bool shouldReplicateTag(List<String> tags, String tag) {
    int matchedOpenTags = 0;
    int matchedClosedTags = 0;

    for (var tagInTags in tags) {
      if (tagInTags.trim().length < 2) continue;

      List toClosedTag = tag.split("<");
      String closedTag;

      if (!tag.contains('/')) {
        closedTag = '</' + toClosedTag[1];
      } else {
        closedTag = tag;
      }

      if (tagInTags == closedTag && tagInTags.contains('/')) {
        matchedClosedTags++;
      }

      if (tagInTags == tag && !tagInTags.contains('/')) {
        matchedOpenTags++;
      }
    }

    if (matchedOpenTags > matchedClosedTags) {
      dev.log(matchedOpenTags.toString() + '' + matchedClosedTags.toString());
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
      for (int j = 0; j < cachedTags.length; j++) {
        if (shouldReplicateTag(tags, tags[i])) {
          List toClosedTag = tags[i].split("<");
          String closedTag = '</${toClosedTag[1]}';

          controller.value = controller.value.copyWith(
              text: controller.text.replaceRange(
                  max(cursorPos, 0), max(cursorPos, 0), closedTag),
              selection: TextSelection.fromPosition(
                  TextPosition(offset: max(cursorPos, 0))));
          break outerloop;
        }
      }
    }

    writeNewTagCache(tags, 'helloworld');
  }
}
