import 'package:todolist_app/task_status.dart';

class Task {
  String id;
  String title;
  String time;
  bool isDone;
  String note;
  TaskStatus status;
  DateTime date;
  DateTime? createdAt;
  DateTime? updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.time,
    required this.isDone,
    required this.note,
    required this.status,
    required this.date,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'time': time,
      'isDone': isDone,
      'note': note,
      'status': status.toString(),
      'date': date.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      time: json['time'],
      isDone: json['isDone'],
      note: json['note'],
      status: TaskStatus.values.firstWhere(
          (e) => e.toString() == json['status'],
          orElse: () => TaskStatus.TODO),
      date: DateTime.parse(json['date']),
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
}
