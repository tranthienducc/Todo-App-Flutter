import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:todolist_app/create_task_dialog.dart';
import 'package:todolist_app/task.dart';
import 'package:todolist_app/task_status.dart';

import './animated_menu_button.dart';
import './folder_card.dart';
import './folder_detail_view.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:todolist_app/l10n/l10n.dart';

String iconToString(IconData icon) => icon.codePoint.toString();
IconData stringToIcon(String iconString) =>
    IconData(int.parse(iconString), fontFamily: 'MaterialIcons');
String colorToString(Color color) => color.value.toString();
Color stringToColor(String colorString) => Color(int.parse(colorString));

class FolderData {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  late final int tasks;
  late List<Task>? taskLists;

  FolderData({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    this.tasks = 0,
    this.taskLists,
  });

  bool get isEmpty =>
      id.isEmpty && title.isEmpty && (taskLists?.isEmpty ?? true);

  bool get isNotEmpty => !isEmpty;
  FolderData copyWith({
    String? id,
    String? title,
    IconData? icon,
    List<Task>? taskLists,
    Color? color,
    int? tasks,
  }) {
    return FolderData(
      id: id ?? this.id,
      title: title ?? this.title,
      taskLists: taskLists ?? this.taskLists,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      tasks: tasks ?? this.tasks,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'tasks': tasks,
        'icon': iconToString(icon),
        'taskLists': taskLists?.map((task) => task.toJson()).toList(),
        'color': colorToString(color),
      };

  factory FolderData.fromJson(Map<String, dynamic> json) => FolderData(
        id: json['id'],
        title: json['title'],
        icon: stringToIcon(json['icon']),
        color: stringToColor(json['color']),
        taskLists: json['taskLists'] != null
            ? (json['taskLists'] as List)
                .map((task) => Task.fromJson(task))
                .toList()
            : [],
        tasks: json['tasks'] ?? 0,
      );
}

enum ScreenType { mobile, tablet, desktop }

ScreenType getScreenType(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width >= 1024) return ScreenType.desktop;
  if (width >= 600) return ScreenType.tablet;
  return ScreenType.mobile;
}

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

class CreateFolderDialog extends StatefulWidget {
  final FolderData? folderData;

  const CreateFolderDialog({super.key, this.folderData});

  @override
  State<CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<CreateFolderDialog> {
  late TextEditingController _nameController;
  IconData _selectedIcon = Icons.folder;
  Color _selectedColor = Colors.blue;

  final List<IconData> _availableIcons = [
    Icons.folder,
    Icons.work,
    Icons.music_note,
    Icons.flight,
    Icons.book,
    Icons.home,
    Icons.shopping_bag,
    Icons.favorite,
    Icons.sports_basketball,
    Icons.movie,
    Icons.restaurant,
    Icons.fitness_center,
  ];

  final List<Color> _availableColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.folderData?.title ?? '',
    );
    _selectedIcon = widget.folderData?.icon ?? Icons.folder;
    _selectedColor = widget.folderData?.color ?? Colors.blue;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.folderData == null
                      ? AppLocalizations.of(context)!.createFolder
                      : AppLocalizations.of(context)!.editFolder,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.placeholderFolder,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(
                      _selectedIcon,
                      color: _selectedColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.selectIcon,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 90,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    padding: const EdgeInsets.all(8),
                    itemCount: _availableIcons.length,
                    itemBuilder: (context, index) {
                      final icon = _availableIcons[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIcon = icon;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: icon == _selectedIcon
                                ? _selectedColor.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Icon(
                              icon,
                              color: icon == _selectedIcon
                                  ? _selectedColor
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.selectIcon,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _availableColors.length,
                    itemBuilder: (context, index) {
                      final color = _availableColors[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedColor = color;
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: color == _selectedColor
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (_nameController.text.isNotEmpty) {
                          Navigator.pop(
                            context,
                            FolderData(
                              id: DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString(),
                              title: _nameController.text,
                              icon: _selectedIcon,
                              color: _selectedColor,
                              tasks: widget.folderData?.tasks ?? 0,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(widget.folderData == null
                          ? AppLocalizations.of(context)!.create
                          : AppLocalizations.of(context)!.save),
                    ),
                  ],
                ),
              ],
            )),
      ),
    );
  }
}

Future<void> saveLocale(Locale locale) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('locale', locale.languageCode);
}

Future<Locale> loadLocale() async {
  final prefs = await SharedPreferences.getInstance();
  final languageCode = prefs.getString('locale') ?? 'en';
  return Locale(languageCode);
}

class _FolderListPageState extends State<FolderListPage> {
  List<FolderData> _folderLists = [];
  late int totalTasks = 0;
  bool isMenuOpen = false;
  late List<Task> lateTasks = [];
  List<Task> todayTasks = [];
  late List<Task> doneTasks = [];
  FolderData? _selectedFolder;

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
      onTap: () {
        if (isMenuOpen) {
          setState(() {
            isMenuOpen = false;
          });
        }
      },
      child: Scaffold(
          backgroundColor: Colors.grey[100],
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedMenuButton(
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
                    onMenuToggle: (isOpen) {
                      setState(() {
                        isMenuOpen = isOpen;
                      });
                    },
                    folderLists: _folderLists,
                  ),
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
                        ? _buildEmptyState()
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              int crossAxisCount = 2;
                              if (screenType == ScreenType.tablet) {
                                crossAxisCount = 3;
                              } else if (screenType == ScreenType.desktop) {
                                crossAxisCount = 4;
                              }
                              return GridView.builder(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1.1,
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
                  ),
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
              print("Đây là kết quả khi tạo task $result");
            },
            backgroundColor: Colors.blue,
            child: const Icon(Icons.add),
          )),
    );
  }

  Widget _buildEmptyState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Container(
                width: 120,
                height: 20,
                color: Colors.white,
              ),
              const Spacer(),
              Container(
                width: 80,
                height: 16,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
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
