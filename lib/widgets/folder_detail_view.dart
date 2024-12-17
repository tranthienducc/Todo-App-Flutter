import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todolist_app/classed/folder_data.dart';
import 'package:todolist_app/services/export_excel.dart';
import 'package:todolist_app/services/organize_tasks_function.dart';
import 'package:todolist_app/services/update_task_list_service.dart';
import 'package:todolist_app/utils/index.dart';
import 'package:todolist_app/widgets/create_task_dialog.dart';
import 'package:todolist_app/services/platform_utils.dart';
import 'package:todolist_app/utils/enum/enum.dart';
import 'package:todolist_app/widgets/task_section_widget.dart';

import '../classed/task.dart';
import '../services/excel_service.dart';
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
      OrganizeTasksService.organizeTasks(
        taskLists: widget.taskLists,
        lateTasks: widget.lateTasks,
        todayTasks: widget.todayTasks,
        doneTasks: widget.doneTasks,
        setState: setState,
      );
      UpdateTaskListService.updateTaskList(
          setState: setState,
          doneTasksWidget: widget.doneTasks,
          folder: widget.folder,
          lateTasksWidget: widget.lateTasks,
          taskListsWidget: widget.taskLists,
          todayTasksWidget: widget.todayTasks);
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

      OrganizeTasksService.organizeTasks(
        taskLists: widget.taskLists,
        lateTasks: widget.lateTasks,
        todayTasks: widget.todayTasks,
        doneTasks: widget.doneTasks,
        setState: setState,
      );
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

  void showMoveTaskDialog(Task task) {
    final availableFolders = widget.folderLists
        .where((folder) =>
            folder.id !=
                widget.folder.id && // Không hiển thị chính folder hiện tại
            folder.title != 'All') // Không hiển thị folder "All"
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

  void handleTaskToggle(Task task, bool? value) async {
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
      OrganizeTasksService.organizeTasks(
        taskLists: widget.taskLists,
        lateTasks: widget.lateTasks,
        todayTasks: widget.todayTasks,
        doneTasks: widget.doneTasks,
        setState: setState,
      );
    });

    await widget.saveTasks(widget.folder);
    await widget.saveFolders(widget.folderLists);
  }

  void deleteTask(Task task) async {
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

      OrganizeTasksService.organizeTasks(
        taskLists: widget.taskLists,
        lateTasks: widget.lateTasks,
        todayTasks: widget.todayTasks,
        doneTasks: widget.doneTasks,
        setState: setState,
      );
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

  void editTask(Task task) async {
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

        OrganizeTasksService.organizeTasks(
          taskLists: widget.taskLists,
          lateTasks: widget.lateTasks,
          todayTasks: widget.todayTasks,
          doneTasks: widget.doneTasks,
          setState: setState,
        );

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

  void handleSortTasks(String result, List<Task> tasks) {
    setState(() {
      if (result == 'sortByStatus') {
        sortTasksByStatus(tasks);
      } else if (result == 'sortByUpdateTime') {
        sortTasksByUpdateTime(tasks);
      }
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
                        taskLists: widget.taskLists,
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
                  buildSection(
                      title: AppLocalizations.of(context)!.late,
                      tasks: widget.lateTasks,
                      context: context,
                      lateTasksWidget: widget.lateTasks,
                      todayTasksWidget: widget.todayTasks,
                      doneTasksWidget: widget.doneTasks,
                      colorWidget: widget.color,
                      deleteTask: deleteTask,
                      editTask: editTask,
                      handleTaskToggle: handleTaskToggle,
                      statusColorsWidget: statusColors,
                      titleWidget: widget.title,
                      onSortTasks: handleSortTasks,
                      folderLists: widget.folderLists,
                      folderWidget: widget.folder,
                      saveTasks: widget.saveTasks,
                      showMoveTaskDialog: showMoveTaskDialog,
                      saveFolders: widget.saveFolders,
                      loadTasks: _loadTasks),
                  buildSection(
                      title: AppLocalizations.of(context)!.today,
                      tasks: widget.todayTasks,
                      context: context,
                      lateTasksWidget: widget.lateTasks,
                      todayTasksWidget: widget.todayTasks,
                      doneTasksWidget: widget.doneTasks,
                      colorWidget: widget.color,
                      deleteTask: deleteTask,
                      editTask: editTask,
                      handleTaskToggle: handleTaskToggle,
                      statusColorsWidget: statusColors,
                      titleWidget: widget.title,
                      onSortTasks: handleSortTasks,
                      folderLists: widget.folderLists,
                      folderWidget: widget.folder,
                      saveTasks: widget.saveTasks,
                      showMoveTaskDialog: showMoveTaskDialog,
                      saveFolders: widget.saveFolders,
                      loadTasks: _loadTasks),
                  buildSection(
                      title: AppLocalizations.of(context)!.done,
                      tasks: widget.doneTasks,
                      context: context,
                      lateTasksWidget: widget.lateTasks,
                      todayTasksWidget: widget.todayTasks,
                      doneTasksWidget: widget.doneTasks,
                      colorWidget: widget.color,
                      deleteTask: deleteTask,
                      editTask: editTask,
                      handleTaskToggle: handleTaskToggle,
                      statusColorsWidget: statusColors,
                      titleWidget: widget.title,
                      onSortTasks: handleSortTasks,
                      showMoveTaskDialog: showMoveTaskDialog,
                      folderLists: widget.folderLists,
                      folderWidget: widget.folder,
                      saveTasks: widget.saveTasks,
                      saveFolders: widget.saveFolders,
                      loadTasks: _loadTasks),
                ],
              ),
            ),
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
