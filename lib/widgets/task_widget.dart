import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todolist_app/classed/folder_data.dart';
import 'package:todolist_app/classed/task.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:todolist_app/utils/enum/enum.dart';

Widget buildTask(
    {required void Function(Task) deleteTask,
    required void Function(Task, bool?) handleTaskToggle,
    required Map<TaskStatus, Color> statusColors,
    required Color folderColor,
    required String folderTitle,
    required void Function(Task) editTask,
    required BuildContext context,
    required Task task,
    required List<FolderData> folderLists,
    required FolderData folderWidget,
    required Function saveTasks,
    required Function saveFolders,
    required Function loadTasks,
    required Function showMoveTaskDialog,
    required String section}) {
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
                  color: task.isDone ? folderColor : Colors.black87,
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
        if (folderTitle != "All")
          IconButton(
            icon: const Icon(Icons.move_to_inbox),
            color: folderColor,
            onPressed: () => showMoveTaskDialog(task),
          ),
        IconButton(
          icon: const Icon(Icons.edit),
          color: folderColor,
          onPressed: () => editTask(task),
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          color: folderColor,
          onPressed: () => deleteTask(task),
        ),
        Checkbox(
          value: task.isDone,
          onChanged: (value) => handleTaskToggle(task, value),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          activeColor: folderColor,
        ),
      ],
    ),
  );
}
