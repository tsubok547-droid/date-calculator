import 'package:flutter/material.dart';

/// アプリ共通のSnackBarを表示する
///
/// [context] 表示元のBuildContext
/// [message] 表示するメッセージ
void showAppSnackBar(BuildContext context, String message) {
  // 念のため、contextが有効か（画面に表示されているか）を確認
  if (!context.mounted) return;

  // 既存のSnackBarがあれば隠す
  ScaffoldMessenger.of(context).hideCurrentSnackBar();

  // 新しいSnackBarを作成して表示
  final snackBar = SnackBar(
    content: Text(message),
    // 少し見た目をモダンにするための設定（お好みで調整・削除してください）
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
    action: SnackBarAction(
      label: 'OK',
      onPressed: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
    ),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}