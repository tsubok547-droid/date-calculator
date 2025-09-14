import 'package:flutter/material.dart';
import '../../screens/settings_page.dart'; // 設定画面をインポート

class CalculatorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onNavigateToHistory;
  // ▼▼▼ テーマカラー関連のプロパティはもう不要なので削除 ▼▼▼
  // final Function(Color) onColorChanged;
  // final VoidCallback onShowColorPicker;
  // final Map<String, Color> predefinedColors;
  // ▲▲▲ ここまで ▲▲▲
  final VoidCallback onShowVersionInfo;


  const CalculatorAppBar({
    super.key,
    required this.onNavigateToHistory,
    // ▼▼▼ コンストラクタからも削除 ▼▼▼
    // required this.onColorChanged,
    // required this.onShowColorPicker,
    // required this.predefinedColors,
    // ▲▲▲ ここまで ▲▲▲
    required this.onShowVersionInfo,
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
            MenuItemButton(
              onPressed: onNavigateToHistory,
              child: const Text('計算履歴'),
            ),
            // TODO: 履歴のエクスポート/インポート機能はここに追加
            const Divider(),
            MenuItemButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
              child: const Text('機能設定'),
            ),
            const Divider(),
            // ▼▼▼ 不要になったSubmenuButtonを削除 ▼▼▼
            // SubmenuButton(...)
            // ▲▲▲ ここまで ▲▲▲
            MenuItemButton(
              onPressed: onShowVersionInfo,
              child: const Text('バージョン情報'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}