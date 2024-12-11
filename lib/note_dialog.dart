import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class NoteDialog extends StatefulWidget {
  final String initialNote;

  const NoteDialog({
    super.key,
    required this.initialNote,
  });

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
      title: Text(AppLocalizations.of(context)!.addNote),
      content: TextField(
        controller: _noteController,
        decoration:
            InputDecoration(hintText: AppLocalizations.of(context)!.enterNote),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _noteController.text),
          child: Text(AppLocalizations.of(context)!.add),
        ),
      ],
    );
  }
}
