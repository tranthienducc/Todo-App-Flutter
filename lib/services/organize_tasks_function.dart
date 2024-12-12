import 'package:todolist_app/classed/task.dart';
import 'package:todolist_app/utils/enum/enum.dart';

class OrganizeTasksService {
  static void organizeTasks({
    required List<Task> taskLists,
    required List<Task> lateTasks,
    required List<Task> todayTasks,
    required List<Task> doneTasks,
    required Function setState,
  }) {
    setState(() {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      lateTasks.clear();
      todayTasks.clear();
      doneTasks.clear();

      for (var task in taskLists) {
        task.isDone = task.status == TaskStatus.DONE;

        if (task.isDone) {
          doneTasks.add(task);
        } else {
          if (task.date.isBefore(today)) {
            lateTasks.add(task);
          } else if (task.date.year == today.year &&
              task.date.month == today.month &&
              task.date.day == today.day) {
            todayTasks.add(task);
          }
        }
      }
    });
  }
}
