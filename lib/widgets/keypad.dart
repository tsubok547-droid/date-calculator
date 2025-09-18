import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../utils/constants.dart';

class Keypad extends StatelessWidget {
  final Function(String) onButtonPressed;
  final Function(int) onShortcutPressed;
  final bool areInputsDisabled;
  final SettingsService settingsService;

  const Keypad({
    super.key,
    required this.onButtonPressed,
    required this.onShortcutPressed,
    required this.areInputsDisabled,
    required this.settingsService,
  });

  @override
  Widget build(BuildContext context) {
    final shortcutValues = settingsService.getShortcutValues();

    return Column(
      children: [
        Expanded(
          flex: 2,
          child: Row(children: [
            _buildShortcutButton(context, shortcutValues[0]),
            _buildShortcutButton(context, shortcutValues[1]),
            _buildShortcutButton(context, shortcutValues[2]),
          ]),
        ),
        Expanded(
          flex: 2,
          child: Row(children: [
            _buildShortcutButton(context, shortcutValues[3]),
            _buildShortcutButton(context, shortcutValues[4]),
            _buildShortcutButton(context, shortcutValues[5]),
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
            _buildKeypadButton(context, AppConstants.keyBackspace)
          ]),
        ),
        Expanded(
          flex: 4,
          child: Row(
            children: [
              _buildKeypadButton(context, AppConstants.keyClear),
              _buildKeypadButton(context, '0', flex: 2),
              _buildKeypadButton(context, AppConstants.keyEnter),
            ],
          ),
        ),
      ],
    );
  }

  /// 【修正】Enterキーの無効化条件を変更
  Widget _buildKeypadButton(BuildContext context, String text, {int flex = 1}) {
    final bool isNumberButton = "0123456789".contains(text);
    final Color? buttonColor = isNumberButton ? null : Theme.of(context).colorScheme.secondaryContainer;
    final Color? textColor = isNumberButton ? null : Theme.of(context).colorScheme.onSecondaryContainer;
    final bool shouldBeDisabled = areInputsDisabled && text != 'C' && text != AppConstants.keyEnter;

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
          onPressed: shouldBeDisabled ? null : () => onButtonPressed(text),
          child: Text(text),
        ),
      ),
    );
  }

  /// 【修正】ショートカットキーを常に有効化
  Widget _buildShortcutButton(BuildContext context, int days) {
    final Color baseColor = Theme.of(context).colorScheme.primary;
    final HSLColor hslColor = HSLColor.fromColor(baseColor);
    final HSLColor darkerHslColor = hslColor.withLightness((hslColor.lightness - 0.15).clamp(0.0, 1.0));
    final Color buttonColor = darkerHslColor.toColor();
    final int weeks = days ~/ 7;
    
    final String buttonText = (days % 7 == 0) ? '+$days ($weeks週)' : '+$days';

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
          onPressed: () => onShortcutPressed(days),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(buttonText, maxLines: 1),
          ),
        ),
      ),
    );
  }
}