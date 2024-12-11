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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FolderDetailView extends StatefulWidget {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final int tasks;
  List<FolderData> folderLists;
  int totalTasks;
  final Function saveFolders;
  final Function loadFolders;
  final Function editFolder;
  final Function saveTasks;
  final ExcelService? excelService;
  FolderData folder;
  List<Task> lateTasks;
  List<Task> todayTasks;
  List<Task> doneTasks;
  List<Task> taskLists;
  FolderData? selectedFolder;
  final Function? selectFolder;

  FolderDetailView({
    super.key,
    this.selectedFolder,
    required this.selectFolder,
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.tasks,
    required this.folderLists,
    required this.totalTasks,
    required this.saveFolders,
    required this.saveTasks,
    required this.loadFolders,
    required this.taskLists,
    required this.editFolder,
    required this.folder,
    this.lateTasks = const [],
    this.todayTasks = const [],
    this.doneTasks = const [],
    this.excelService,
  });

  get currentFolders => null;

  @override
  State<FolderDetailView> createState() => _FolderDetailViewState();
}

class _FolderDetailViewState extends State<FolderDetailView> {
  late String id;
  late String title;
  late IconData icon;
  late Color color;
  late FolderData folder;
  List<String> folders = [];
  late List<String> _availableFolderTitles = [];
  late int totalTasks = 0;
  late int tasks = 0;
  late List<Task> taskLists = [];

  late final Function editFolder;
  late final TaskStatus _status = TaskStatus.TODO;
  final Map<TaskStatus, Color> statusColors = {
    TaskStatus.TODO: Colors.blue,
    TaskStatus.INPROGRESS: Colors.orange,
    TaskStatus.PENDING: Colors.purple,
    TaskStatus.DONE: Colors.green,
  };

  @override
  void initState() {
    super.initState();
    _loadTasks().then((_) {
      _organizeTasks();
      _updateTaskLists(widget.folder);
    });
    id = widget.id;
    title = widget.title;
    icon = widget.icon;
    color = widget.color;
    folder = widget.folder;
    totalTasks = widget.tasks;
    taskLists = widget.taskLists;
    widget.loadFolders();

    _availableFolderTitles = widget.folderLists
        .where((folder) => folder.id != widget.id)
        .map((folder) => folder.title)
        .toList();
  }

  void _organizeTasks() {
    setState(() {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      widget.lateTasks.clear();
      widget.todayTasks.clear();
      widget.doneTasks.clear();

      for (var task in widget.taskLists) {
        task.isDone = task.status == TaskStatus.DONE;

        if (task.isDone) {
          widget.doneTasks.add(task);
        } else {
          if (task.date.isBefore(today)) {
            widget.lateTasks.add(task);
          } else if (task.date.year == today.year &&
              task.date.month == today.month &&
              task.date.day == today.day) {
            widget.todayTasks.add(task);
          }
        }
      }
    });
  }

