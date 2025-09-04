// lib/widgets/calculator/display_fields.dart

import 'package:flutter/material.dart';
import '../../models/calculation_state.dart';
import '../../utils/date_formatter.dart';

class DisplayFields extends StatelessWidget {
  final CalculationState calculationState;
  final bool isJapaneseCalendar;
  final bool isDaysExpressionHighlighted;
  final bool isFinalDateHighlighted;
  final Function(ActiveField) onSelectDate;

  const DisplayFields({
    super.key,
    required this.calculationState,
    required this.isJapaneseCalendar,
    required this.isDaysExpressionHighlighted,
    required this.isFinalDateHighlighted,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SingleDisplayField(
          label: '基準日',
          value: formatDate(
            calculationState.standardDate,
            isJapanese: isJapaneseCalendar,
            style: DateFormatStyle.full,
          ),
          isBase: true,
          isFocused: calculationState.activeField == ActiveField.standardDate,
          onTap: () => onSelectDate(ActiveField.standardDate),
        ),
        const SizedBox(height: 8),
        _SingleDisplayField(
          label: '日数',
          value: calculationState.daysExpression,
          isBase: false,
          isFocused: calculationState.activeField == ActiveField.daysExpression,
          onTap: () => onSelectDate(ActiveField.daysExpression),
          isAnimating: isDaysExpressionHighlighted,
        ),
        const SizedBox(height: 8),
        _SingleDisplayField(
          label: '最終日',
          value: formatDate(
            calculationState.finalDate,
            isJapanese: isJapaneseCalendar,
            style: DateFormatStyle.full,
          ),
          isBase: false,
          isFocused: calculationState.activeField == ActiveField.finalDate,
          onTap: () => onSelectDate(ActiveField.finalDate),
          isAnimating: isFinalDateHighlighted,
        ),
      ],
    );
  }
}

class _SingleDisplayField extends StatelessWidget {
  final String label;
  final String value;
  final bool isBase;
  final bool isFocused;
  final VoidCallback onTap;
  final bool isAnimating;

  const _SingleDisplayField({
    required this.label,
    required this.value,
    required this.isBase,
    required this.isFocused,
    required this.onTap,
    this.isAnimating = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final Color highlightColor = colorScheme.tertiaryContainer;
    final bool isHighlighted = isBase || isFocused;
    final Color baseBackgroundColor = isHighlighted
        ? colorScheme.primaryContainer
        : theme.scaffoldBackgroundColor;
    final Color backgroundColor = isAnimating ? highlightColor : baseBackgroundColor;
    final Color borderColor = isFocused ? colorScheme.primary : Colors.grey.shade300;
    final bool isDaysField = label == '日数';
    const double fontSize = 32;

    return SizedBox(
      height: 80,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isFocused ? 2.0 : 1.0),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Align(
                      alignment: isDaysField ? Alignment.centerRight : Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          value,
                          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}