import 'dart:developer' as dev;

mixin IEditor {
  void returnEditorValue(String text) {
    dev.log(text);
    dev.log('iget extecuted');
  }
}
