// lib/widgets/calculator/calculator_app_bar.dart

import 'package:flutter/material.dart';

class CalculatorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onNavigateToHistory;
  final Function(Color) onColorChanged;
  final VoidCallback onShowColorPicker;
  final VoidCallback onShowVersionInfo;
  final Map<String, Color> predefinedColors;

  const CalculatorAppBar({
    super.key,
    required this.onNavigateToHistory,
    required this.onColorChanged,
    required this.onShowColorPicker,
    required this.onShowVersionInfo,
    required this.predefinedColors,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('くすりの日数計算機'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: [
        MenuAnchor(
          builder: (context, controller, child) {
            return IconButton(
              onPressed: () => controller.isOpen ? controller.close() : controller.open(),
              icon: const Icon(Icons.more_vert),
              tooltip: 'メニュー',
            );
          },
          menuChildren: [
            MenuItemButton(onPressed: onNavigateToHistory, child: const Text('計算履歴')),
            const Divider(),
            SubmenuButton(
              menuChildren: [
                ...predefinedColors.entries.map((entry) {
                  return MenuItemButton(
                    onPressed: () => onColorChanged(entry.value),
                    child: Text(entry.key),
                  );
                }),
                const Divider(),
                MenuItemButton(onPressed: onShowColorPicker, child: const Text('カスタム...')),
              ],
              child: const Text('テーマカラーを変更'),
            ),
            MenuItemButton(onPressed: onShowVersionInfo, child: const Text('バージョン情報')),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}