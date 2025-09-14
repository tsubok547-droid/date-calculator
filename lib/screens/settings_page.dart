import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/services_provider.dart';
import '../services/settings_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late List<int> _currentShortcuts;
  late SettingsService _settingsService;
  late bool _isAddEventToCalendarEnabled;

  final List<int> _weekOptions = const [7, 14, 21, 28, 42, 49, 56, 63, 70, 77, 84, 91, 98];
  final List<int> _monthOptions = const [30, 60, 90, 120];

  final Map<String, Color> _predefinedColors = {
    'インディゴ': Colors.indigo,
    'アッシュグレー': const Color(0xFF78909C),
    'ダスティミント': const Color(0xFF80CBC4),
    'スカイブルー': const Color(0xFF64B5F6),
    'ラベンダー': const Color(0xFFB39DDB),
    'アイボリー': const Color(0xFFFFF9C4),
    'ダスティローズ': const Color(0xFFE57373),
  };

  @override
  void initState() {
    super.initState();
    _settingsService = ref.read(settingsServiceProvider);
    _currentShortcuts = List.from(_settingsService.getShortcutValues());
    _isAddEventToCalendarEnabled = _settingsService.shouldAddEventToCalendar();
  }

  Future<int?> _showShortcutSelectionDialog(BuildContext context) {
    final allOptions = [..._weekOptions, ..._monthOptions]..sort();

    return showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('日数を選択'),
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allOptions.length,
              itemBuilder: (context, index) {
                final value = allOptions[index];
                return ListTile(
                  title: Text(
                    _formatShortcutValue(value),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.of(context).pop(value);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _restoreDefaults() async {
    await _settingsService.restoreDefaultShortcuts();
    setState(() {
      _currentShortcuts = List.from(SettingsService.defaultShortcuts);
    });
    ref.invalidate(settingsServiceProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ショートカットをデフォルトに戻しました。')),
      );
    }
  }

  void _onShortcutChanged(int slotIndex, int? newValue) async {
    if (newValue == null) return;
    setState(() {
      _currentShortcuts[slotIndex] = newValue;
    });
    await _settingsService.saveShortcutValues(_currentShortcuts);
    ref.invalidate(settingsServiceProvider);
  }

  void _changeColor(Color color) {
    final settingsService = ref.read(settingsServiceProvider);
    settingsService.setPrimaryColor(color).then((_) {
      ref.invalidate(settingsServiceProvider);
    });
  }

  void _showColorPicker() {
    Color pickerColor = _settingsService.getPrimaryColor();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('カスタムカラーを選択'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) => pickerColor = color,
            ),
          ),
          actions: [
            TextButton(
              child: const Text('決定'),
              onPressed: () {
                _changeColor(pickerColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showThemeColorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('テーマカラーを選択'),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _predefinedColors.entries.map((entry) {
                final color = entry.value;
                final name = entry.key;
                return ChoiceChip(
                  label: Text(name),
                  selected: _settingsService.getPrimaryColor() == color,
                  onSelected: (selected) {
                    if (selected) {
                      _changeColor(color);
                      Navigator.of(context).pop();
                    }
                  },
                  avatar: CircleAvatar(backgroundColor: color),
                  shape: const StadiumBorder(),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _formatShortcutValue(int days) {
    if (days % 30 == 0 && days > 0) {
      return '+$days (${days ~/ 30}月)';
    }
    if (days % 7 == 0 && days > 0) {
      return '+$days (${days ~/ 7}週)';
    }
    return '+$days 日';
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _settingsService.getPrimaryColor();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('機能設定'),
        // --- ▼▼▼ [修正] AppBarのデフォルトに戻すボタンを削除 ▼▼▼ ---
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.restore),
        //     tooltip: 'デフォルトに戻す',
        //     onPressed: _restoreDefaults,
        //   ),
        // ],
        // --- ▲▲▲ ここまで ▲▲▲ ---
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              key: const PageStorageKey('shortcut_settings'),
              leading: const Icon(Icons.touch_app_outlined),
              title: Text('ショートカット設定', style: theme.textTheme.titleLarge),
              subtitle: const Text('6つのボタンに日数を割り当てます'),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                  child: Text('6つのショートカットボタンに、よく使う日数を割り当てます。'),
                ),
                for (int i = 0; i < 6; i++)
                  _buildShortcutSettingTile(
                    context: context,
                    slotNumber: i + 1,
                    currentValue: _currentShortcuts[i],
                    onChanged: (newValue) => _onShortcutChanged(i, newValue),
                  ),
                // --- ▼▼▼ [修正] ショートカット設定内にリセットボタンを配置 ▼▼▼ ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.restore, size: 18),
                    label: const Text('ショートカットをデフォルトに戻す'),
                    onPressed: _restoreDefaults,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                    ),
                  ),
                ),
                // --- ▲▲▲ ここまで ▲▲▲ ---
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              key: const PageStorageKey('theme_settings'),
              leading: const Icon(Icons.palette_outlined),
              title: Text('テーマカラーの変更', style: theme.textTheme.titleLarge),
              subtitle: const Text('アプリの見た目を変更します'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                        leading: CircleAvatar(backgroundColor: primaryColor),
                        title: const Text('現在のテーマカラー', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          _predefinedColors.entries
                            .firstWhere(
                              (entry) => entry.value == primaryColor, 
                              orElse: () => const MapEntry('カスタム', Colors.grey)
                            ).key,
                        ),
                        trailing: const Icon(Icons.edit),
                        onTap: _showThemeColorDialog,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300)
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.color_lens_outlined),
                        label: const Text('カスタムカラーを選択...'),
                        onPressed: _showColorPicker,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              key: const PageStorageKey('integration_settings'),
              leading: const Icon(Icons.extension_outlined),
              title: Text('連携機能', style: theme.textTheme.titleLarge),
              subtitle: const Text('他のアプリとの連携を設定します'),
              children: [
                SwitchListTile(
                  title: const Text('カレンダーに予定を追加', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('計算完了後、カレンダーアプリに予定を追加する確認画面を表示します。'),
                  value: _isAddEventToCalendarEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _isAddEventToCalendarEnabled = value;
                    });
                    _settingsService.setAddEventToCalendar(value);
                    ref.invalidate(settingsServiceProvider);
                  },
                  secondary: const Icon(Icons.calendar_today_outlined),
                  contentPadding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutSettingTile({
    required BuildContext context,
    required int slotNumber,
    required int currentValue,
    required ValueChanged<int?> onChanged,
  }) {
    return ListTile(
      title: Text(
        'ボタン $slotNumber',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatShortcutValue(currentValue),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_drop_down, color: Colors.grey),
        ],
      ),
      onTap: () async {
        final int? newValue = await _showShortcutSelectionDialog(context);
        if (newValue != null) {
          onChanged(newValue);
        }
      },
    );
  }
}