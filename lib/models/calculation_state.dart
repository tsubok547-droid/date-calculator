// lib/models/calculation_state.dart

enum ActiveField { standardDate, daysExpression, finalDate }

class CalculationState {
  final DateTime standardDate;
  final String daysExpression;
  final DateTime? finalDate;
  final ActiveField activeField;
  final String? comment;

  CalculationState({
    required this.standardDate,
    required this.daysExpression,
    this.finalDate,
    this.activeField = ActiveField.daysExpression,
    this.comment,
  });

  CalculationState copyWith({
    DateTime? standardDate,
    String? daysExpression,
    DateTime? finalDate,
    ActiveField? activeField,
    String? comment,
    bool forceFinalDateNull = false,
  }) {
    return CalculationState(
      standardDate: standardDate ?? this.standardDate,
      daysExpression: daysExpression ?? this.daysExpression,
      finalDate: forceFinalDateNull ? null : (finalDate ?? this.finalDate),
      activeField: activeField ?? this.activeField,
      comment: comment ?? this.comment,
    );
  }

  Map<String, dynamic> toJson() => {
        'standardDate': standardDate.toIso8601String(),
        'daysExpression': daysExpression,
        'finalDate': finalDate?.toIso8601String(),
        'comment': comment,
      };

  factory CalculationState.fromJson(Map<String, dynamic> json) =>
      CalculationState(
        standardDate: DateTime.parse(json['standardDate']),
        daysExpression: json['daysExpression'],
        finalDate: json['finalDate'] != null
            ? DateTime.parse(json['finalDate'])
            : null,
        comment: json['comment'],
      );
}