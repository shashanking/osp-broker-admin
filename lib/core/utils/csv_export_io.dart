import 'dart:io';

import 'package:file_picker/file_picker.dart';

Future<void> saveCsv({
  required String fileName,
  required String csv,
}) async {
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Save CSV',
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: const ['csv'],
  );

  if (path == null) return;

  final file = File(path);
  await file.writeAsString(csv);
}
