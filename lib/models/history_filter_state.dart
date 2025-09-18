enum FilterLogic { and, or }

class HistoryFilterState {
  final String? comment;
  final DateTime? standardDateStart;
  final DateTime? standardDateEnd;
  final DateTime? finalDateStart;
  final DateTime? finalDateEnd;
  final FilterLogic logic;

  HistoryFilterState({
    this.comment,
    this.standardDateStart,
    this.standardDateEnd,
    this.finalDateStart,
    this.finalDateEnd,
    this.logic = FilterLogic.and,
  });

  // 今後のためにコピー機能も用意しておく
  HistoryFilterState copyWith({
    String? comment,
    DateTime? standardDateStart,
    DateTime? standardDateEnd,
    DateTime? finalDateStart,
    DateTime? finalDateEnd,
    FilterLogic? logic,
  }) {
    return HistoryFilterState(
      comment: comment ?? this.comment,
      standardDateStart: standardDateStart ?? this.standardDateStart,
      standardDateEnd: standardDateEnd ?? this.standardDateEnd,
      finalDateStart: finalDateStart ?? this.finalDateStart,
      finalDateEnd: finalDateEnd ?? this.finalDateEnd,
      logic: logic ?? this.logic,
    );
  }
}