import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:todolist_app/classed/folder_data.dart';
import 'package:todolist_app/classed/task.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:todolist_app/utils/enum/enum.dart';

class DialogExportExcel extends StatefulWidget {
  final BuildContext context;
  final List<Task> lateTasks;
  final List<Task> todayTasks;
  final List<Task> doneTasks;
  final List<Task> taskList;
  final List<FolderData> folderListWidget;

  DialogExportExcel({
    required this.context,
    required this.lateTasks,
    required this.todayTasks,
    required this.doneTasks,
    required this.taskList,
    required this.folderListWidget,
  });

  @override
  _DialogExportExcelState createState() => _DialogExportExcelState();
}

class _DialogExportExcelState extends State<DialogExportExcel> {
  late FolderData? selectedFolder;
  late Task? selectedTask;

  @override
  void initState() {
    super.initState();
    selectedFolder = widget.folderListWidget.isNotEmpty
        ? widget.folderListWidget.first
        : null;

    if (selectedFolder != null && selectedFolder!.taskLists!.isNotEmpty) {
      selectedTask = selectedFolder!.taskLists!.first;
    } else {
      selectedTask = null;
    }
  }

  Future<void> exportExcel() async {
    if (selectedFolder == null && selectedTask == null ||
        selectedFolder!.taskLists!.isEmpty) {
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
        TextCellValue("Thư mục mẫu"),
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

      taskSheet.appendRow([
        TextCellValue("Công việc mẫu"),
        TextCellValue("2025-1-1"),
        TextCellValue("8:00 PM"),
        TextCellValue("PENDING"),
        TextCellValue("Thư mục mẫu"),
      ]);

      Uint8List? excelBytes = Uint8List.fromList(excel.save() ?? []);

      if (excelBytes.isNotEmpty) {
        String fileName = 'thumucmau_tasks';
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: excelBytes,
          ext: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.exportExcelSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (selectedFolder != null) {
      var excel = Excel.createExcel();
      List<FolderData> folderDataList =
          widget.folderListWidget.map((folderWidget) {
        return folderWidget;
      }).toList();

      var folderSheet = excel['Folder Information'];
      folderSheet.appendRow([
        TextCellValue("Tên Thư Mục"),
        TextCellValue("Tổng Số Task"),
        TextCellValue("Task Quá Hạn"),
        TextCellValue("Task Hôm Nay"),
        TextCellValue("Task Đã Hoàn Thành"),
      ]);

      for (var folder in folderDataList) {
        int totalTasks = folder.taskLists?.length ?? 0;
        int overdueTasks = folder.taskLists
                ?.where((task) =>
                    task.date.isBefore(DateTime.now()) && !task.isDone)
                .length ??
            0;
        int todayTasks = folder.taskLists
                ?.where((task) =>
                    task.date.year == DateTime.now().year &&
                    task.date.month == DateTime.now().month &&
                    task.date.day == DateTime.now().day)
                .length ??
            0;
        int doneTasks =
            folder.taskLists?.where((task) => task.isDone).length ?? 0;
        folderSheet.appendRow([
          TextCellValue(folder.title),
          TextCellValue(totalTasks.toString()),
          TextCellValue(overdueTasks.toString()),
          TextCellValue(todayTasks.toString()),
          TextCellValue(doneTasks.toString()),
        ]);
      }

      var taskSheet = excel['Tasks'];
      taskSheet.appendRow([
        TextCellValue("Tiêu Đề"),
        TextCellValue("Ngày"),
        TextCellValue("Giờ"),
        TextCellValue("Trạng Thái"),
        TextCellValue("Ghi Chú"),
        TextCellValue("Thư Mục"),
      ]);
      for (var folder in folderDataList) {
        if (folder.title == "All") {
          continue;
        }

        for (var task in folder.taskLists ?? []) {
          taskSheet.appendRow([
            TextCellValue(task.title),
            TextCellValue(task.date.toString().split(' ')[0]),
            TextCellValue(task.time),
            TextCellValue(task.isDone ? 'Đã Hoàn Thành' : 'Chưa Hoàn Thành'),
            TextCellValue(task.note ?? ''),
            TextCellValue(folder.title),
          ]);
        }
      }

      List<int>? savedFile = excel.save();
      if (savedFile == null) {
        throw Exception("Excel file creation failed");
      }

      Uint8List excelBytes = Uint8List.fromList(savedFile);

      if (excelBytes.isNotEmpty) {
        String fileName = '${selectedFolder!.title}_tasks';
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: excelBytes,
          ext: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.exportExcelSuccess),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.exportExcelFailed),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.notifications),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.selectFolderAndTask),
            const SizedBox(height: 10),
            Text(AppLocalizations.of(context)!.selectFolder),
            DropdownButton<FolderData>(
              hint: Text(AppLocalizations.of(context)!.selectFolder),
              value: widget.folderListWidget
                      .any((folder) => folder == selectedFolder)
                  ? selectedFolder
                  : null,
              onChanged: (FolderData? newFolder) {
                setState(() {
                  selectedFolder = newFolder;
                  selectedTask = newFolder?.taskLists?.isNotEmpty ?? false
                      ? newFolder!.taskLists!.first
                      : Task(
                          id: '',
                          title: 'Default Task',
                          time: '',
                          isDone: false,
                          note: '',
                          status: TaskStatus.TODO,
                          date: DateTime.now(),
                        );
                });
              },
              items: widget.folderListWidget
                  .map<DropdownMenuItem<FolderData>>((folder) {
                return DropdownMenuItem<FolderData>(
                  value: folder,
                  child: Row(
                    children: [
                      Icon(folder.icon, color: folder.color),
                      const SizedBox(width: 10),
                      Text(folder.title),
                    ],
                  ),
                );
              }).toList(),
            ),
            if (selectedFolder != null) ...[
              const SizedBox(height: 10),
              Text(AppLocalizations.of(context)!
                  .selectTaskTo(selectedFolder!.title)),
              DropdownButton<Task>(
                hint: Text(AppLocalizations.of(context)!.selectTask),
                value:
                    selectedFolder!.taskLists?.contains(selectedTask) ?? false
                        ? selectedTask
                        : null,
                onChanged: (Task? newTask) {
                  setState(() {
                    selectedTask = newTask!;
                  });
                },
                items: selectedFolder!.taskLists
                        ?.map<DropdownMenuItem<Task>>((task) {
                      return DropdownMenuItem<Task>(
                        value: task,
                        child: Text(task.title),
                      );
                    }).toList() ??
                    [],
              ),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () async {
            await exportExcel();
            Navigator.of(context).pop();
          },
          child: Text(AppLocalizations.of(context)!.save),
        ),
      ],
      backgroundColor: Colors.white,
    );
  }
}
