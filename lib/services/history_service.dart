import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/calculation_state.dart';
import '../utils/string_sanitizer.dart'; // 共通ユーティリティをインポート

class HistoryService {
  /// 履歴リストをCSVとしてエクスポート（共有）する
  Future<bool> exportHistory(List<CalculationState> history) async {
    try {
      final List<List<dynamic>> rows = [
        // ヘッダー行
        ['standardDate', 'daysExpression', 'finalDate', 'comment']
      ];

      for (final state in history) {
        rows.add([
          state.standardDate.toIso8601String(),
          sanitizeForCsv(state.daysExpression), // 共通関数を呼び出し
          state.finalDate?.toIso8601String() ?? '',
          sanitizeForCsv(state.comment) // 共通関数を呼び出し
        ]);
      }

      final String csv = const ListToCsvConverter().convert(rows);
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = '${tempDir.path}/history_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final File file = await File(filePath).writeAsString(csv);

      final result = await Share.shareXFiles([XFile(file.path)], subject: '計算履歴のエクスポート');

      return result.status == ShareResultStatus.success;
    } catch (e) {
      // エラーが発生した場合は失敗としてfalseを返す
      return false;
    }
  }

  /// CSVファイルから履歴リストをインポートする
  Future<List<CalculationState>?> importHistory() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.single.path == null) {
        return null; // ユーザーがファイル選択をキャンセルした
      }

      final file = File(result.files.single.path!);
      final csvString = await file.readAsString();
      final List<List<dynamic>> rows = const CsvToListConverter().convert(csvString);

      if (rows.length < 2) {
        return []; // ヘッダーのみ、または空のファイル
      }

      // ヘッダー行をスキップして CalculationState に変換
      final List<CalculationState> importedHistory = [];
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length >= 4) {
          importedHistory.add(
            CalculationState(
              standardDate: DateTime.parse(row[0]),
              daysExpression: row[1].toString(),
              finalDate: row[2].toString().isNotEmpty ? DateTime.parse(row[2]) : null,
              comment: row[3].toString().isNotEmpty ? row[3] : null,
            ),
          );
        }
      }
      return importedHistory;
    } catch (e) {
      // パースエラーなどが発生した場合はnullを返す
      return null;
    }
  }
}