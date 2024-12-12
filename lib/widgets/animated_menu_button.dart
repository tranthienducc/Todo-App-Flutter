import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:todolist_app/classed/folder_data.dart';
import 'package:todolist_app/services/excel_helper.dart';
import 'package:todolist_app/services/platform_utils.dart';
import 'package:todolist_app/widgets/create_folder_dialog.dart';

import '../classed/task.dart';
import '../services/excel_service.dart';
import "../main.dart";
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AnimatedMenuButton extends StatefulWidget {
  final Function(FolderData) onFolderCreated;
  final Function(FolderData) onFolderEdit;
  final List<FolderData> currentFolders;
  final List<FolderData> folderLists;
  List<Task> lateTasks;
  List<Task> todayTasks;
  List<Task> doneTasks;
  List<Task> taskList = [];

  AnimatedMenuButton({
    super.key,
    required this.onFolderCreated,
    required this.onFolderEdit,
    required this.currentFolders,
    required this.folderLists,
    required this.taskList,
    this.lateTasks = const [],
    this.todayTasks = const [],
    this.doneTasks = const [],
  });

  @override
  State<AnimatedMenuButton> createState() => _AnimatedMenuButtonState();
}

class _AnimatedMenuButtonState extends State<AnimatedMenuButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final ExcelService _excelService = ExcelService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _importExcel() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final sampleFilePath = '${directory.path}/sample_import.xlsx';
      final sampleFile = File(sampleFilePath);

      if (!await sampleFile.exists()) {
        final excel = Excel.createExcel();
        final sheet = excel[excel.getDefaultSheet()!];
        sheet.appendRow([
          TextCellValue("Tên Thư Mục"),
          TextCellValue("Tổng Số Task"),
          TextCellValue("Task Quá Hạn"),
          TextCellValue("Task Hôm Nay"),
          TextCellValue("Task Đã Hoàn Thành")
        ]);
        await sampleFile.writeAsBytes(excel.encode()!);

        _showDialog(
          context,
          AppLocalizations.of(context)!.sampleFileExcel(sampleFilePath),
          Colors.orange,
        );
        return;
      }

      List<Map<String, dynamic>> importedData =
          await _excelService.importFromExcel();

      if (importedData.isEmpty) {
        _showDialog(
          context,
          AppLocalizations.of(context)!.notFoundFolderFileExcel,
          Colors.orange,
        );
        return;
      }

      List<FolderData> newFolders = [];
      for (var data in importedData) {
        if (data['title'] == null || data['title'].toString().isEmpty) {
          print('Skipping invalid folder: $data');
          continue;
        }

        FolderData newFolder = FolderData(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: data['title'],
            color: data['color'] ?? Colors.blue.value,
            icon: data['icon'] ?? Icons.folder.codePoint);
        newFolders.add(newFolder);
        widget.onFolderCreated(newFolder);
      }

      _showDialog(
        context,
        AppLocalizations.of(context)!.importFolder(newFolders.length),
        newFolders.isNotEmpty ? Colors.green : Colors.orange,
      );
    } catch (e) {
      _showDialog(
        context,
        AppLocalizations.of(context)!.importFailed(e),
        Colors.grey,
      );
    }
  }

  void _showDialog(
      BuildContext context, String message, Color backgroundColor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.notifications),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.exit),
            ),
          ],
          backgroundColor: backgroundColor,
        );
      },
    );
  }

  void _toggleLanguage() {
    final newLocale = FolderListPage.localeNotifier.value.languageCode == 'en'
        ? const Locale('vi')
        : const Locale('en');

    FolderListPage.setLocale(context, newLocale);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.menu,
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.create),
            title: Text(AppLocalizations.of(context)!.createFolder),
            onTap: () async {
              Navigator.pop(context);
              final result = await showDialog<FolderData>(
                context: context,
                builder: (context) => const CreateFolderDialog(),
              );

              if (result != null) {
                widget.onFolderCreated(result);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: ValueListenableBuilder<Locale>(
              valueListenable: FolderListPage.localeNotifier,
              builder: (context, locale, _) {
                return Text(
                    locale.languageCode == 'en' ? 'Vietnamese' : 'English');
              },
            ),
            onTap: () {
              Navigator.pop(context);
              _toggleLanguage();
            },
          ),
          if (kIsWeb || PlatformUtil.isDesktopPlatform)
            ListTile(
              leading: const Icon(Icons.import_export),
              title: Text(AppLocalizations.of(context)!.importExcel),
              onTap: () {
                Navigator.pop(context);
                _importExcel();
              },
            ),
          if (kIsWeb || PlatformUtil.isDesktopPlatform)
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: Text(AppLocalizations.of(context)!.exportExcel),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return DialogExportExcel(
                      context: context,
                      folderListWidget: widget.folderLists,
                      lateTasks: widget.lateTasks,
                      todayTasks: widget.todayTasks,
                      doneTasks: widget.doneTasks,
                      taskList: widget.taskList,
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}
