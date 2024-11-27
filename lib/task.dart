import 'package:todolist_app/task_status.dart';

class Task {
  String title;
  String time;
  bool isDone;
  String note;
  TaskStatus status;
  DateTime date;

  Task({
    required this.title,
    required this.time,
    required this.isDone,
    required this.note,
    required this.status,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'time': time,
      'isDone': isDone,
      'note': note,
      'status': status.toString(),
      'date': date.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'],
      time: json['time'],
      isDone: json['isDone'],
      note: json['note'],
      status: TaskStatus.values.firstWhere(
          (e) => e.toString() == json['status'],
          orElse: () => TaskStatus.todo),
      date: DateTime.parse(json['date']),
    );
  }
}
