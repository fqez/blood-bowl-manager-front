import 'dart:async';
import 'dart:html' as html;

Future<String?> pickPlayerImageDataUri() {
  final completer = Completer<String?>();
  final input = html.FileUploadInputElement()
    ..accept = 'image/png,image/jpeg,image/webp,image/gif'
    ..style.display = 'none';

  html.document.body?.append(input);

  void cleanup() => input.remove();

  input.onChange.first.then((_) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      cleanup();
      if (!completer.isCompleted) completer.complete(null);
      return;
    }

    final reader = html.FileReader();
    reader.onError.first.then((_) {
      cleanup();
      if (!completer.isCompleted) {
        completer.completeError(reader.error ?? 'Could not read image file');
      }
    });
    reader.onLoad.first.then((_) {
      cleanup();
      final result = reader.result;
      if (result is String && result.startsWith('data:image/')) {
        completer.complete(result);
      } else {
        completer.completeError('Selected file is not a valid image');
      }
    });
    reader.readAsDataUrl(files.first);
  }).catchError((Object error) {
    cleanup();
    if (!completer.isCompleted) completer.completeError(error);
  });

  input.click();
  return completer.future;
}
