import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import './task.dart';
import 'excel_service.dart';
import "main.dart";
import 'platform_utils.dart';

class AnimatedMenuButton extends StatefulWidget {
  final Function(FolderData) onFolderCreated;
  final Function(FolderData) onFolderEdit;
  final List<FolderData> currentFolders;
  final Function(bool isOpen) onMenuToggle;
  final List<FolderData> folderLists;

  const AnimatedMenuButton({
    super.key,
    required this.onFolderCreated,
    required this.onFolderEdit,
    required this.currentFolders,
    required this.onMenuToggle,
    required this.folderLists,
  });

  @override
  State<AnimatedMenuButton> createState() => _AnimatedMenuButtonState();
}

class _AnimatedMenuButtonState extends State<AnimatedMenuButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;
  final ExcelService _excelService = ExcelService();
  late List<Task> lateTasks;
  late List<Task> todayTasks;
  late List<Task> doneTasks;

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

  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
      widget.onMenuToggle(_isOpen);
    });
  }

  void _closeMenu() {
    if (_isOpen) {
      setState(() {
        _isOpen = false;
        _controller.reverse();
        widget.onMenuToggle(_isOpen);
      });
    }
  }

  Future<void> _importExcel() async {
    _closeMenu();
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
        sheet.appendRow([
          TextCellValue("Tên Thư Mục"),
          TextCellValue("Tổng Số Task"),
          TextCellValue("Task Quá Hạn"),
          TextCellValue("Task Hôm Nay"),
          TextCellValue("Task Đã Hoàn Thành")
        ]);
        await sampleFile.writeAsBytes(excel.encode()!);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Sample file created at: $sampleFilePath'),
            backgroundColor: Colors.orange));
        return;
      }
      List<Map<String, dynamic>> importedData =
          await _excelService.importFromExcel();

      if (importedData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No folders found in the Excel file'),
            backgroundColor: Colors.orange));
        return;
      }

      List<FolderData> newFolders = [];
      for (var data in importedData) {
        if (data['title'] == null || data['title'].toString().isEmpty) {
          print('Skipping invalid folder: $data');
          continue;
        }

        FolderData newFolder = FolderData(
            title: data['title'],
            color: data['color'] ?? Colors.blue.value,
            icon: data['icon'] ?? Icons.folder.codePoint);
        newFolders.add(newFolder);
        widget.onFolderCreated(newFolder);
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Imported ${newFolders.length} folders'),
          backgroundColor:
              newFolders.isNotEmpty ? Colors.green : Colors.orange));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Import failed: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _exportExcel() async {
    try {
      var excel = Excel.createExcel();

      if (widget.folderLists.isEmpty ||
          (lateTasks.isEmpty && todayTasks.isEmpty && doneTasks.isEmpty)) {
        var folderSheet = excel['Folder Information'];
        folderSheet.appendRow([
          TextCellValue("Tên Thư Mục"),
          TextCellValue("Tổng Số Task"),
          TextCellValue("Task Quá Hạn"),
          TextCellValue("Task Hôm Nay"),
          TextCellValue("Task Đã Hoàn Thành")
        ]);
        folderSheet.appendRow([
          TextCellValue("Chưa có dữ liệu"),
          TextCellValue('0'),
          TextCellValue('0'),
          TextCellValue('0'),
          TextCellValue('0')
        ]);

        var taskSheet = excel['Tasks'];
        taskSheet.appendRow([
          TextCellValue("Tiêu Đề"),
          TextCellValue("Ngày"),
          TextCellValue("Giờ"),
          TextCellValue("Trạng Thái"),
          TextCellValue("Ghi Chú"),
          TextCellValue("Thư Mục")
        ]);
        taskSheet.appendRow([
          TextCellValue("Chưa có dữ liệu"),
          TextCellValue("Chưa có dữ liệu"),
          TextCellValue("Chưa có dữ liệu"),
          TextCellValue("Chưa có dữ liệu"),
          TextCellValue("Chưa có dữ liệu"),
          TextCellValue("Chưa có dữ liệu")
        ]);
      } else {
        var folderSheet = excel['Folder Information'];
        folderSheet.appendRow([
          TextCellValue("Tên Thư Mục"),
          TextCellValue("Tổng Số Task"),
          TextCellValue("Task Quá Hạn"),
          TextCellValue("Task Hôm Nay"),
          TextCellValue("Task Đã Hoàn Thành")
        ]);
        folderSheet.appendRow([
          TextCellValue(
              lateTasks.map((toElement) => toElement.title) as String),
          TextCellValue(lateTasks.length.toString()),
          TextCellValue(todayTasks.length.toString()),
          TextCellValue(doneTasks.length.toString())
        ]);

        var taskSheet = excel['Tasks'];
        taskSheet.appendRow([
          TextCellValue("Tiêu Đề"),
          TextCellValue("Ngày"),
          TextCellValue("Giờ"),
          TextCellValue("Trạng Thái"),
          TextCellValue("Ghi Chú"),
          TextCellValue("Thư Mục")
        ]);

        final allTasks = [...lateTasks, ...todayTasks, ...doneTasks];
        for (var task in allTasks) {
          taskSheet.appendRow([
            TextCellValue(task.title),
            TextCellValue(task.date.toString().split(' ')[0]),
            TextCellValue(task.time),
            TextCellValue(task.isDone ? 'Đã Hoàn Thành' : 'Chưa Hoàn Thành'),
            TextCellValue(task.note ?? ''),
            TextCellValue(
                lateTasks.map((toElement) => toElement.title) as String)
          ]);
        }
      }

      Uint8List? excelBytes = Uint8List.fromList(excel.save() ?? []);
      final taskTitle = lateTasks.map((toElement) => toElement.title);

      if (excelBytes.isNotEmpty) {
        String fileName = '${taskTitle.isNotEmpty ? taskTitle : "tasks"}_tasks';
        if (!fileName.endsWith('.xlsx')) {
          fileName += '.xlsx';
        }

        await FileSaver.instance.saveFile(
            name: fileName,
            bytes: excelBytes,
            ext: 'xlsx',
            mimeType: MimeType.microsoftExcel);

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xuất Task thành công')));
      } else {
        throw Exception('Không thể tạo file Excel');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Xuất thất bại: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _isOpen ? 1.0 : 0.0,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _closeMenu,
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(
          height: 80,
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 100),
                left: _isOpen ? 0 : -100,
                top: 0,
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: 80,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 48),
                        Visibility(
                          visible: _isOpen,
                          child: _buildActionButton(
                            icon: Icons.create,
                            label: 'Create',
                            onTap: () async {
                              _closeMenu();
                              final result = await showDialog<FolderData>(
                                context: context,
                                builder: (context) =>
                                    const CreateFolderDialog(),
                              );

                              if (result != null) {
                                widget.onFolderCreated(result);
                              }
                            },
                          ),
                        ),
                        if (kIsWeb || PlatformUtil.isDesktopPlatform) ...[
                          Visibility(
                            visible: _isOpen,
                            child: _buildActionButton(
                              icon: Icons.upload_file,
                              label: 'Import Excel',
                              onTap: _importExcel,
                            ),
                          ),
                          Visibility(
                            visible: _isOpen,
                            child: _buildActionButton(
                              icon: Icons.upload_file,
                              label: 'Export Excel',
                              onTap: _exportExcel,
                            ),
                          ),
                        ],
                        Visibility(
                          visible: _isOpen,
                          child: _buildActionButton(
                            icon: Icons.settings,
                            label: 'Setting',
                            onTap: _closeMenu,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                child: GestureDetector(
                  onTap: _toggleMenu,
                  child: Container(
                    width: 100,
                    height: 64,
                    padding: const EdgeInsets.all(8.0),
                    color: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMenuLine(20),
                        const SizedBox(height: 5),
                        _buildMenuLine(15),
                        const SizedBox(height: 5),
                        _buildMenuLine(20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuLine(double width) {
    return Container(
      width: width,
      height: 2,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
