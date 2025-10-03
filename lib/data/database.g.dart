// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CalculationHistoriesTable extends CalculationHistories
    with TableInfo<$CalculationHistoriesTable, CalculationHistory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalculationHistoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _standardDateMeta = const VerificationMeta(
    'standardDate',
  );
  @override
  late final GeneratedColumn<DateTime> standardDate = GeneratedColumn<DateTime>(
    'standard_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _daysExpressionMeta = const VerificationMeta(
    'daysExpression',
  );
  @override
  late final GeneratedColumn<String> daysExpression = GeneratedColumn<String>(
    'days_expression',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finalDateMeta = const VerificationMeta(
    'finalDate',
  );
  @override
  late final GeneratedColumn<DateTime> finalDate = GeneratedColumn<DateTime>(
    'final_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _commentMeta = const VerificationMeta(
    'comment',
  );
  @override
  late final GeneratedColumn<String> comment = GeneratedColumn<String>(
    'comment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    standardDate,
    daysExpression,
    finalDate,
    comment,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calculation_histories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CalculationHistory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('standard_date')) {
      context.handle(
        _standardDateMeta,
        standardDate.isAcceptableOrUnknown(
          data['standard_date']!,
          _standardDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_standardDateMeta);
    }
    if (data.containsKey('days_expression')) {
      context.handle(
        _daysExpressionMeta,
        daysExpression.isAcceptableOrUnknown(
          data['days_expression']!,
          _daysExpressionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_daysExpressionMeta);
    }
    if (data.containsKey('final_date')) {
      context.handle(
        _finalDateMeta,
        finalDate.isAcceptableOrUnknown(data['final_date']!, _finalDateMeta),
      );
    }
    if (data.containsKey('comment')) {
      context.handle(
        _commentMeta,
        comment.isAcceptableOrUnknown(data['comment']!, _commentMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalculationHistory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalculationHistory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      standardDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}standard_date'],
      )!,
      daysExpression: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}days_expression'],
      )!,
      finalDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}final_date'],
      ),
      comment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comment'],
      ),
    );
  }

  @override
  $CalculationHistoriesTable createAlias(String alias) {
    return $CalculationHistoriesTable(attachedDatabase, alias);
  }
}

