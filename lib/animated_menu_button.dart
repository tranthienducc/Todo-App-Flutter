import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'excel_service.dart';
import "main.dart";
import 'platform_utils.dart';

class AnimatedMenuButton extends StatefulWidget {
  final Function(FolderData) onFolderCreated;
  final Function(FolderData) onFolderEdit;
  final List<FolderData> currentFolders;

  const AnimatedMenuButton({
    super.key,
    required this.onFolderCreated,
    required this.onFolderEdit,
    required this.currentFolders,
  });

  @override
  State<AnimatedMenuButton> createState() => _AnimatedMenuButtonState();
}

class _AnimatedMenuButtonState extends State<AnimatedMenuButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;
  final ExcelService _excelService = ExcelService();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      _controller = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (!_controller.isAnimating) {
      setState(() {
        _isOpen = !_isOpen;
        if (_isOpen) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      });
    }
  }

  Future<void> _importExcel() async {
    _toggleMenu();
    try {
      List<Map<String, dynamic>> importedData =
          await _excelService.importFromExcel();

      print('Imported Data: $importedData');

      if (importedData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No folders found in the Excel file'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      List<FolderData> newFolders = [];
      for (var data in importedData) {
        if (data['title'] == null || data['title'].toString().isEmpty) {
          print('Skipping invalid folder: $data');
          continue;
        }

        FolderData newFolder = FolderData(
          title: data['title'],
          color: data['color'] ?? Colors.blue.value,
          icon: data['icon'] ?? Icons.folder.codePoint,
        );
        newFolders.add(newFolder);
        widget.onFolderCreated(newFolder);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${newFolders.length} folders'),
          backgroundColor: newFolders.isNotEmpty ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            left: _isOpen ? 0 : -200,
            top: 0,
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 48),
                  Visibility(
                    visible: _isOpen,
                    child: _buildActionButton(
                      icon: Icons.create,
                      label: 'Create',
                      onTap: () async {
                        _toggleMenu();
                        final result = await showDialog<FolderData>(
                          context: context,
                          builder: (context) => const CreateFolderDialog(),
                        );

                        if (result != null) {
                          widget.onFolderCreated(result);
                        }
                      },
                    ),
                  ),
                  if (kIsWeb || PlatformUtil.isDesktopPlatform) ...[
                    Visibility(
                      visible: _isOpen,
                      child: _buildActionButton(
                        icon: Icons.upload_file,
                        label: 'Import Excel',
                        onTap: _importExcel,
                      ),
                    ),
                  ],
                  Visibility(
                    visible: _isOpen,
                    child: _buildActionButton(
                      icon: Icons.settings,
                      label: 'Setting',
                      onTap: _toggleMenu,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 8,
            top: 12,
            child: GestureDetector(
              onTap: _toggleMenu,
              child: Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      width: 15,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      width: 20,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
