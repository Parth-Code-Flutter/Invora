abstract final class CsvCodec {
  static String encode(List<List<Object?>> rows) =>
      rows.map((row) => row.map(escape).join(',')).join('\r\n');

  static String escape(Object? raw) {
    final value = raw?.toString() ?? '';
    if (!value.contains(RegExp('[,"\\r\\n]'))) return value;
    return '"${value.replaceAll('"', '""')}"';
  }

  /// RFC 4180 parser. Strips a leading UTF-8 BOM.
  static List<List<String>> decode(String raw) {
    var text = raw;
    if (text.startsWith('\uFEFF')) text = text.substring(1);
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var inQuotes = false;
    var i = 0;
    while (i < text.length) {
      final ch = text[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            field.write('"');
            i += 2;
            continue;
          }
          inQuotes = false;
          i++;
          continue;
        }
        field.write(ch);
        i++;
        continue;
      }
      if (ch == '"') {
        inQuotes = true;
        i++;
        continue;
      }
      if (ch == ',') {
        row.add(field.toString());
        field.clear();
        i++;
        continue;
      }
      if (ch == '\n' || ch == '\r') {
        row.add(field.toString());
        field.clear();
        if (row.length > 1 || row.first.isNotEmpty) {
          rows.add(row);
        }
        row = <String>[];
        if (ch == '\r' && i + 1 < text.length && text[i + 1] == '\n') {
          i += 2;
        } else {
          i++;
        }
        continue;
      }
      field.write(ch);
      i++;
    }
    row.add(field.toString());
    if (row.length > 1 || row.first.isNotEmpty) {
      rows.add(row);
    }
    return rows;
  }
}
