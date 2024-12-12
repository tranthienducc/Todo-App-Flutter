import 'package:flutter/material.dart';
import 'package:todolist_app/classed/folder_data.dart';
import 'package:todolist_app/classed/task.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:todolist_app/utils/enum/enum.dart';
import 'package:todolist_app/widgets/task_widget.dart';

Widget buildSection({
  required String title,
  required List<Task> tasks,
  required List<FolderData> folderLists,
  required BuildContext context,
  required List<Task> lateTasksWidget,
  required List<Task> todayTasksWidget,
  required String titleWidget,
  required FolderData folderWidget,
  required List<Task> doneTasksWidget,
  required Color colorWidget,
  required Map<TaskStatus, Color> statusColorsWidget,
  required void Function(Task) editTask,
  required void Function(Task) deleteTask,
  required void Function(Task, bool?) handleTaskToggle,
  required void Function(String, List<Task>) onSortTasks,
  required Function saveTasks,
  required Function saveFolders,
  required Function loadTasks,
}) {
  if (title == AppLocalizations.of(context)!.late) {
    tasks = lateTasksWidget;
  } else if (title == AppLocalizations.of(context)!.today) {
    tasks = todayTasksWidget;
  } else if (title == AppLocalizations.of(context)!.done) {
    tasks = doneTasksWidget;
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
                  ? colorWidget
                  : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.black54),
            onSelected: (String result) {
              onSortTasks(result, tasks);
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
              children: tasks
                  .map((task) => buildTask(
                      task: task,
                      section: title,
                      editTask: editTask,
                      deleteTask: deleteTask,
                      handleTaskToggle: handleTaskToggle,
                      statusColors: statusColorsWidget,
                      folderColor: colorWidget,
                      folderTitle: titleWidget,
                      context: context,
                      loadTasks: loadTasks,
                      saveFolders: saveFolders,
                      saveTasks: saveTasks,
                      folderLists: folderLists,
                      folderWidget: folderWidget))
                  .toList())
          : Text(
              AppLocalizations.of(context)!.emtyTask,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
      const SizedBox(height: 20),
    ],
  );
}
