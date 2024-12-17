import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todolist_app/classed/folder_data.dart';
import 'package:todolist_app/widgets/create_task_dialog.dart';
import 'package:todolist_app/classed/task.dart';
import 'package:todolist_app/utils/enum/enum.dart';
import 'package:todolist_app/utils/index.dart';
import 'package:todolist_app/widgets/create_folder_dialog.dart';
import 'package:todolist_app/widgets/emty_state_widget.dart';

import 'widgets/animated_menu_button.dart';
import 'widgets/folder_card.dart';
import 'widgets/folder_detail_view.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:todolist_app/l10n/l10n.dart';

Locale locale = const Locale('en');

class FolderListPage extends StatefulWidget {
  static final ValueNotifier<Locale> localeNotifier =
      ValueNotifier(const Locale('en'));

  static void setLocale(BuildContext context, Locale newLocale) async {
    localeNotifier.value = newLocale;
    await saveLocale(newLocale);
  }

  const FolderListPage({super.key});

  @override
  State<FolderListPage> createState() => _FolderListPageState();
}

class _FolderListPageState extends State<FolderListPage> {
  List<FolderData> _folderLists = [];
  late int totalTasks = 0;
  late List<Task> lateTasks = [];
  List<Task> todayTasks = [];
  late List<Task> doneTasks = [];
  FolderData? _selectedFolder;
  late List<Task> taskList = [];

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  void setLocale(Locale locale) {
    setState(() {
      locale = locale;
    });
  }

  Future<void> saveFolders(List<FolderData> folders) async {
    final prefs = await SharedPreferences.getInstance();

    final totalTasks = folders
        .where((folder) => folder.title != "All")
        .map((folder) => folder.tasks)
        .fold(0, (sum, tasks) => sum + tasks);

    final allFolderIndex =
        folders.indexWhere((folder) => folder.title == "All");
    if (allFolderIndex != -1) {
      folders[allFolderIndex] =
          folders[allFolderIndex].copyWith(tasks: totalTasks);
    }

    final folderJsonList = folders.map((folder) => folder.toJson()).toList();
    final jsonData = jsonEncode(folderJsonList);

    await prefs.setString('folders', jsonData);
    await prefs.setInt('totalTasks', totalTasks);

    setState(() {
      _folderLists = folders;
      this.totalTasks = totalTasks;
    });
  }

  Future<List<FolderData>> _fetchFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString('folders');
    List<FolderData> folderList = [];

    if (jsonData != null) {
      final List<dynamic> decodedData = jsonDecode(jsonData);
      folderList = decodedData
          .map((json) => FolderData.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    List<Task> allTasks = [];
    int totalTasks = 0;

    for (var folder in folderList) {
      if (folder.title != "All" && folder.taskLists != null) {
        allTasks.addAll(folder.taskLists!);
        totalTasks += folder.taskLists!.length;
      }
    }

    final index = folderList.indexWhere((folder) => folder.title == "All");

    if (index == -1) {
      folderList.add(FolderData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: "All",
        icon: Icons.folder,
        color: Colors.redAccent,
        tasks: totalTasks,
        taskLists: allTasks,
      ));
    } else {
      folderList[index] = folderList[index].copyWith(
        tasks: totalTasks,
        taskLists: allTasks,
      );
    }

    folderList.sort((a, b) {
      if (a.title == "All") return -1;
      if (b.title == "All") return 1;
      return 0;
    });

    return folderList;
  }

  Future<void> _loadFolders() async {
    final folders = await _fetchFolders();
    if (mounted) {
      setState(() {
        _folderLists = folders;
      });
    }
  }

  void _addNewFolder(FolderData newFolder) async {
    setState(() {
      _folderLists.add(newFolder);
      _folderLists.sort((a, b) {
        if (a.title == "All") return -1;
        if (b.title == "All") return 1;
        return 0;
      });
    });
    await saveFolders(_folderLists);
    _loadFolders();
  }

  void editFolder(FolderData updatedFolder) async {
    final result = await showDialog(
      context: context,
      builder: (context) => CreateFolderDialog(folderData: updatedFolder),
    );

    if (result != null && mounted) {
      setState(() {
        int index = _folderLists.indexWhere((f) => f.id == updatedFolder.id);
        if (index != -1) {
          _folderLists[index] = result.copyWith(
            taskLists: _folderLists[index].taskLists,
            tasks: _folderLists[index].taskLists?.length ?? 0,
          );
        }
      });
      await saveFolders(_folderLists);
    }
    await _loadFolders();
  }

  Future<void> saveTasks(FolderData folder) async {
    final prefs = await SharedPreferences.getInstance();
    final tasks = folder.taskLists ?? [];
    final tasksJson = json.encode(tasks.map((t) => t.toJson()).toList());
    await prefs.setString('tasks_${folder.id}', tasksJson);
  }

  void _addNewTask(Map<String, dynamic> taskData, FolderData folder) {
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
      existingFolders: folder,
    );

