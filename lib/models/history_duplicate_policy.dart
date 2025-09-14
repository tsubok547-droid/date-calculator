// lib/models/history_duplicate_policy.dart

enum HistoryDuplicatePolicy {
  /// コメントが同じ場合、古い履歴を削除する (現在の挙動)
  removeSameComment,
  /// コメント、基準日、日数表現が全て同じ場合のみ、古い履歴を削除する
  removeSameCalculation,
  /// コメントや計算内容が同じでも履歴を削除しない (常に新しい履歴を追加)
  keepAll,
}