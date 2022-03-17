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

    String makeClosedTag(String openTag) {
      if (openTag.contains(' ')) {
        List<String> openTagPieces = openTag.split(' ');

        String tagName = openTagPieces[0].split('<')[1];

        return '</$tagName>';
      } else {
        return '</${openTag.split('<')[1]}';
      }
    }

    String removeTagAttributes(String openTag) {
      if (!openTag.contains(' ')) return openTag;

      List<String> openTagPieces = openTag.split(' ');

      String tagName = openTagPieces[0].split('<')[1];

      return '<$tagName>';
    }

    bool shouldReplicate = false;

    for (var tag in matches) {
      tags.add(tag.group(0) as String);
    }

    var getMatchLine = getTextOnCurrentLine(controller);
    var getMatchesOnLine = matchTags(getMatchLine);

    if (tags.isEmpty || getMatchesOnLine.isEmpty) return;

    String latestMatch = getMatchesOnLine.last.group(0) ?? '';

    int openTags = 0;
    int closedTags = 0;

    for (String tag in tags) {
      if (latestMatch.isEmpty || latestMatch.contains('/')) break;

      tag = removeTagAttributes(tag);
      latestMatch = removeTagAttributes(latestMatch);

      String closedTag = makeClosedTag(latestMatch);

      openTags = tags.where((tag) => tag == latestMatch).length;
      closedTags = tags.where((tag) => tag == closedTag).length;
    }

    if (openTags > closedTags) {
      final int cursorPos = controller.selection.base.offset;

      shouldReplicate = true;

      if (matches.isNotEmpty && shouldReplicate) {
        controller.value = controller.value.copyWith(
            text: controller.text.replaceRange(max(cursorPos, 0),
                max(cursorPos, 0), makeClosedTag(latestMatch)),
            selection: TextSelection.fromPosition(
                TextPosition(offset: max(cursorPos, 0))));
      }
    }
  }
}
