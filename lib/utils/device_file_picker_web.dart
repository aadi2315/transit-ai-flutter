// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'device_file_picker.dart';

Future<PickedDeviceInfo?> pickFileFromDeviceImpl({
  List<String> allowedExtensions = const ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
}) {
  final completer = Completer<PickedDeviceInfo?>();

  final input = html.FileUploadInputElement();
  input.accept = allowedExtensions.map((ext) => '.$ext').join(',');
  input.multiple = false;

  input.style.display = 'none';
  html.document.body?.children.add(input);

  void cleanup() {
    input.remove();
  }

  input.onChange.listen((event) {
    final files = input.files;
    if (files != null && files.isNotEmpty) {
      final file = files.first;
      final ext = file.name.contains('.') ? file.name.split('.').last : null;
      completer.complete(
        PickedDeviceInfo(
          fileName: file.name,
          fileSize: file.size,
          extension: ext,
        ),
      );
    } else {
      completer.complete(null);
    }
    cleanup();
  });

  input.click();

  return completer.future;
}
