// lib/widgets/calculator/comment_display.dart

import 'package:flutter/material.dart';

class CommentDisplay extends StatelessWidget {
  final String? comment;
  final VoidCallback onEditComment;

  const CommentDisplay({
    super.key,
    required this.comment,
    required this.onEditComment,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (comment != null && comment!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: InkWell(
          onTap: onEditComment,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            decoration: BoxDecoration(
              // ▼▼▼ 修正箇所 ▼▼▼
              color: HSLColor.fromColor(colorScheme.secondaryContainer).withAlpha(0.4).toColor(),
              // ▲▲▲ ここまで ▲▲▲
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 20,
                  color: colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    comment!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSecondaryContainer,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.edit_outlined, size: 18),
              ],
            ),
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: OutlinedButton.icon(
          icon: const Icon(Icons.add_comment_outlined, size: 18),
          label: const Text('コメントを追加'),
          onPressed: onEditComment,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            // ▼▼▼ 修正箇所 ▼▼▼
            foregroundColor: HSLColor.fromColor(colorScheme.onSurface).withAlpha(0.7).toColor(),
            // ▲▲▲ ここまで ▲▲▲
          ),
        ),
      );
    }
  }
}