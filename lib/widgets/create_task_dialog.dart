import 'package:flutter/material.dart';
import 'package:todolist_app/classed/folder_data.dart';
import 'package:todolist_app/utils/index.dart';
import 'package:todolist_app/widgets/note_dialog.dart';
import 'package:todolist_app/classed/task.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:todolist_app/utils/enum/enum.dart';

class CreateTaskDialog extends StatefulWidget {
  final Task? existingTask;
  FolderData? selectedFolder;
  final Function? selectFolder;
  TaskStatus status;
  Map<TaskStatus, Color> statusColors;
  List<FolderData> existingFolders;

  CreateTaskDialog({
    super.key,
    this.selectedFolder,
    required this.selectFolder,
    required this.existingTask,
    required this.status,
    required this.statusColors,
    required this.existingFolders,
  });

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  late TextEditingController _taskController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _note;

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
    widget.status = widget.existingTask?.status ?? TaskStatus.TODO;
    widget.statusColors = widget.statusColors;
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
        title: Text(AppLocalizations.of(context)!.selectStatus),
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
                    color: widget.statusColors[status],
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  status.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    color: widget.statusColors[status],
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
      setState(() => widget.status = status);
    }
  }

  void _handleTaskAction() {
    if (widget.selectedFolder == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a folder before creating a task'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (_taskController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.warningContentTask)),
      );
      return;
    }

    final result = {
      'task': _taskController.text.trim(),
      'date': _selectedDate,
      'time': _selectedTime,
      'note': _note,
      'status': widget.status,
      'statusColor': widget.statusColors[widget.status],
      'existingFolders': widget.selectedFolder?.id,
    };

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.existingTask == null
              ? AppLocalizations.of(context)!.newTask
              : AppLocalizations.of(context)!.editTask,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Colors.black),
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
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.planing,
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
                          _note.isEmpty
                              ? AppLocalizations.of(context)!.addNote
                              : _note,
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
                    onTap: () async {
                      await widget.selectFolder!(context)
                          .then((selectedFolder) {
                        if (selectedFolder != null) {
                          setState(() {
                            widget.selectedFolder = selectedFolder;
                          });
                        }
                      });
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.folder_outlined,
                            color: Colors.grey, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          widget.selectedFolder?.isEmpty ?? true
                              ? AppLocalizations.of(context)!.selectFolder
                              : widget.selectedFolder!.title,
                          style: TextStyle(
                            color: widget.selectedFolder?.title != null
                                ? Colors.black
                                : Colors.grey,
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
                            color: widget.statusColors[widget.status],
                            size: 20),
                        const SizedBox(width: 10),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                  color: widget.statusColors[widget.status],
                                  shape: BoxShape.circle),
                            ),
                            Text(
                              widget.status
                                  .toString()
                                  .split('.')
                                  .last
                                  .toUpperCase(),
                              style: TextStyle(
                                color: widget.statusColors[widget.status],
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
                  widget.existingTask == null
                      ? AppLocalizations.of(context)!.create
                      : AppLocalizations.of(context)!.save,
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
}
