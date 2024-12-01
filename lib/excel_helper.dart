import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:todolist_app/task.dart';

Future<void> exportTasksToExcel({
  required BuildContext context,
  required String folderTitle,
  required int totalTasks,
  required List<Task> lateTasks,
  required List<Task> todayTasks,
  required List<Task> doneTasks,
}) async {
  if (lateTasks.isEmpty && todayTasks.isEmpty && doneTasks.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Không có task nào để xuất')),
    );
    return;
  }

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
        const SnackBar(content: Text('Xuất Task thành công')),
      );
    } else {
      throw Exception('Không thể tạo file Excel');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Xuất thất bại: $e')),
    );
  }
}
