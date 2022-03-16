import 'package:flutter/material.dart';
import 'package:rich_text_controller/rich_text_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

    bool shouldReplicate = false;

    for (var tag in matches) {
      tags.add(tag.group(0) as String);
    }

    var getMatchLine = getTextOnCurrentLine(controller);
    var getMatchesOnLine = matchTags(getMatchLine);

    if (tags.isEmpty || getMatchesOnLine.isEmpty) return;

    String latestMatch = getMatchesOnLine.last.group(0) ?? '';

    int? openTags;
    int? closedTags;

    for (String tag in tags) {
      if (latestMatch.isEmpty || latestMatch.contains('/')) break;

      String closedTag = '</' + latestMatch.split('<')[1];

      openTags = tags.where((tag) => tag == latestMatch).length;
      closedTags = tags.where((tag) => tag == closedTag).length;
    }

    if (openTags! > closedTags!) {
      final int cursorPos = controller.selection.base.offset;

      shouldReplicate = true;

      if (matches.isNotEmpty && shouldReplicate) {
        controller.value = controller.value.copyWith(
            text: controller.text.replaceRange(max(cursorPos, 0),
                max(cursorPos, 0), '</' + latestMatch.split('<')[1]),
            selection: TextSelection.fromPosition(
                TextPosition(offset: max(cursorPos, 0))));
      }
    }
  }
}
