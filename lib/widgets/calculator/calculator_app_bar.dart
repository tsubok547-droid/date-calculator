import 'package:flutter/material.dart';
import '../../screens/settings_page.dart';

class CalculatorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onNavigateToHistory;
  final VoidCallback onShowVersionInfo;
  // --- ▼▼▼ 2つのコールバックを追加 ▼▼▼ ---
  final VoidCallback onExportHistory;
  final VoidCallback onImportHistory;
  // --- ▲▲▲ ここまで ▲▲▲ ---

  const CalculatorAppBar({
    super.key,
    required this.onNavigateToHistory,
    required this.onShowVersionInfo,
    // --- ▼▼▼ コンストラクタに追加 ▼▼▼ ---
    required this.onExportHistory,
    required this.onImportHistory,
    // --- ▲▲▲ ここまで ▲▲▲ ---
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
            // --- ▼▼▼ エクスポート・インポートボタンを設置 ▼▼▼ ---
            MenuItemButton(
              onPressed: onExportHistory,
              child: const Text('履歴をエクスポート...'),
            ),
            MenuItemButton(
              onPressed: onImportHistory,
              child: const Text('履歴をインポート...'),
            ),
            // --- ▲▲▲ ここまで ▲▲▲ ---
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