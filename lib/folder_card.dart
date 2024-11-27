import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'main.dart';

class FolderCard extends StatelessWidget {
  final String title;
  final int tasks;
  final int totalTasks;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final FolderData? folder;
  final bool isLoading;

  const FolderCard({
    super.key,
    this.title = '',
    this.tasks = 0,
    this.icon = Icons.folder,
    this.color = Colors.grey,
    required this.onTap,
    this.folder,
    this.totalTasks = 0,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildShimmerLoading();
    }

    if (folder == null) {
      return _buildNoFolderAvailable();
    }

    return _buildFolderCard();
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Container(
                width: 120,
                height: 20,
                color: Colors.white,
              ),
              const Spacer(),
              Container(
                width: 80,
                height: 16,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoFolderAvailable() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No folder available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFolderCard() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                folder?.icon ?? icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '$tasks Tasks',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
