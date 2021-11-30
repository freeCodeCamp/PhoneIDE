import 'package:flutter/material.dart';
import 'dart:developer' as dev;

class Linebar extends StatefulWidget {
  final Widget child;
  final Function calculateBarWidth;

  const Linebar(
      {Key? key, required this.calculateBarWidth, required this.child})
      : super(key: key);

  static double calculateTextSize(
    String text, {
    required TextStyle style,
    required BuildContext context,
    double minWidth = 0,
    double maxWidth = double.infinity,
  }) {
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final TextDirection textDirection = Directionality.of(context);

    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      textScaleFactor: textScaleFactor,
    )..layout(minWidth: minWidth, maxWidth: maxWidth);
    dev.log(textPainter.size.width.toString());
    return textPainter.size.width;
  }

  @override
  _LinebarState createState() => _LinebarState();
}

class _LinebarState extends State<Linebar> {
  @override
  void initState() {
    super.initState();
    widget.calculateBarWidth();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
