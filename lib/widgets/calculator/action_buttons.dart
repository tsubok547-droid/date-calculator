// lib/widgets/calculator/action_buttons.dart

import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onResetToToday;
  final VoidCallback onCalendarModeChanged;
  final bool isJapaneseCalendar;

  const ActionButtons({
    super.key,
    required this.onResetToToday,
    required this.onCalendarModeChanged,
    required this.isJapaneseCalendar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.today, size: 18),
              label: const Text('今日'),
              onPressed: onResetToToday,
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.switch_left, size: 18),
              label: Text(isJapaneseCalendar ? '西暦へ' : '和暦へ'),
              onPressed: onCalendarModeChanged,
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          ),
        ],
      ),
    );
  }
}