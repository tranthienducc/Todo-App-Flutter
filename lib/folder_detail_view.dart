import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todolist_app/create_task_dialog.dart';
import 'package:todolist_app/main.dart';
import 'package:todolist_app/task_status.dart';

import './task.dart';
import 'excel_service.dart';

class FolderDetailView extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int tasks;
  final List<FolderData> folderLists;
  final int totalTasks;
  final Function saveFolders;
  final Function loadFolders;
  final Function editFolder;
  final ExcelService? excelService;
  final FolderData folder;

  const FolderDetailView({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.tasks,
    required this.folderLists,
    required this.totalTasks,
    required this.saveFolders,
    required this.loadFolders,
    required this.editFolder,
    required this.folder,
    this.excelService,
  });

  get currentFolders => null;

  @override
  State<FolderDetailView> createState() => _FolderDetailViewState();
}

class _FolderDetailViewState extends State<FolderDetailView> {
  late List<Task> lateTasks;
  late List<Task> todayTasks;
  late List<Task> doneTasks;
  late String title;
  late IconData icon;
  late Color color;
  late FolderData folder;
  List<String> folders = [];
  late List<String> _availableFolderTitles = [];
  late int totalTasks = 0;
  late int tasks = 0;
  late final Function editFolder;

  @override
  void initState() {
    super.initState();
    lateTasks = [];
    todayTasks = [];
    doneTasks = [];
    title = widget.title;
    icon = widget.icon;
    color = widget.color;
    folder = widget.folder;
    totalTasks = widget.tasks;
    _loadTasks();
    _availableFolderTitles = widget.folderLists
        .where((folder) => folder.title != widget.title)
        .map((folder) => folder.title)
        .toList();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString('tasks_${widget.title}');

    if (tasksJson != null) {
      final List<dynamic> decodedTasks = json.decode(tasksJson);
      final List<Task> allTasks =
          decodedTasks.map((tasksJson) => Task.fromJson(tasksJson)).toList();

      setState(() {
        lateTasks = allTasks
            .where((task) => task.date.isBefore(DateTime.now()) && !task.isDone)
            .toList();
        todayTasks = allTasks
            .where(
                (task) => !task.date.isBefore(DateTime.now()) && !task.isDone)
            .toList();
        doneTasks = allTasks.where((task) => task.isDone).toList();
        totalTasks = allTasks.length;
      });
    }
  }

  void _moveTaskToFolder(Task task, FolderData targetFolder) async {
    setState(() {
      lateTasks.remove(task);
      todayTasks.remove(task);
      doneTasks.remove(task);
      _saveTasks();
    });

    final prefs = await SharedPreferences.getInstance();
    final String? targetTasksJson =
        prefs.getString('tasks_${targetFolder.title}');
    List<Task> targetTasks = [];

    if (targetTasksJson != null) {
      final List<dynamic> decodedTasks = json.decode(targetTasksJson);
      targetTasks =
          decodedTasks.map((taskJson) => Task.fromJson(taskJson)).toList();
    }

    targetTasks.add(task);
    await prefs.setString(
      'tasks_${targetFolder.title}',
      json.encode(targetTasks.map((t) => t.toJson()).toList()),
    );

    int newTaskCount = targetTasks.length;
    final updatedTargetFolder = targetFolder.copyWith(tasks: newTaskCount);

    List<FolderData> folderDataList = widget.folderLists;
    int folderIndex =
        folderDataList.indexWhere((f) => f.title == targetFolder.title);

    if (folderIndex != -1) {
      folderDataList[folderIndex] = updatedTargetFolder;
      await prefs.setString('folders',
          json.encode(folderDataList.map((f) => f.toJson()).toList()));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Task đã được di chuyển tới thư mục "${targetFolder.title}".')),
    );
  }

