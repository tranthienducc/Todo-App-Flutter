import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExcelService {
  get iconString => null;

  IconData _parseIconFromString(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'document':
        return Icons.document_scanner;
      case 'folder':
        return Icons.folder;
      case 'file':
        return Icons.file_present;
      case '📄':
        return Icons.document_scanner;
      case '📂':
        return Icons.folder;
      case '🔧':
        return Icons.build;
      default:
        return Icons.help_outline;
    }
  }

  Color _parseColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<List<Map<String, dynamic>>> importFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null) {
        return [];
      }

      var bytes = result.files.single.bytes;
      if (bytes == null) {
        return [];
      }

      var excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        return [];
      }

      var sheetName = excel.tables.keys.first;
      var rows = excel.tables[sheetName]!.rows;

      if (rows.isEmpty) {
        return [];
      }

      List<Map<String, dynamic>> folders = [];

      for (var row in rows.skip(1)) {
        String title = row[0]?.value?.toString() ?? '';
        String iconName = row[1]?.value?.toString() ?? '';
        String colorName = row[2]?.value?.toString() ?? '';
        IconData icon = _parseIconFromString(iconName);
        Color color = _parseColorFromName(colorName);

        if (title.isEmpty) {
          continue;
        }

        folders.add({
          'title': title,
          'icon': icon,
          'color': color,
        });
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('folders', json.encode(folders));
      } catch (e) {
        print('Lỗi khi lưu dữ liệu vào SharedPreferences: $e');
      }
      return folders;
    } catch (e) {
      print('Excel import error: $e');
      return [];
    }
  }

  Future<void> saveExcel(Excel excel, String fileName) async {
    try {
      final directory = await getExternalStorageDirectory();

      if (directory == null) {
        throw Exception('Không thể truy cập thư mục lưu trữ');
      }

      final filePath = '${directory.path}/$fileName.xlsx';

      List<int>? fileBytes = excel.save();

      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes!);
    } catch (e) {
      print('Lỗi khi lưu file Excel: $e');
      rethrow;
    }
  }
}

extension on Object? {
  get isNotEmpty => null;
}