class CalculationHistory extends DataClass
    implements Insertable<CalculationHistory> {
  final int id;
  final DateTime standardDate;
  final String daysExpression;
  final DateTime? finalDate;
  final String? comment;
  const CalculationHistory({
    required this.id,
    required this.standardDate,
    required this.daysExpression,
    this.finalDate,
    this.comment,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['standard_date'] = Variable<DateTime>(standardDate);
    map['days_expression'] = Variable<String>(daysExpression);
    if (!nullToAbsent || finalDate != null) {
      map['final_date'] = Variable<DateTime>(finalDate);
    }
    if (!nullToAbsent || comment != null) {
      map['comment'] = Variable<String>(comment);
    }
    return map;
  }

  CalculationHistoriesCompanion toCompanion(bool nullToAbsent) {
    return CalculationHistoriesCompanion(
      id: Value(id),
      standardDate: Value(standardDate),
      daysExpression: Value(daysExpression),
      finalDate: finalDate == null && nullToAbsent
          ? const Value.absent()
          : Value(finalDate),
      comment: comment == null && nullToAbsent
          ? const Value.absent()
          : Value(comment),
    );
  }

  factory CalculationHistory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalculationHistory(
      id: serializer.fromJson<int>(json['id']),
      standardDate: serializer.fromJson<DateTime>(json['standardDate']),
      daysExpression: serializer.fromJson<String>(json['daysExpression']),
      finalDate: serializer.fromJson<DateTime?>(json['finalDate']),
      comment: serializer.fromJson<String?>(json['comment']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'standardDate': serializer.toJson<DateTime>(standardDate),
      'daysExpression': serializer.toJson<String>(daysExpression),
      'finalDate': serializer.toJson<DateTime?>(finalDate),
      'comment': serializer.toJson<String?>(comment),
    };
  }

  CalculationHistory copyWith({
    int? id,
    DateTime? standardDate,
    String? daysExpression,
    Value<DateTime?> finalDate = const Value.absent(),
    Value<String?> comment = const Value.absent(),
  }) => CalculationHistory(
    id: id ?? this.id,
    standardDate: standardDate ?? this.standardDate,
    daysExpression: daysExpression ?? this.daysExpression,
    finalDate: finalDate.present ? finalDate.value : this.finalDate,
    comment: comment.present ? comment.value : this.comment,
  );
  CalculationHistory copyWithCompanion(CalculationHistoriesCompanion data) {
    return CalculationHistory(
      id: data.id.present ? data.id.value : this.id,
      standardDate: data.standardDate.present
          ? data.standardDate.value
          : this.standardDate,
      daysExpression: data.daysExpression.present
          ? data.daysExpression.value
          : this.daysExpression,
      finalDate: data.finalDate.present ? data.finalDate.value : this.finalDate,
      comment: data.comment.present ? data.comment.value : this.comment,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalculationHistory(')
          ..write('id: $id, ')
          ..write('standardDate: $standardDate, ')
          ..write('daysExpression: $daysExpression, ')
          ..write('finalDate: $finalDate, ')
          ..write('comment: $comment')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, standardDate, daysExpression, finalDate, comment);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalculationHistory &&
          other.id == this.id &&
          other.standardDate == this.standardDate &&
          other.daysExpression == this.daysExpression &&
          other.finalDate == this.finalDate &&
          other.comment == this.comment);
}

class CalculationHistoriesCompanion
    extends UpdateCompanion<CalculationHistory> {
  final Value<int> id;
  final Value<DateTime> standardDate;
  final Value<String> daysExpression;
  final Value<DateTime?> finalDate;
  final Value<String?> comment;
  const CalculationHistoriesCompanion({
    this.id = const Value.absent(),
    this.standardDate = const Value.absent(),
    this.daysExpression = const Value.absent(),
    this.finalDate = const Value.absent(),
    this.comment = const Value.absent(),
  });
  CalculationHistoriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime standardDate,
    required String daysExpression,
    this.finalDate = const Value.absent(),
    this.comment = const Value.absent(),
  }) : standardDate = Value(standardDate),
       daysExpression = Value(daysExpression);
  static Insertable<CalculationHistory> custom({
    Expression<int>? id,
    Expression<DateTime>? standardDate,
    Expression<String>? daysExpression,
    Expression<DateTime>? finalDate,
    Expression<String>? comment,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (standardDate != null) 'standard_date': standardDate,
      if (daysExpression != null) 'days_expression': daysExpression,
      if (finalDate != null) 'final_date': finalDate,
      if (comment != null) 'comment': comment,
    });
  }

  CalculationHistoriesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? standardDate,
    Value<String>? daysExpression,
    Value<DateTime?>? finalDate,
    Value<String?>? comment,
  }) {
    return CalculationHistoriesCompanion(
      id: id ?? this.id,
      standardDate: standardDate ?? this.standardDate,
      daysExpression: daysExpression ?? this.daysExpression,
      finalDate: finalDate ?? this.finalDate,
      comment: comment ?? this.comment,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (standardDate.present) {
      map['standard_date'] = Variable<DateTime>(standardDate.value);
    }
    if (daysExpression.present) {
      map['days_expression'] = Variable<String>(daysExpression.value);
    }
    if (finalDate.present) {
      map['final_date'] = Variable<DateTime>(finalDate.value);
    }
    if (comment.present) {
      map['comment'] = Variable<String>(comment.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalculationHistoriesCompanion(')
          ..write('id: $id, ')
          ..write('standardDate: $standardDate, ')
          ..write('daysExpression: $daysExpression, ')
          ..write('finalDate: $finalDate, ')
          ..write('comment: $comment')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CalculationHistoriesTable calculationHistories =
      $CalculationHistoriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [calculationHistories];
}

typedef $$CalculationHistoriesTableCreateCompanionBuilder =
    CalculationHistoriesCompanion Function({
      Value<int> id,
      required DateTime standardDate,
      required String daysExpression,
      Value<DateTime?> finalDate,
      Value<String?> comment,
    });
typedef $$CalculationHistoriesTableUpdateCompanionBuilder =
    CalculationHistoriesCompanion Function({
      Value<int> id,
      Value<DateTime> standardDate,
      Value<String> daysExpression,
      Value<DateTime?> finalDate,
      Value<String?> comment,
    });

class $$CalculationHistoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CalculationHistoriesTable> {
  $$CalculationHistoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get standardDate => $composableBuilder(
    column: $table.standardDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get daysExpression => $composableBuilder(
    column: $table.daysExpression,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finalDate => $composableBuilder(
    column: $table.finalDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CalculationHistoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CalculationHistoriesTable> {
  $$CalculationHistoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get standardDate => $composableBuilder(
    column: $table.standardDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get daysExpression => $composableBuilder(
    column: $table.daysExpression,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finalDate => $composableBuilder(
    column: $table.finalDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CalculationHistoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalculationHistoriesTable> {
  $$CalculationHistoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get standardDate => $composableBuilder(
    column: $table.standardDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get daysExpression => $composableBuilder(
    column: $table.daysExpression,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get finalDate =>
      $composableBuilder(column: $table.finalDate, builder: (column) => column);

  GeneratedColumn<String> get comment =>
      $composableBuilder(column: $table.comment, builder: (column) => column);
}

class $$CalculationHistoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CalculationHistoriesTable,
          CalculationHistory,
          $$CalculationHistoriesTableFilterComposer,
          $$CalculationHistoriesTableOrderingComposer,
          $$CalculationHistoriesTableAnnotationComposer,
          $$CalculationHistoriesTableCreateCompanionBuilder,
          $$CalculationHistoriesTableUpdateCompanionBuilder,
          (
            CalculationHistory,
            BaseReferences<
              _$AppDatabase,
              $CalculationHistoriesTable,
              CalculationHistory
            >,
          ),
          CalculationHistory,
          PrefetchHooks Function()
        > {
  $$CalculationHistoriesTableTableManager(
    _$AppDatabase db,
    $CalculationHistoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalculationHistoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalculationHistoriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CalculationHistoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> standardDate = const Value.absent(),
                Value<String> daysExpression = const Value.absent(),
                Value<DateTime?> finalDate = const Value.absent(),
                Value<String?> comment = const Value.absent(),
              }) => CalculationHistoriesCompanion(
                id: id,
                standardDate: standardDate,
                daysExpression: daysExpression,
                finalDate: finalDate,
                comment: comment,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime standardDate,
                required String daysExpression,
                Value<DateTime?> finalDate = const Value.absent(),
                Value<String?> comment = const Value.absent(),
              }) => CalculationHistoriesCompanion.insert(
                id: id,
                standardDate: standardDate,
                daysExpression: daysExpression,
                finalDate: finalDate,
                comment: comment,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CalculationHistoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CalculationHistoriesTable,
      CalculationHistory,
      $$CalculationHistoriesTableFilterComposer,
      $$CalculationHistoriesTableOrderingComposer,
      $$CalculationHistoriesTableAnnotationComposer,
      $$CalculationHistoriesTableCreateCompanionBuilder,
      $$CalculationHistoriesTableUpdateCompanionBuilder,
      (
        CalculationHistory,
        BaseReferences<
          _$AppDatabase,
          $CalculationHistoriesTable,
          CalculationHistory
        >,
      ),
      CalculationHistory,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CalculationHistoriesTableTableManager get calculationHistories =>
      $$CalculationHistoriesTableTableManager(_db, _db.calculationHistories);
}
