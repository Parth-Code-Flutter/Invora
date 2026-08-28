import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Best-effort first-sheet reader for simple Excel .xlsx exports.
abstract final class XlsxSheetReader {
  static List<List<String>>? tryParse(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final shared = _sharedStrings(archive);
      final sheet = archive.files.firstWhere(
        (file) => file.name == 'xl/worksheets/sheet1.xml',
        orElse: () => archive.files.firstWhere(
          (file) => file.name.startsWith('xl/worksheets/sheet'),
        ),
      );
      return _cells(utf8.decode(sheet.content as List<int>), shared);
    } catch (_) {
      return null;
    }
  }

  static List<String> _sharedStrings(Archive archive) {
    final file = archive.findFile('xl/sharedStrings.xml');
    if (file == null) return const [];
    final xml = utf8.decode(file.content as List<int>);
    return RegExp(r'<si[\s\S]*?</si>', caseSensitive: false)
        .allMatches(xml)
        .map((match) {
          final texts = RegExp(
            r'<t(?:\s[^>]*)?>([\s\S]*?)</t>',
            caseSensitive: false,
          ).allMatches(match.group(0)!).map((t) => _unescape(t.group(1)!));
          return texts.join();
        })
        .toList(growable: false);
  }

  static List<List<String>> _cells(String xml, List<String> shared) {
    final values = <(int, int, String)>[];
    var maxRow = 0;
    var maxCol = 0;
    for (final match in RegExp(
      r'<c([^>]*)>([\s\S]*?)</c>',
      caseSensitive: false,
    ).allMatches(xml)) {
      final attrs = match.group(1)!;
      final body = match.group(2)!;
      final ref = RegExp(r'r="([A-Z]+)(\d+)"').firstMatch(attrs);
      if (ref == null) continue;
      final col = _columnIndex(ref.group(1)!);
      final row = int.parse(ref.group(2)!);
      final type = RegExp(r't="([^"]+)"').firstMatch(attrs)?.group(1);
      final raw = RegExp(
        r'<v>([\s\S]*?)</v>',
        caseSensitive: false,
      ).firstMatch(body)?.group(1);
      var text = '';
      if (type == 's' && raw != null) {
        final index = int.tryParse(raw);
        if (index != null && index >= 0 && index < shared.length) {
          text = shared[index];
        }
      } else if (type == 'inlineStr') {
        text = _unescape(
          RegExp(
                r'<t(?:\s[^>]*)?>([\s\S]*?)</t>',
                caseSensitive: false,
              ).firstMatch(body)?.group(1) ??
              '',
        );
      } else if (raw != null) {
        text = _unescape(raw);
      }
      values.add((row, col, text));
      if (row > maxRow) maxRow = row;
      if (col > maxCol) maxCol = col;
    }
    if (maxRow == 0) return const [];
    final grid = List.generate(maxRow, (_) => List<String>.filled(maxCol, ''));
    for (final cell in values) {
      grid[cell.$1 - 1][cell.$2 - 1] = cell.$3;
    }
    while (grid.isNotEmpty && grid.last.every((cell) => cell.trim().isEmpty)) {
      grid.removeLast();
    }
    return grid;
  }

  static int _columnIndex(String letters) {
    var index = 0;
    for (final code in letters.codeUnits) {
      index = index * 26 + (code - 64);
    }
    return index;
  }

  static String _unescape(String raw) => raw
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');
}
