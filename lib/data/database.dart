// lib/data/database.dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart'; // この行は必須です

// テーブルの各列（カラム）を定義します
class CalculationHistories extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get standardDate => dateTime()();
  TextColumn get daysExpression => text()();
  DateTimeColumn get finalDate => dateTime().nullable()();
  TextColumn get comment => text().nullable()();
}

// データベース本体のクラスを定義します
@DriftDatabase(tables: [CalculationHistories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

// データベースファイル（db.sqlite）をどこに保存するかを指定します
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}