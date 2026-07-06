import 'dart:convert';

import 'csv_export_io.dart' if (dart.library.html) 'csv_export_web.dart'
    as impl;

String _stringifyValue(Object? value) {
  if (value == null) return '';
  if (value is DateTime) return value.toIso8601String();
  if (value is num || value is bool) return value.toString();
  if (value is String) return value;
  if (value is Map || value is Iterable) {
    return jsonEncode(value);
  }
  return value.toString();
}

String _escapeCsvCell(String input) {
  final needsQuotes = input.contains(',') ||
      input.contains('\n') ||
      input.contains('\r') ||
      input.contains('"');
  if (!needsQuotes) return input;
  final escaped = input.replaceAll('"', '""');
  return '"$escaped"';
}

String buildCsv(
  List<Map<String, Object?>> rows, {
  List<String>? headers,
}) {
  final resolvedHeaders = headers ??
      <String>{
        for (final row in rows) ...row.keys,
      }.toList();

  final buffer = StringBuffer();
  buffer.writeln(resolvedHeaders.map(_escapeCsvCell).join(','));

  for (final row in rows) {
    final line = resolvedHeaders
        .map((h) => _escapeCsvCell(_stringifyValue(row[h])))
        .join(',');
    buffer.writeln(line);
  }

  return buffer.toString();
}

Future<void> exportCsv({
  required String fileName,
  required List<Map<String, Object?>> rows,
  List<String>? headers,
}) async {
  final csv = buildCsv(rows, headers: headers);
  await impl.saveCsv(fileName: fileName, csv: csv);
}
