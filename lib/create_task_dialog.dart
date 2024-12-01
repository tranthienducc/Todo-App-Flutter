import 'package:flutter/material.dart';
import 'package:todolist_app/note_dialog.dart';
import 'package:todolist_app/task.dart';
import 'package:todolist_app/task_status.dart';

class CreateTaskDialog extends StatefulWidget {
  final Task? existingTask;
  final TaskStatus _status;
  final Map<TaskStatus, Color> statusColors;
  const CreateTaskDialog(this.existingTask, this._status, this.statusColors,
      {super.key});
  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  late TextEditingController _taskController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _note;
  late TaskStatus _status;
  late final Map<TaskStatus, Color> statusColors;

  TimeOfDay parseTimeOfDay(String timeString) {
    final RegExp timeFormat = RegExp(r'(\d+):(\d+)([APMapm]{2})');
    final match = timeFormat.firstMatch(timeString);

    if (match != null) {
      final hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      final period = match.group(3)?.toUpperCase();

      int adjustedHour = hour;
      if (period == 'PM' && hour != 12) {
        adjustedHour += 12;
      } else if (period == 'AM' && hour == 12) {
        adjustedHour = 0;
      }

      return TimeOfDay(hour: adjustedHour, minute: minute);
    }

    return TimeOfDay.now();
  }

  @override
  void initState() {
    super.initState();
    _taskController =
        TextEditingController(text: widget.existingTask?.title ?? '');
    _selectedDate = widget.existingTask?.date ?? DateTime.now();
    _selectedTime = widget.existingTask?.time != null
        ? parseTimeOfDay(widget.existingTask?.time ?? '')
        : TimeOfDay.now();
    _note = widget.existingTask?.note ?? '';
    _status = widget.existingTask?.status ?? TaskStatus.TODO;
    statusColors = widget.statusColors;
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _addNote(BuildContext context) async {
    final String? note = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => NoteDialog(initialNote: _note),
    );

    if (note != null && mounted) {
      setState(() => _note = note);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Colors.black),
        ),
        title: Text(
          widget.existingTask == null ? 'New Task' : 'Edit Task',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _taskController,
                    style: const TextStyle(fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: 'What are you planning?',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () => _selectDateTime(context),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time,
                            color: Colors.blue, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          '${_selectedDate.toString().split(' ')[0]}, ${_selectedTime.format(context)}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _addNote(context),
                    child: Row(
                      children: [
                        const Icon(Icons.note_outlined,
                            color: Colors.grey, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          _note.isEmpty ? 'Add note' : _note,
                          style: TextStyle(
                            color: _note.isEmpty ? Colors.grey : Colors.black,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _selectStatus(context),
                    child: Row(
                      children: [
                        Icon(Icons.flag_outlined,
                            color: statusColors[_status], size: 20),
                        const SizedBox(width: 10),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                  color: statusColors[_status],
                                  shape: BoxShape.circle),
                            ),
                            Text(
                              _status.toString().split('.').last.toUpperCase(),
                              style: TextStyle(
                                color: statusColors[_status],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleTaskAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  widget.existingTask == null ? 'Create' : 'Save',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: _selectedTime,
      );
      if (time != null && mounted) {
        setState(() {
          _selectedDate = date;
          _selectedTime = time;
        });
      }
    }
  }

  Future<void> _selectStatus(BuildContext context) async {
    final TaskStatus? status = await showDialog<TaskStatus>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select status'),
        children: TaskStatus.values.map((TaskStatus status) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, status),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: statusColors[status],
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  status.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    color: statusColors[status],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );

    if (status != null && mounted) {
      setState(() => _status = status);
    }
  }

  void _handleTaskAction() {
    if (_taskController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task')),
      );
      return;
    }

    final result = {
      'task': _taskController.text.trim(),
      'date': _selectedDate,
      'time': _selectedTime,
      'note': _note,
      'status': _status,
      'statusColor': statusColors[_status],
    };

    Navigator.of(context).pop(result);
  }
}
