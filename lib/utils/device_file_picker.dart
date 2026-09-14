import 'dart:typed_data';
import 'device_file_picker_stub.dart'
    if (dart.library.html) 'device_file_picker_web.dart' as impl;

class PickedDeviceInfo {
  final String fileName;
  final int fileSize;
  final String? extension;
  final Uint8List? bytes;
  final String? mimeType;

  const PickedDeviceInfo({
    required this.fileName,
    required this.fileSize,
    this.extension,
    this.bytes,
    this.mimeType,
  });

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

Future<PickedDeviceInfo?> pickFileFromDevice({
  List<String> allowedExtensions = const ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
}) async {
  return impl.pickFileFromDeviceImpl(allowedExtensions: allowedExtensions);
}
