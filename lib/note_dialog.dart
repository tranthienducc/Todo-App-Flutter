import 'package:flutter/material.dart';

class NoteDialog extends StatefulWidget {
  final String initialNote;

  const NoteDialog({
    Key? key,
    required this.initialNote,
  }) : super(key: key);

  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add note'),
      content: TextField(
        controller: _noteController,
        decoration: const InputDecoration(hintText: 'Enter note'),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _noteController.text),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
