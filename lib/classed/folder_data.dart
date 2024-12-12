import 'package:flutter/material.dart';
import 'package:todolist_app/classed/task.dart';
import 'package:todolist_app/utils/index.dart';

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
