import 'package:flutter/material.dart';
import 'package:rich_text_controller/rich_text_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as dev;
import 'dart:math';

mixin IEditor {
  void returnEditorValue(String text) {}

  /// Takes a text controller and returns the current position of the cursor.

  String getTextOnCurrentLine(RichTextController? controller) {
    return controller!.selection
        .textBefore(controller.value.text)
        .split("\n")
        .last;
  }

  List<RegExpMatch> matchTags(String text) {
    RegExp pattern = RegExp('<("[^"\n]*"|\'[^\'\n]*\'|[^\'"\n>])*>');
    Iterable<RegExpMatch> match = pattern.allMatches(text);

    return match.toList();
  }

  void replicateTags(List<String> match, RichTextController? controller) async {
    if (controller == null) return;

    List<RegExpMatch> matches = matchTags(controller.text);

    List<String> tags = [];

    var prefs = await SharedPreferences.getInstance();

    bool shouldReplicate = false;

    if (prefs.getInt('tagmatch') == null) {
      prefs.setInt('tagmatch', 0);
    }

    if (matches.length > (prefs.getInt('tagmatch') as int)) {
      prefs.setInt('tagmatch', matches.length);
      shouldReplicate = true;
    } else {
      prefs.setInt('tagmatch', matches.length);
    }

    // get matches on the current line

    String currentLine = getTextOnCurrentLine(controller);

    matches = matchTags(currentLine);

    for (var tag in matches) {
      tags.add(tag.group(0) as String);
    }

    final int cursorPos = controller.selection.base.offset;

    if (matches.isNotEmpty && shouldReplicate) {
      controller.value = controller.value.copyWith(
          text: controller.text.replaceRange(max(cursorPos, 0),
              max(cursorPos, 0), '</${tags.last.split("<")[1]}'),
          selection: TextSelection.fromPosition(
              TextPosition(offset: max(cursorPos, 0))));
    }
  }
}
