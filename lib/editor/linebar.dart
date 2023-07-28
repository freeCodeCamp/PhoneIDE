import 'package:flutter/material.dart';

class Linebar extends StatefulWidget {
  final Widget child;
  final Function calculateBarWidth;

  const Linebar(
      {Key? key, required this.calculateBarWidth, required this.child})
      : super(key: key);

  static Size calculateTextSize(
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
    return textPainter.size;
  }

  @override
  LinebarState createState() => LinebarState();
}

class LinebarState extends State<Linebar> {
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