  void _updateTaskLists(FolderData? folder) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (folder != null) {
      setState(() {
        widget.taskLists = folder.taskLists ?? [];
        _organizeTasks();
      });
    }
  }

  Future<void> _loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Task> allTasks = [];

      if (widget.title == "All") {
        allTasks = widget.folderLists
            .expand((folder) {
              final folderId = folder.id;
              final String? tasksJson = prefs.getString('tasks_$folderId');
              if (tasksJson != null) {
                final List<dynamic> decodedTasks = json.decode(tasksJson);
                return decodedTasks.map((taskJson) => Task.fromJson(taskJson));
              }
              return <Task>[];
            })
            .toList()
            .cast<Task>();
      } else {
        final String? tasksJson = prefs.getString('tasks_${widget.folder.id}');
        if (tasksJson != null) {
          final List<dynamic> decodedTasks = json.decode(tasksJson);
          allTasks =
              decodedTasks.map((taskJson) => Task.fromJson(taskJson)).toList();
        }
      }

      setState(() {
        widget.taskLists = allTasks;
        widget.totalTasks = allTasks.length;
      });

      _organizeTasks();
    } catch (e) {
      debugPrint("Error loading tasks: $e");
    }
  }

  Future<void> _moveTaskToFolder(FolderData targetFolder, Task task) async {
    try {
      FolderData allFolder = widget.folderLists.firstWhere(
        (folder) => folder.title == "All",
        orElse: () => widget.folder,
      );

      FolderData sourceFolder = widget.folder;

      if (sourceFolder.id != allFolder.id) {
        setState(() {
          sourceFolder.taskLists?.removeWhere((t) => t.id == task.id);
          sourceFolder = sourceFolder.copyWith(
            taskLists: sourceFolder.taskLists,
            tasks: sourceFolder.taskLists?.length ?? 0,
          );
        });
        await widget.saveTasks(sourceFolder);
      }

      if (targetFolder.id != sourceFolder.id) {
        setState(() {
          targetFolder.taskLists ??= [];
          targetFolder.taskLists?.removeWhere((t) => t.id == task.id);
          targetFolder.taskLists?.add(task);
          targetFolder = targetFolder.copyWith(
            taskLists: targetFolder.taskLists,
            tasks: targetFolder.taskLists?.length ?? 0,
          );
        });
        await widget.saveTasks(targetFolder);
      }

      if (allFolder.id != targetFolder.id && allFolder.id != sourceFolder.id) {
        setState(() {
          allFolder.taskLists ??= [];
          allFolder.taskLists?.removeWhere((t) => t.id == task.id);
          if (shouldAddTaskToAllFolder(task, targetFolder)) {
            allFolder.taskLists?.add(task);
          }
          allFolder = allFolder.copyWith(
            taskLists: allFolder.taskLists,
            tasks: allFolder.taskLists?.length ?? 0,
          );
        });
        await widget.saveTasks(allFolder);
      }

      final updatedFolders = widget.folderLists.map((folder) {
        if (folder.id == sourceFolder.id) return sourceFolder;
        if (folder.id == targetFolder.id) return targetFolder;
        if (folder.id == allFolder.id) return allFolder;
        return folder;
      }).toList();

      await widget.saveFolders(updatedFolders);

      await _loadTasks();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.taskHasbeenMove(targetFolder.title),
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error moving task: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không thể di chuyển task")),
      );
    }
  }

  bool shouldAddTaskToAllFolder(Task task, FolderData targetFolder) {
    return targetFolder.title == "All";
  }

  void _showMoveTaskDialog(Task task) {
    final availableFolders = widget.folderLists
        .where((folder) =>
            folder.id != task.existingFolders?.id &&
            folder.id != widget.folder.id &&
            folder.title != 'All')
        .toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.moveTaskToFolder),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: availableFolders.isNotEmpty
                  ? availableFolders
                      .map((folder) => ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                folder.icon,
                                color: Theme.of(context).primaryColor,
                                size: 24,
                              ),
                            ),
                            title: Text(folder.title),
                            onTap: () {
                              Navigator.pop(context);
                              _moveTaskToFolder(folder, task);
                            },
                          ))
                      .toList()
                  : [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'No folder found',
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    Navigator.pop(context, widget.folder.tasks);
    super.dispose();
  }

  void _handleTaskToggle(Task task, bool? value) async {
    if (value == null) return;

    if (value) {
      task.isDone = true;
      if (task.status != TaskStatus.DONE) {
        task.originalStatus = task.status;
      }
      task.status = TaskStatus.DONE;

      widget.todayTasks.remove(task);
      if (!widget.doneTasks.contains(task)) widget.doneTasks.add(task);
    } else {
      task.isDone = false;
      task.status = task.originalStatus ?? TaskStatus.TODO;

      widget.doneTasks.remove(task);
      if (!widget.todayTasks.contains(task)) widget.todayTasks.add(task);
    }

    setState(() {
      _organizeTasks();
    });

    await widget.saveTasks(widget.folder);
    await widget.saveFolders(widget.folderLists);
  }

  // void _addNewTask(Map<String, dynamic> taskData) {
  //   final taskDate = taskData['date'] as DateTime;
  //   final taskTime = taskData['time'] as TimeOfDay;

  //   final task = Task(
  //     id: DateTime.now().millisecondsSinceEpoch.toString(),
  //     title: taskData['task'],
  //     time: taskTime.format(context),
  //     isDone: false,
  //     note: taskData['note'] ?? '',
  //     status: taskData['status'] ?? TaskStatus.PENDING,
  //     date: taskDate,
  //     createdAt: DateTime.now(),
  //   );

  //   setState(() {
  //     todayTasks.add(task);
  //     totalTasks = lateTasks.length + todayTasks.length + doneTasks.length;

  //     int folderIndex = widget.folderLists
  //         .indexWhere((folder) => folder.title == widget.title);

  //     if (folderIndex != -1) {
  //       final updatedFolder =
  //           widget.folderLists[folderIndex].copyWith(tasks: totalTasks);
  //       widget.folderLists[folderIndex] = updatedFolder;

  //       widget.saveFolders(widget.folderLists);
  //     }

  //     widget.saveTasks();
  //   });
  // }

  void _deleteTask(Task task) async {
    final allFolder =
        widget.folderLists.firstWhere((folder) => folder.title == "All");

    setState(() {
      widget.taskLists.removeWhere((t) => t.id == task.id);

      for (var i = 0; i < widget.folderLists.length; i++) {
        var folder = widget.folderLists[i];

        folder.taskLists?.removeWhere((t) => t.id == task.id);

        widget.folderLists[i] = folder.copyWith(
            taskLists: folder.taskLists, tasks: folder.taskLists?.length ?? 0);
      }

      _organizeTasks();
    });

    await widget.saveTasks(widget.folder);
    await widget.saveTasks(allFolder);
    await widget.saveFolders(widget.folderLists);

    if (mounted) {
      setState(() {
        widget.totalTasks = widget.taskLists.length;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.deleteTasksSuccess(task.title),
        ),
      ),
    );
  }

  void _editTask(Task task) async {
    final currentFolder = widget.folderLists.firstWhere(
      (folder) =>
          folder.title != "All" &&
          folder.taskLists!.any((t) => t.id == task.id),
      orElse: () => widget.folder,
    );

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateTaskDialog(
          existingTask: task,
          status: task.status,
          statusColors: statusColors,
          existingFolders: widget.folderLists,
          selectedFolder: currentFolder,
          selectFolder: (context) async {
            await widget.selectFolder!(context);
          },
        ),
        fullscreenDialog: true,
      ),
    );

    if (result != null) {
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

      final allFolderIndex =
          widget.folderLists.indexWhere((folder) => folder.title == "All");
      final currentFolderIndex = widget.folderLists.indexOf(currentFolder);

      setState(() {
        if (currentFolderIndex != -1) {
          final taskIndex = widget.folderLists[currentFolderIndex].taskLists!
              .indexWhere((t) => t.id == task.id);
          if (taskIndex != -1) {
            widget.folderLists[currentFolderIndex].taskLists![taskIndex] =
                editedTask;
          }
        }

        if (allFolderIndex != -1) {
          final allFolder = widget.folderLists[allFolderIndex];
          final taskIndex =
              allFolder.taskLists!.indexWhere((t) => t.id == task.id);

          if (taskIndex != -1) {
            allFolder.taskLists![taskIndex] = editedTask;
          } else {
            allFolder.taskLists!.add(editedTask);
          }
        }

        widget.taskLists = widget.taskLists.map((t) {
          return t.id == task.id ? editedTask : t;
        }).toList();

        _organizeTasks();

        widget.totalTasks = widget.taskLists.length;
      });

      if (currentFolderIndex != -1) {
        await widget.saveTasks(widget.folderLists[currentFolderIndex]);
      }
      if (allFolderIndex != -1) {
        await widget.saveTasks(widget.folderLists[allFolderIndex]);
      }
      await widget.saveFolders(widget.folderLists);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.editFolderSuccess),
        ),
      );
    }
  }

  Future<void> _deleteFolder() async {
    final int totalTasksInFolder = widget.lateTasks.length +
        widget.todayTasks.length +
        widget.doneTasks.length;

    if (totalTasksInFolder > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.warningDelete(folder.title)),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('tasks_${folder.id}');

    String? foldersJson = prefs.getString('folders');
    List<dynamic> folderList = json.decode(foldersJson!);

    folderList.removeWhere((f) => f['id'] == folder.id);

    await prefs.setString('folders', json.encode(folderList));

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              AppLocalizations.of(context)!.deleteFolderSuccess(folder.title))),
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
    bool isMobile = MediaQuery.of(context).size.width < 600;
    bool isDesktop = PlatformUtil.isDesktopPlatform;
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
                        taskLists = widget.folder.taskLists!;
                      });
                      Navigator.pop(context, widget.folder);
                    } else if (result == 'delete') {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title:
                              Text(AppLocalizations.of(context)!.deleteFolder),
                          content: Text(AppLocalizations.of(context)!
                              .confirmDeleteFolder),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(AppLocalizations.of(context)!.cancel),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await _deleteFolder();
                              },
                              child: Text(AppLocalizations.of(context)!.delete),
                            ),
                          ],
                        ),
                      );
                    } else if (result == 'exportExcel') {
                      await exportTasksToExcel(
                        context: context,
                        folderTitle: widget.title,
                        totalTasks: totalTasks,
                        lateTasks: widget.lateTasks,
                        todayTasks: widget.todayTasks,
                        doneTasks: widget.doneTasks,
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    List<PopupMenuEntry<String>> menuItems = [];
                    if (widget.title == 'All' && isDesktop) {
                      menuItems.add(
                        PopupMenuItem<String>(
                          value: 'exportExcel',
                          child: Row(
                            children: [
                              const Icon(Icons.file_download),
                              const SizedBox(width: 8),
                              Text(AppLocalizations.of(context)!.exportExcel),
                            ],
                          ),
                        ),
                      );
                    } else if (widget.title != 'All') {
                      menuItems.addAll([
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Text(AppLocalizations.of(context)!.editFolder),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child:
                              Text(AppLocalizations.of(context)!.deleteFolder),
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
                  '$totalTasks ${AppLocalizations.of(context)!.tasks}',
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
                  _buildSection(
                      AppLocalizations.of(context)!.late, widget.lateTasks),
                  _buildSection(
                      AppLocalizations.of(context)!.today, widget.todayTasks),
                  _buildSection(
                      AppLocalizations.of(context)!.done, widget.doneTasks),
                ],
              ),
            ),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () async {
      //     final result = await Navigator.of(context).push(
      //       MaterialPageRoute(
      //         builder: (context) => const CreateTaskDialog(
      //           null,
      //           TaskStatus.TODO,
      //          const {
      //             TaskStatus.TODO: Colors.blue,
      //             TaskStatus.INPROGRESS: Colors.orange,
      //             TaskStatus.PENDING: Colors.purple,
      //             TaskStatus.DONE: Colors.green,
      //           },
      //         ),
      //         fullscreenDialog: true,
      //       ),
      //     );

      //     if (result != null) {
      //       _addNewTask(result as Map<String, dynamic>);
      //     }
      //   },
      //   backgroundColor: Colors.blue,
      //   child: const Icon(Icons.add),
      // ),
    );
  }

  Widget _buildSection(String title, List<Task> tasks) {
    if (title == AppLocalizations.of(context)!.late) {
      tasks = widget.lateTasks;
    } else if (title == AppLocalizations.of(context)!.today) {
      tasks = widget.todayTasks;
    } else if (title == AppLocalizations.of(context)!.done) {
      tasks = widget.doneTasks;
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
                color: title == AppLocalizations.of(context)!.done
                    ? widget.color
                    : Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort, color: Colors.black54),
              onSelected: (String result) {
                setState(() {
                  if (result == 'sortByStatus') {
                    _sortTasksByStatus(tasks);
                  } else if (result == 'sortByUpdateTime') {
                    _sortTasksByUpdateTime(tasks);
                  }
                });
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    value: 'sortByStatus',
                    child: Text(AppLocalizations.of(context)!.sortByStatus),
                  ),
                  PopupMenuItem<String>(
                    value: 'sortByUpdateTime',
                    child: Text(AppLocalizations.of(context)!.sortByUpdateTime),
                  ),
                ];
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        tasks.isNotEmpty
            ? Column(
                children: tasks.map((task) => _buildTask(task, title)).toList())
            : Text(
                AppLocalizations.of(context)!.emtyTask,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
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
                    Text(
                      AppLocalizations.of(context)!.status,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 2),
                      decoration: BoxDecoration(
                        color: statusColors[task.status] ?? Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      task.status.toString().split('.').last,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
                Text(
                  task.updatedAt != null
                      ? '${AppLocalizations.of(context)!.lastEdit} ${DateFormat('hh:mm a').format(task.updatedAt!)}'
                      : AppLocalizations.of(context)!.notEditYet,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (widget.title != "All")
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
                  title: Text(AppLocalizations.of(context)!.deleteTask),
                  content:
                      Text(AppLocalizations.of(context)!.confirmDeleteTask),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    TextButton(
                      onPressed: () {
                        _deleteTask(task);
                        Navigator.of(context).pop();
                      },
                      child: Text(AppLocalizations.of(context)!.delete),
                    ),
                  ],
                ),
              );
            },
          ),
          Checkbox(
            value: task.isDone,
            onChanged: (value) {
              _handleTaskToggle(task, value);
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
