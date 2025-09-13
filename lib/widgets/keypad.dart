// lib/widgets/keypad.dart

import 'package:flutter/material.dart';

class Keypad extends StatelessWidget {
  final Function(String) onButtonPressed;
  final Function(int) onShortcutPressed;
  // --- ▼ 変更点 ▼ ---
  final bool areInputsDisabled; // キーパッドが無効かどうかの状態を受け取る

  const Keypad({
    super.key,
    required this.onButtonPressed,
    required this.onShortcutPressed,
    required this.areInputsDisabled, // コンストラクタに追加
  });
  // --- ▲ ここまで ▲ ---

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: Row(children: [
            _buildShortcutButton(context, 7),
            _buildShortcutButton(context, 14),
            _buildShortcutButton(context, 28),
          ]),
        ),
        Expanded(
          flex: 2,
          child: Row(children: [
            _buildShortcutButton(context, 56),
            _buildShortcutButton(context, 84),
            _buildShortcutButton(context, 91),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          flex: 4,
          child: Row(children: [
            _buildKeypadButton(context, '7'),
            _buildKeypadButton(context, '8'),
            _buildKeypadButton(context, '9'),
            _buildKeypadButton(context, '+')
          ]),
        ),
        Expanded(
          flex: 4,
          child: Row(children: [
            _buildKeypadButton(context, '4'),
            _buildKeypadButton(context, '5'),
            _buildKeypadButton(context, '6'),
            _buildKeypadButton(context, '-')
          ]),
        ),
        Expanded(
          flex: 4,
          child: Row(children: [
            _buildKeypadButton(context, '1'),
            _buildKeypadButton(context, '2'),
            _buildKeypadButton(context, '3'),
            _buildKeypadButton(context, '←')
          ]),
        ),
        Expanded(
          flex: 4,
          child: Row(
            children: [
              _buildKeypadButton(context, 'C'),
              _buildKeypadButton(context, '0', flex: 2),
              _buildKeypadButton(context, 'Ent'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeypadButton(BuildContext context, String text, {int flex = 1}) {
    final bool isNumberButton = "0123456789".contains(text);
    final Color? buttonColor = isNumberButton ? null : Theme.of(context).colorScheme.secondaryContainer;
    final Color? textColor = isNumberButton ? null : Theme.of(context).colorScheme.onSecondaryContainer;
    
    // C以外のボタンを無効化するフラグ
    final bool shouldBeDisabled = areInputsDisabled && text != 'C';

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(double.infinity),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            backgroundColor: buttonColor,
            foregroundColor: textColor,
            textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          // 無効化フラグがtrueの場合、onPressedにnullを設定してボタンを無効化
          onPressed: shouldBeDisabled ? null : () => onButtonPressed(text),
          child: Text(text),
        ),
      ),
    );
  }

  Widget _buildShortcutButton(BuildContext context, int days) {
    final Color baseColor = Theme.of(context).colorScheme.primary;
    final HSLColor hslColor = HSLColor.fromColor(baseColor);
    final HSLColor darkerHslColor = hslColor.withLightness((hslColor.lightness - 0.15).clamp(0.0, 1.0));
    final Color buttonColor = darkerHslColor.toColor();
    final int weeks = days ~/ 7;
    final String buttonText = '+$days ($weeks週)';

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(double.infinity),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          // areInputsDisabledがtrueの場合、onPressedにnullを設定してボタンを無効化
          onPressed: areInputsDisabled ? null : () => onShortcutPressed(days),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(buttonText, maxLines: 1),
          ),
        ),
      ),
    );
  }
}