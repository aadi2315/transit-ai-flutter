
import 'device_file_picker.dart';

Future<PickedDeviceInfo?> pickFileFromDeviceImpl({
  List<String> allowedExtensions = const ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
}) async {
  return const PickedDeviceInfo(
    fileName: 'student_document.pdf',
    fileSize: 462 * 1024,
    extension: 'pdf',
  );
}
