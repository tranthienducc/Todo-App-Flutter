import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:todolist_app/task.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<void> exportTasksToExcel({
  required BuildContext context,
  required String folderTitle,
  required int totalTasks,
  required List<Task> lateTasks,
  required List<Task> todayTasks,
  required List<Task> doneTasks,
}) async {
  try {
    var excel = Excel.createExcel();

    var folderSheet = excel['Folder Information'];
    folderSheet.appendRow([
      TextCellValue("Tên Thư Mục"),
      TextCellValue("Tổng Số Task"),
      TextCellValue("Task Quá Hạn"),
      TextCellValue("Task Hôm Nay"),
      TextCellValue("Task Đã Hoàn Thành"),
    ]);
    folderSheet.appendRow([
      TextCellValue(folderTitle),
      TextCellValue(totalTasks.toString()),
      TextCellValue(lateTasks.length.toString()),
      TextCellValue(todayTasks.length.toString()),
      TextCellValue(doneTasks.length.toString()),
    ]);

    var taskSheet = excel['Tasks'];
    taskSheet.appendRow([
      TextCellValue("Tiêu Đề"),
      TextCellValue("Ngày"),
      TextCellValue("Giờ"),
      TextCellValue("Trạng Thái"),
      TextCellValue("Ghi Chú"),
      TextCellValue("Thư Mục"),
    ]);

    final allTasks = [...lateTasks, ...todayTasks, ...doneTasks];
    for (var task in allTasks) {
      taskSheet.appendRow([
        TextCellValue(task.title),
        TextCellValue(task.date.toString().split(' ')[0]),
        TextCellValue(task.time),
        TextCellValue(task.isDone ? 'Đã Hoàn Thành' : 'Chưa Hoàn Thành'),
        TextCellValue(task.note ?? ''),
        TextCellValue(folderTitle),
      ]);
    }

    Uint8List? excelBytes = Uint8List.fromList(excel.save() ?? []);

    if (excelBytes.isNotEmpty) {
      String fileName = '${folderTitle}_tasks';
      if (!fileName.endsWith('.xlsx')) {
        fileName += '.xlsx';
      }

      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: excelBytes,
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.exportExcelSuccess)),
      );
    } else {
      throw Exception(AppLocalizations.of(context)!.errorExportExecl);
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.exportExcelFailed)),
    );
  }
}

Future<void> _createEmptyExcel(BuildContext context, String folderTitle) async {
  var excel = Excel.createExcel();
  var folderSheet = excel['Folder Information'];
  folderSheet.appendRow([
    TextCellValue("Tên Thư Mục"),
    TextCellValue("Tổng Số Task"),
    TextCellValue("Task Quá Hạn"),
    TextCellValue("Task Hôm Nay"),
    TextCellValue("Task Đã Hoàn Thành"),
  ]);
  folderSheet.appendRow([
    TextCellValue(folderTitle),
    TextCellValue("0"),
    TextCellValue("0"),
    TextCellValue("0"),
    TextCellValue("0"),
  ]);

  var taskSheet = excel['Tasks'];
  taskSheet.appendRow([
    TextCellValue("Tiêu Đề"),
    TextCellValue("Ngày"),
    TextCellValue("Giờ"),
    TextCellValue("Trạng Thái"),
    TextCellValue("Ghi Chú"),
    TextCellValue("Thư Mục"),
  ]);

  Uint8List? excelBytes = Uint8List.fromList(excel.save() ?? []);

  if (excelBytes.isNotEmpty) {
    String fileName = '${folderTitle}_tasks';
    if (!fileName.endsWith('.xlsx')) {
      fileName += '.xlsx';
    }

    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: excelBytes,
      ext: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.exportExcelSuccess)),
    );
  } else {
    throw Exception(AppLocalizations.of(context)!.errorExportExecl);
  }
}
