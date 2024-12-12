import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

Widget buildEmptyState() {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(
      height: 60,
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
