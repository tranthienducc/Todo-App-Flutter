import 'package:todolist_app/classed/folder_data.dart';
import 'package:todolist_app/classed/task.dart';
import 'package:todolist_app/services/organize_tasks_function.dart';

class UpdateTaskListService {
  static void updateTaskList({
    required FolderData? folder,
    required Function setState,
    required List<Task> taskListsWidget,
    required List<Task> lateTasksWidget,
    required List<Task> todayTasksWidget,
    required List<Task> doneTasksWidget,
  }) {
    setState(() {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (folder != null) {
        setState(() {
          taskListsWidget = folder.taskLists ?? [];
          OrganizeTasksService.organizeTasks(
            taskLists: taskListsWidget,
            lateTasks: lateTasksWidget,
            todayTasks: todayTasksWidget,
            doneTasks: doneTasksWidget,
            setState: setState,
          );
        });
      }
    });
  }
}
