import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:todolist_app/task.dart';

import './animated_menu_button.dart';
import './folder_card.dart';
import './folder_detail_view.dart';

String iconToString(IconData icon) => icon.codePoint.toString();
IconData stringToIcon(String iconString) =>
    IconData(int.parse(iconString), fontFamily: 'MaterialIcons');
String colorToString(Color color) => color.value.toString();
Color stringToColor(String colorString) => Color(int.parse(colorString));

class FolderData {
  final String title;
  final IconData icon;
  final Color color;
  late final int tasks;

  FolderData({
    required this.title,
    required this.icon,
    required this.color,
    this.tasks = 0,
  });

  FolderData copyWith({
    String? title,
    IconData? icon,
    Color? color,
    int? tasks,
  }) {
    return FolderData(
      title: title ?? this.title,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      tasks: tasks ?? this.tasks,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'tasks': tasks,
        'icon': iconToString(icon),
        'color': colorToString(color),
      };

  factory FolderData.fromJson(Map<String, dynamic> json) => FolderData(
        title: json['title'],
        icon: stringToIcon(json['icon']),
        color: stringToColor(json['color']),
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

class FolderListPage extends StatefulWidget {
  const FolderListPage({super.key});

  @override
  State<FolderListPage> createState() => _FolderListPageState();
}

class CreateFolderDialog extends StatefulWidget {
  final FolderData? folderData;

  const CreateFolderDialog({Key? key, this.folderData}) : super(key: key);

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
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.folderData == null ? 'Create New Folder' : 'Edit Folder',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Folder Name',
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
            const Text(
              'Select Icon',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
            const Text(
              'Select Color',
              style: TextStyle(
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
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    if (_nameController.text.isNotEmpty) {
                      Navigator.pop(
                        context,
                        FolderData(
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
                  child: Text(widget.folderData == null ? 'Create' : 'Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderListPageState extends State<FolderListPage> {
  List<FolderData> _folderLists = [];
  late int totalTasks = 0;
  bool isMenuOpen = false;
  late List<Task> lateTasks;
  late List<Task> todayTasks;
  late List<Task> doneTasks;

  int _calculateTotalTasks() {
    return _folderLists.fold(0, (sum, folder) => sum + folder.tasks);
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

  Future<List<FolderData>> loadFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString('folders');
    List<FolderData> folderList = [];

    if (jsonData != null) {
      final List<dynamic> decodedData = jsonDecode(jsonData);
      folderList = decodedData
          .map((json) => FolderData.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    // Calculate total tasks from all folders except "All"
    final totalTasks = folderList
        .where((folder) => folder.title != "All")
        .map((folder) => folder.tasks)
        .fold(0, (sum, tasks) => sum + tasks);

    // Check if "All" folder exists
    final index = folderList.indexWhere((folder) => folder.title == "All");

    if (index == -1) {
      // If "All" folder doesn't exist, add it
      folderList.add(FolderData(
        title: "All",
        icon: Icons.folder,
        color: Colors.redAccent,
        tasks: totalTasks,
      ));
    } else {
      // Update the existing "All" folder with the total tasks
      folderList[index] = folderList[index].copyWith(tasks: totalTasks);
    }

    // Ensure "All" is always first
    folderList.sort((a, b) {
      if (a.title == "All") return -1;
      if (b.title == "All") return 1;
      return 0;
    });

    return folderList;
  }

  void _loadFolders() async {
    final folders = await loadFolders();
    setState(() {
      _folderLists = folders;
    });
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
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString('tasks_${updatedFolder.title}');

    final result = await showDialog(
      context: context,
      builder: (context) => CreateFolderDialog(folderData: updatedFolder),
    );

    if (result != null) {
      if (tasksJson != null) {
        await prefs.setString('tasks_${result.title}', tasksJson);
      }

      setState(() {
        int index =
            _folderLists.indexWhere((f) => f.title == updatedFolder.title);
        if (index != -1) {
          _folderLists[index] = result.copyWith(tasks: updatedFolder.tasks);
        }
      });

      await saveFolders(_folderLists);
    }
  }

  void _openFolderDetail(FolderData folder) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FolderDetailView(
          title: folder.title,
          icon: folder.icon,
          color: folder.color,
          folder: folder,
          tasks: folder.tasks,
          folderLists: _folderLists,
          loadFolders: _loadFolders,
          totalTasks: totalTasks,
          saveFolders: saveFolders,
          editFolder: editFolder,
        ),
      ),
    );

    if (result != null) {
      if (result is int) {
        setState(() {
          totalTasks = result;
        });
      }

      if (result == true) {
        _loadFolders();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFolders();
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
                const Text(
                  'List Folders',
                  style: TextStyle(
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
      ),
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

void main() {
  // debugPaintSizeEnabled = true;
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FolderListPage(),
  ));
}