  void _showMoveTaskDialog(Task task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Move Task To'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.folderLists
                  .where((folder) => folder.title != widget.title)
                  .map((folder) => ListTile(
                        title: Text(folder.title),
                        onTap: () {
                          Navigator.pop(context);
                          _moveTaskToFolder(task, folder);
                        },
                      ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final allTasks = [...lateTasks, ...todayTasks, ...doneTasks];

    final tasksJson =
        json.encode(allTasks.map((task) => task.toJson()).toList());
    await prefs.setString('tasks_${widget.title}', tasksJson);

    int newTaskCount = allTasks.length;

    final updatedFolder = widget.folder.copyWith(tasks: newTaskCount);

    final foldersJson = prefs.getString('folders') ?? '[]';
    final List<dynamic> folderList = jsonDecode(foldersJson);

    List<FolderData> folderDataList =
        folderList.map((folder) => FolderData.fromJson(folder)).toList();

    int folderIndex = folderDataList.indexWhere((f) => f.title == widget.title);
    if (folderIndex != -1) {
      folderDataList[folderIndex] = updatedFolder;
      await prefs.setString('folders',
          jsonEncode(folderDataList.map((f) => f.toJson()).toList()));
    }
  }

  @override
  void dispose() {
    Navigator.pop(context, totalTasks);
    super.dispose();
  }

  void _handleTaskToggle(
      Task task, List<Task> sourceList, List<Task> targetList) {
    setState(() {
      sourceList.remove(task);
      task.isDone = !task.isDone;
      targetList.add(task);
      _saveTasks();
    });
  }

  void _addNewTask(Map<String, dynamic> taskData) {
    final now = DateTime.now();
    final taskDate = taskData['date'] as DateTime;
    final taskTime = taskData['time'] as TimeOfDay;

    void _updateTotalTasks() {
      int newTotalTasks =
          widget.folderLists.fold(0, (sum, folder) => sum + folder.tasks);

      widget.saveFolders(widget.folderLists);

      Navigator.pop(context, newTotalTasks);
    }

    final task = Task(
      title: taskData['task'],
      time: taskTime.format(context),
      isDone: false,
      note: taskData['note'] ?? '',
      status: taskData['status'] ?? TaskStatus.pending,
      date: taskDate,
      createdAt: DateTime.now(),
    );

    setState(() {
      if (taskDate.isBefore(now)) {
        lateTasks.add(task);
      } else {
        todayTasks.add(task);
      }
      _saveTasks();
      _updateTotalTasks();
    });

    widget.currentFolders.tasks++;
    widget.saveFolders(widget.folderLists);
  }

  void _editTask(Task task) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateTaskDialog(task),
        fullscreenDialog: true,
      ),
    );
    if (result != null) {
      setState(() {
        lateTasks.removeWhere((t) => t.title == task.title);
        todayTasks.removeWhere((t) => t.title == task.title);
        doneTasks.removeWhere((t) => t.title == task.title);

        final editedTask = Task(
          title: result['task'],
          time: result['time'].format(context),
          isDone: task.isDone,
          note: result['note'] ?? '',
          status: result['status'] ?? TaskStatus.pending,
          date: result['date'],
          updatedAt: DateTime.now(),
        );
        if (editedTask.date.isBefore(DateTime.now()) && !editedTask.isDone) {
          lateTasks.add(editedTask);
        } else if (!editedTask.isDone) {
          todayTasks.add(editedTask);
        } else {
          doneTasks.add(editedTask);
        }
        _saveTasks();
      });
    }
  }

  void _deleteTask(Task task) async {
    setState(() {
      lateTasks.removeWhere((t) => t.title == task.title);
      todayTasks.removeWhere((t) => t.title == task.title);
      doneTasks.removeWhere((t) => t.title == task.title);

      widget.currentFolders.tasks--;
      widget.saveFolders(widget.folderLists);
    });
    await _saveTasks();
  }

  Future<void> _deleteFolder() async {
    final prefs = await SharedPreferences.getInstance();

    String? tasksJson = prefs.getString('tasks_${folder.title}');
    if (tasksJson != null && tasksJson.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Thư mục "${folder.title}" còn chứa task. Vui lòng xoá hết task trước khi xoá thư mục.',
          ),
        ),
      );
      return;
    }

    await prefs.remove('tasks_${folder.title}');

    String? foldersJson = prefs.getString('folders');
    if (foldersJson != null) {
      List<dynamic> folderList = json.decode(foldersJson);

      folderList.removeWhere((f) => f['title'] == folder.title);

      await prefs.setString('folders', json.encode(folderList));
    }

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã xóa thư mục "${folder.title}"')),
    );
    await _loadTasks();
    await widget.loadFolders();
  }

  Future<void> _exportExcel() async {
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
        TextCellValue(widget.title),
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
          TextCellValue(widget.title),
        ]);
      }

      Uint8List? excelBytes = Uint8List.fromList(excel.save() ?? []);

      if (excelBytes.isNotEmpty) {
        String fileName = '${widget.title}_tasks';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.color,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (String result) async {
              if (result == 'edit') {
                await widget.editFolder(widget.folder);
                setState(() {
                  title = widget.folder.title;
                  icon = widget.folder.icon;
                  color = widget.folder.color;
                });
                Navigator.pop(context, true);
              } else if (result == 'delete') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Folder'),
                    content: const Text(
                        'Are you sure you want to delete this folder?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _deleteFolder();
                        },
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              } else if (result == 'exportExcel') {
                await _exportExcel();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('Edit Folder'),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete Folder'),
                ),
                const PopupMenuItem<String>(
                  value: 'exportExcel',
                  child: Row(
                    children: [
                      Icon(Icons.file_download),
                      SizedBox(width: 8),
                      Text('Export to Excel'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  folder.icon,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: 10),
                Text(
                  folder.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${totalTasks} Tasks',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSection('Late', lateTasks),
                  _buildSection('Today', todayTasks),
                  _buildSection('Done', doneTasks),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CreateTaskDialog(null),
              fullscreenDialog: true,
            ),
          );

          if (result != null) {
            _addNewTask(result as Map<String, dynamic>);
          }
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSection(String title, List<Task> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: title == 'Done' ? widget.color : Colors.black54,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        ...tasks.map((task) => _buildTask(task, title)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTask(Task task, String section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: task.isDone ? widget.color : Colors.black87,
                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  task.updatedAt != null
                      ? 'Last Edited: ${task.updatedAt!.toLocal()}'
                      : 'Created: ${task.createdAt?.toLocal()}',
                  style: TextStyle(
                    fontSize: 14,
                    color: task.isDone ? widget.color : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.move_to_inbox),
            color: widget.color,
            onPressed: () => _showMoveTaskDialog(task),
          ),
          IconButton(
              icon: const Icon(Icons.edit),
              color: widget.color,
              onPressed: () {
                _editTask(task);
              }),
          IconButton(
            icon: const Icon(Icons.delete),
            color: widget.color,
            onPressed: () {
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) => AlertDialog(
                  title: const Text('Delete Task'),
                  content:
                      const Text('Are you sure you want to delete this task?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        _deleteTask(task);
                        Navigator.of(dialogContext).pop();
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          ),
          Checkbox(
            value: task.isDone,
            onChanged: (value) {
              if (task.isDone) {
                if (section == 'Done') {
                  _handleTaskToggle(
                    task,
                    doneTasks,
                    task.time.contains('April') ? lateTasks : todayTasks,
                  );
                }
              } else {
                if (section == 'Late' || section == 'Today') {
                  _handleTaskToggle(
                    task,
                    section == 'Late' ? lateTasks : todayTasks,
                    doneTasks,
                  );
                }
              }
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            activeColor: widget.color,
          ),
        ],
      ),
    );
  }
}

extension on String {
  IconData? get icon => null;

  get color => null;

  String? get title => null;
}