    setState(() {
      int folderIndex = _folderLists.indexWhere((f) => f.id == folder.id);
      if (folderIndex != -1) {
        final updatedTasks =
            List<Task>.from(_folderLists[folderIndex].taskLists ?? [])
              ..add(task);
        _folderLists[folderIndex] = folder.copyWith(
          taskLists: updatedTasks,
          tasks: updatedTasks.length,
        );
      }
    });

    saveTasks(folder);
    saveFolders(_folderLists);
  }

  Future<FolderData?> selectFolder(BuildContext context) async {
    final FolderData? selectedFolders = await showDialog<FolderData>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(
          AppLocalizations.of(context)!.selectFolder,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: _folderLists
            .where((folder) => folder.title != "All")
            .map((FolderData folder) {
          return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, folder),
              child: Row(
                children: [
                  Icon(
                    folder.icon,
                    color: folder.color,
                  ),
                  const SizedBox(width: 8),
                  Text(folder.title),
                ],
              ));
        }).toList(),
      ),
    );

    if (selectedFolders != null && mounted) {
      setState(() {
        _selectedFolder = selectedFolders;
      });
      await saveFolders(_folderLists);
      _loadFolders();
    }
    return selectedFolders;
  }

  void _openFolderDetail(FolderData folder) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FolderDetailView(
            id: folder.id,
            title: folder.title,
            icon: folder.icon,
            color: folder.color,
            folder: folder,
            tasks: folder.tasks,
            folderLists: _folderLists,
            saveTasks: saveTasks,
            loadFolders: _loadFolders,
            totalTasks: totalTasks,
            saveFolders: saveFolders,
            editFolder: editFolder,
            lateTasks: lateTasks,
            todayTasks: todayTasks,
            selectedFolder: _selectedFolder,
            selectFolder: selectFolder,
            taskLists: folder.taskLists ?? [],
            doneTasks: doneTasks),
      ),
    );

    if (result != null) {
      if (result is int) {
        setState(() {
          totalTasks = result;
        });
      }

      await _loadFolders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenType = getScreenType(context);

    return GestureDetector(
      onTap: () {},
      child: Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            backgroundColor: Colors.grey[100],
            leading: Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                );
              },
            ),
          ),
          drawer: AnimatedMenuButton(
            lateTasks: lateTasks,
            todayTasks: todayTasks,
            doneTasks: doneTasks,
            onFolderCreated: (folder) {
              _addNewFolder(folder);
              _loadFolders();
            },
            onFolderEdit: (folder) {
              _loadFolders();
            },
            currentFolders: _folderLists,
            folderLists: _folderLists,
            taskList: taskList,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.listFolders,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _folderLists.isEmpty
                        ? buildEmptyState()
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              int crossAxisCount = 2;
                              double cardWidth = 160.0;
                              double cardHeight = 140.0;

                              if (screenType == ScreenType.tablet) {
                                crossAxisCount = 3;
                                cardWidth = 140.0;
                                cardHeight = 100.0;
                              } else if (screenType == ScreenType.desktop) {
                                crossAxisCount = 6;
                                cardWidth = 100.0;
                                cardHeight = 60.0;
                              }

                              return GridView.builder(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: cardWidth / cardHeight,
                                ),
                                itemCount: _folderLists.length,
                                itemBuilder: (context, index) {
                                  final folder = _folderLists[index];
                                  return FolderCard(
                                    title: folder.title,
                                    tasks: folder.tasks,
                                    icon: folder.icon,
                                    color: folder.color,
                                    totalTasks: totalTasks,
                                    folder: folder,
                                    onTap: () => _openFolderDetail(folder),
                                  );
                                },
                              );
                            },
                          ),
                  )
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              const isAddingNewTask = true;
              if (isAddingNewTask) {
                setState(() {
                  _selectedFolder = null;
                });
              }

              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CreateTaskDialog(
                    existingTask: null,
                    status: TaskStatus.TODO,
                    selectedFolder: _selectedFolder,
                    selectFolder: selectFolder,
                    statusColors: const {
                      TaskStatus.TODO: Colors.blue,
                      TaskStatus.INPROGRESS: Colors.orange,
                      TaskStatus.PENDING: Colors.purple,
                      TaskStatus.DONE: Colors.green,
                    },
                    existingFolders: _folderLists,
                  ),
                  fullscreenDialog: true,
                ),
              );

              if (result != null) {
                _addNewTask(result as Map<String, dynamic>, _selectedFolder!);
              }
            },
            backgroundColor: Colors.blue,
            tooltip: AppLocalizations.of(context)!.newTask,
            child: const Icon(Icons.add),
          )),
    );
  }
}

extension on int {
  get length => null;
}

void main() async {
  // debugPaintSizeEnabled = true;
  WidgetsFlutterBinding.ensureInitialized();
  final locale = await loadLocale();

  FolderListPage.localeNotifier.value = locale;

  runApp(
    ValueListenableBuilder<Locale>(
      valueListenable: FolderListPage.localeNotifier,
      builder: (context, locale, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: L10n.all,
          home: const FolderListPage(),
        );
      },
    ),
  );
}
