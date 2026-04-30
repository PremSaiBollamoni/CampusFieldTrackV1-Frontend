import 'dart:io';

// Mobile implementation — dart:io is available on Android/iOS.
Future<void> writeFileBytes(String path, List<int> bytes) async {
  final file = File(path);
  await file.writeAsBytes(bytes);
}
