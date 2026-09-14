// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'dart:typed_data';
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
      final ext = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : null;
      
      String mime = 'image/jpeg';
      if (ext == 'png') {
        mime = 'image/png';
      } else if (ext == 'pdf') {
        mime = 'application/pdf';
      } else if (ext == 'webp') {
        mime = 'image/webp';
      }

      final reader = html.FileReader();
      reader.onLoadEnd.listen((e) {
        final result = reader.result;
        Uint8List? fileBytes;
        if (result is Uint8List) {
          fileBytes = result;
        } else if (result is ByteBuffer) {
          fileBytes = Uint8List.view(result);
        } else if (result is List<int>) {
          fileBytes = Uint8List.fromList(result);
        }

        completer.complete(
          PickedDeviceInfo(
            fileName: file.name,
            fileSize: file.size,
            extension: ext,
            bytes: fileBytes,
            mimeType: mime,
          ),
        );
      });

      reader.onError.listen((e) {
        completer.complete(
          PickedDeviceInfo(
            fileName: file.name,
            fileSize: file.size,
            extension: ext,
          ),
        );
      });

      reader.readAsArrayBuffer(file);
    } else {
      completer.complete(null);
    }
    cleanup();
  });

  input.click();

  return completer.future;
}
