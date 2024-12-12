import 'package:todolist_app/classed/folder_data.dart';
import 'package:todolist_app/utils/enum/enum.dart';

class Task {
  String id;
  String title;
  String time;
  bool isDone;
  String note;
  TaskStatus? originalStatus;
  TaskStatus status;
  DateTime date;
  DateTime? createdAt;
  DateTime? updatedAt;
  FolderData? existingFolders;

  Task({
    required this.id,
    required this.title,
    required this.time,
    this.originalStatus,
    required this.isDone,
    required this.note,
    required this.status,
    required this.date,
    this.createdAt,
    this.updatedAt,
    this.existingFolders,
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
      'originalStatus': originalStatus?.toString(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'existingFolders': existingFolders?.toJson(),
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
      originalStatus: json['originalStatus'] != null
          ? TaskStatus.values.firstWhere(
              (e) => e.toString() == json['originalStatus'],
              orElse: () => TaskStatus.TODO)
          : null,
      date: DateTime.parse(json['date']),
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      existingFolders: json['existingFolders'] != null
          ? FolderData.fromJson(json['existingFolders'])
          : null,
    );
  }
}
