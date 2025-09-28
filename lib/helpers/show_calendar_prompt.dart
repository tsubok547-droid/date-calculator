// lib/helpers/show_calendar_prompt.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// カレンダーアプリに予定を追加するか確認するダイアログを表示する
///
/// ユーザーが「追加」を選択した場合は `true` を、
/// 「キャンセル」を選択した場合は `false` を返す。
Future<bool?> showCalendarPrompt(
  BuildContext context, {
  required String title,
  required DateTime startTime,
}) {
  // contextが有効でない場合は何もせずにnullを返す
  if (!context.mounted) return Future.value(null);

  final formattedDate = DateFormat('M月d日(E)', 'ja_JP').format(startTime);

  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('カレンダーに予定を追加'),
      content: Text(
          'お使いのカレンダーアプリを開いて、以下の内容で予定を追加しますか？\n\nタイトル: $title\n日時: $formattedDate'),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル')),
        TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('追加')),
      ],
    ),
  );
}