import 'package:flutter/material.dart';
import 'package:todolist_app/classed/folder_data.dart';
import 'package:todolist_app/classed/task.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TaskMover {
  final BuildContext context;
  final List<FolderData> folderLists;
  final Function saveTasks;
  final Function saveFolders;
  final Function loadTasks;

  TaskMover({
    required this.context,
    required this.folderLists,
    required this.saveTasks,
    required this.saveFolders,
    required this.loadTasks,
  });

  Future<void> moveTaskToFolder({
    required FolderData targetFolder,
    required Task task,
    required FolderData folderWidget,
  }) async {
    try {
      FolderData allFolder = folderLists.firstWhere(
        (folder) => folder.title == "All",
        orElse: () => folderWidget,
      );

      FolderData sourceFolder = folderWidget;

      if (sourceFolder.id != allFolder.id) {
        _updateFolder(
          folder: sourceFolder,
          removeTask: task,
        );
        await saveTasks(sourceFolder);
      }

      if (targetFolder.id != sourceFolder.id) {
        _updateFolder(
          folder: targetFolder,
          addTask: task,
        );
        await saveTasks(targetFolder);
      }

      if (allFolder.id != targetFolder.id && allFolder.id != sourceFolder.id) {
        _updateFolder(
          folder: allFolder,
          removeTask: task,
          addTask: shouldAddTaskToAllFolder(task, targetFolder) ? task : null,
        );
        await saveTasks(allFolder);
      }

      final updatedFolders = folderLists.map((folder) {
        if (folder.id == sourceFolder.id) return sourceFolder;
        if (folder.id == targetFolder.id) return targetFolder;
        if (folder.id == allFolder.id) return allFolder;
        return folder;
      }).toList();

      await saveFolders(updatedFolders);
      await loadTasks();

      _showSnackbar(
        AppLocalizations.of(context)!.taskHasbeenMove(targetFolder.title),
      );
    } catch (e) {
      debugPrint("Error moving task: $e");
      _showSnackbar("Không thể di chuyển task");
    }
  }

  void _updateFolder({
    required FolderData folder,
    Task? addTask,
    Task? removeTask,
  }) {
    if (removeTask != null) {
      folder.taskLists?.removeWhere((t) => t.id == removeTask.id);
    }
    if (addTask != null) {
      folder.taskLists ??= [];
      folder.taskLists?.add(addTask);
    }
    folder = folder.copyWith(
      taskLists: folder.taskLists,
      tasks: folder.taskLists?.length ?? 0,
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool shouldAddTaskToAllFolder(Task task, FolderData targetFolder) {
    return targetFolder.title == "All";
  }
}

void showMoveTaskDialog({
  required Task task,
  required List<FolderData> folderLists,
  required BuildContext context,
  required FolderData folderWidget,
  required Function saveTasks,
  required Function saveFolders,
  required Function loadTasks,
}) {
  final TaskMover taskMover = TaskMover(
    context: context,
    folderLists: folderLists,
    saveTasks: saveTasks,
    saveFolders: saveFolders,
    loadTasks: loadTasks,
  );

  final availableFolders = folderLists
      .where((folder) =>
          folder.id != task.existingFolders?.id &&
          folder.id != folderWidget &&
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
                            taskMover.moveTaskToFolder(
                              targetFolder: folder,
                              task: task,
                              folderWidget: folderWidget,
                            );
                          },
                        ))
                    .toList()
                : [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          AppLocalizations.of(context)!.notFoundFolder,
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
