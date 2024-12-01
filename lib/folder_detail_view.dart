import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todolist_app/create_task_dialog.dart';
import 'package:todolist_app/excel_helper.dart';
import 'package:todolist_app/main.dart';
import 'package:todolist_app/platform_utils.dart';
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
  late final TaskStatus _status = TaskStatus.TODO;
  final Map<TaskStatus, Color> statusColors = {
    TaskStatus.TODO: Colors.blue,
    TaskStatus.INPROGRESS: Colors.orange,
    TaskStatus.PENDING: Colors.purple,
    TaskStatus.DONE: Colors.green,
  };

  void _updateTaskLists() {
    final now = DateTime.now();

    setState(() {
      todayTasks.removeWhere((task) {
        if (task.date.isBefore(DateTime(now.year, now.month, now.day))) {
          lateTasks.add(task);
          return true;
        }
        return false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    lateTasks = [];
    todayTasks = [];
    doneTasks = [];
    _loadTasks().then((_) => _updateTaskLists());
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
    List<Task> allTasks = [];

    if (title == "All") {
      for (var folder in widget.folderLists) {
        final String? tasksJson = prefs.getString('tasks_${folder.title}');
        if (tasksJson != null) {
          final List<dynamic> decodedTasks = json.decode(tasksJson);
          allTasks.addAll(
              decodedTasks.map((taskJson) => Task.fromJson(taskJson)).toList());
        }
      }
    } else {
      final String? tasksJson = prefs.getString('tasks_${widget.title}');
      if (tasksJson != null) {
        final List<dynamic> decodedTasks = json.decode(tasksJson);
        allTasks =
            decodedTasks.map((taskJson) => Task.fromJson(taskJson)).toList();
      }
    }

    setState(() {
      lateTasks = allTasks
          .where((task) => task.date.isBefore(DateTime.now()) && !task.isDone)
          .toList();
      todayTasks = allTasks
          .where((task) => !task.date.isBefore(DateTime.now()) && !task.isDone)
          .toList();
      doneTasks = allTasks.where((task) => task.isDone).toList();
      totalTasks = allTasks.length;
    });
  }

  void _moveTaskToFolder(Task task, FolderData targetFolder) async {
    setState(() {
      lateTasks.remove(task);
      todayTasks.remove(task);
      doneTasks.remove(task);
      saveTasks();
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

  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final allTasks = [...lateTasks, ...todayTasks, ...doneTasks];

    final tasksJson =
        json.encode(allTasks.map((task) => task.toJson()).toList());
    await prefs.setString('tasks_${widget.title}', tasksJson);

    int newTaskCount = allTasks.length;

    int folderIndex =
        widget.folderLists.indexWhere((folder) => folder.title == widget.title);
    if (folderIndex != -1) {
      final updatedFolder =
          widget.folderLists[folderIndex].copyWith(tasks: newTaskCount);
      widget.folderLists[folderIndex] = updatedFolder;

      await prefs.setString('folders',
          jsonEncode(widget.folderLists.map((f) => f.toJson()).toList()));
      widget.saveFolders(widget.folderLists);
    }
  }

  @override
  void dispose() {
    Navigator.pop(context, widget.folder.tasks);
    super.dispose();
  }

  void _handleTaskToggle(
      Task task, List<Task> sourceList, List<Task> targetList) {
    setState(() {
      sourceList.remove(task);
      task.isDone = !task.isDone;
      targetList.add(task);
      saveTasks();
    });
  }

  void _addNewTask(Map<String, dynamic> taskData) {
    final taskDate = taskData['date'] as DateTime;
    final taskTime = taskData['time'] as TimeOfDay;

    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: taskData['task'],
      time: taskTime.format(context),
      isDone: false,
      note: taskData['note'] ?? '',
      status: taskData['status'] ?? TaskStatus.PENDING,
      date: taskDate,
      createdAt: DateTime.now(),
    );

    setState(() {
      todayTasks.add(task);
      totalTasks = lateTasks.length + todayTasks.length + doneTasks.length;

      int folderIndex = widget.folderLists
          .indexWhere((folder) => folder.title == widget.title);

      if (folderIndex != -1) {
        final updatedFolder =
            widget.folderLists[folderIndex].copyWith(tasks: totalTasks);
        widget.folderLists[folderIndex] = updatedFolder;

        widget.saveFolders(widget.folderLists);
      }

      saveTasks();
    });
  }

  void _deleteTask(Task task) {
    setState(() {
      lateTasks.removeWhere((t) => t.id == task.id);
      todayTasks.removeWhere((t) => t.id == task.id);
      doneTasks.removeWhere((t) => t.id == task.id);

      totalTasks = lateTasks.length + todayTasks.length + doneTasks.length;

      int folderIndex = widget.folderLists
          .indexWhere((folder) => folder.title == widget.title);
      if (folderIndex != -1) {
        final updatedFolder =
            widget.folderLists[folderIndex].copyWith(tasks: totalTasks);
        widget.folderLists[folderIndex] = updatedFolder;

        widget.saveFolders(widget.folderLists);
      }

      saveTasks();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã xóa task "${task.title}"')),
    );
  }

  void _editTask(Task task) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateTaskDialog(task, _status, statusColors),
        fullscreenDialog: true,
      ),
    );

    if (result != null) {
      setState(() {
        lateTasks.removeWhere((t) => t.id == task.id);
        todayTasks.removeWhere((t) => t.id == task.id);
        doneTasks.removeWhere((t) => t.id == task.id);

        final editedTask = Task(
          id: task.id,
          title: result['task'],
          time: result['time'].format(context),
          isDone: task.isDone,
          note: result['note'] ?? '',
          status: result['status'] ?? TaskStatus.PENDING,
          date: result['date'],
          createdAt: task.createdAt,
          updatedAt: DateTime.now(),
        );

        if (!editedTask.isDone) {
          todayTasks.add(editedTask);
        } else {
          doneTasks.add(editedTask);
        }

        saveTasks();
      });
    }
  }

  Future<void> _deleteFolder() async {
    final int totalTasksInFolder =
        lateTasks.length + todayTasks.length + doneTasks.length;

    if (totalTasksInFolder > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Thư mục "${folder.title}" còn chứa task. Vui lòng xoá hết task trước khi xoá thư mục.',
          ),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();

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

  void _sortTasksByStatus(List<Task> tasks) {
    tasks.sort((a, b) => a.status.index.compareTo(b.status.index));
  }

  void _sortTasksByUpdateTime(List<Task> tasks) {
    tasks.sort((a, b) {
      final aUpdatedAt = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bUpdatedAt = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bUpdatedAt.compareTo(aUpdatedAt);
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile =
        MediaQuery.of(context).size.width < 600; // Kiểm tra nếu là mobile
    bool isDesktop = PlatformUtil.isDesktopPlatform; // Kiểm tra nếu là desktop

    return Scaffold(
      backgroundColor: widget.color,
      appBar: (widget.title == 'All' && isMobile)
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ))
          : AppBar(
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
                      if (widget.title == 'All') {
                        await exportTasksToExcel(
                          context: context,
                          folderTitle: widget.title,
                          totalTasks: totalTasks,
                          lateTasks: lateTasks,
                          todayTasks: todayTasks,
                          doneTasks: doneTasks,
                        );
                      }
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    List<PopupMenuEntry<String>> menuItems = [];

                    // Chỉ hiển thị "Export to Excel" nếu là desktop và folder là "All"
                    if (widget.title == 'All' && isDesktop) {
                      menuItems.add(
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
                      );
                    } else if (widget.title != 'All') {
                      menuItems.addAll([
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Text('Edit Folder'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete Folder'),
                        ),
                      ]);
                    }

                    return menuItems;
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
              builder: (context) => const CreateTaskDialog(
                null,
                TaskStatus.TODO,
                {
                  TaskStatus.TODO: Colors.blue,
                  TaskStatus.INPROGRESS: Colors.orange,
                  TaskStatus.PENDING: Colors.purple,
                  TaskStatus.DONE: Colors.green,
                },
              ),
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
    if (title == 'Today') {
      _updateTaskLists();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: title == 'Done' ? widget.color : Colors.black54,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort, color: Colors.black54),
              onSelected: (String result) {
                if (result == 'sortByStatus') {
                  setState(() {
                    _sortTasksByStatus(tasks);
                  });
                } else if (result == 'sortByUpdateTime') {
                  setState(() {
                    _sortTasksByUpdateTime(tasks);
                  });
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem<String>(
                    value: 'sortByStatus',
                    child: Text('Sort by Status'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'sortByUpdateTime',
                    child: Text('Sort by Update Time'),
                  ),
                ];
              },
            ),
          ],
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Status: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: statusColors[task.status] ?? Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      task.status.toString().split('.').last,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
                Text(
                  task.updatedAt != null
                      ? 'Last Edit: ${DateFormat('hh:mm a').format(task.updatedAt!)}'
                      : 'No edits yet',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
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
                builder: (context) => AlertDialog(
                  title: const Text('Delete Task'),
                  content:
                      const Text('Are you sure you want to delete this task?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        _deleteTask(task);
                        Navigator.of(context).pop();
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
