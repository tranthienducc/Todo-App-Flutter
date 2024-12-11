import 'package:flutter/material.dart';

import './task.dart';

class MoveTaskDialog extends StatelessWidget {
  final Task task;
  final List<String> folders;
  final String currentFolder;
  final Function(String) onFolderSelected;

  const MoveTaskDialog({
    super.key,
    required this.task,
    required this.folders,
    required this.currentFolder,
    required this.onFolderSelected,
  });

  @override
  Widget build(BuildContext context) {
    final availableFolders =
        folders.where((folder) => folder != currentFolder).toList();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.drive_file_move,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  'Move "${task.title}"',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (availableFolders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No folders available to move to',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            )
          else
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableFolders.length,
                itemBuilder: (context, index) {
                  final folder = availableFolders[index];
                  return ListTile(
                    leading: const Icon(Icons.folder),
                    title: Text(
                      folder,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      onFolderSelected(folder);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          OverflowBar(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
