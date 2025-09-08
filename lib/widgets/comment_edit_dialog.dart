// lib/widgets/comment_edit_dialog.dart

import 'package:flutter/material.dart';

// どこからでも呼び出せるグローバルな関数として定義
Future<String?> showCommentEditDialog(BuildContext context, {String? currentComment}) {
  final controller = TextEditingController(text: currentComment);

  return showDialog<String?>(
    context: context,
    builder: (context) => AlertDialog(
      // コメントの有無でタイトルを動的に変更
      title: Text(currentComment == null || currentComment.isEmpty 
          ? 'コメントを追加' 
          : 'コメントを編集'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          // 提案した新しいプレースホルダー
          hintText: '例：〇〇様 A錠 (一包化), B薬 (予製)',
        ),
      ),
      actions: [
        TextButton(
          child: const Text('キャンセル'),
          onPressed: () => Navigator.of(context).pop(), // nullを返す
        ),
        TextButton(
          child: const Text('保存'),
          onPressed: () => Navigator.of(context).pop(controller.text), // 入力内容を返す
        ),
      ],
    ),
  );
}