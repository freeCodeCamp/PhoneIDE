import 'package:phone_ide/controller/custom_text_controller.dart';

enum RegionPosition { before, inner, after }

class TextFieldData {
  const TextFieldData({required this.controller, required this.position});

  final TextEditingControllerIDE controller;

  final RegionPosition position;
}
