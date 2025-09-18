import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/services_provider.dart';

class ThemeSettingsSection extends ConsumerWidget {
  const ThemeSettingsSection({super.key});

  final Map<String, Color> _predefinedColors_ = const {
    'インディゴ': Colors.indigo,
    'アッシュグレー': Color(0xFF78909C),
    'ダスティミント': Color(0xFF80CBC4),
    'スカイブルー': Color(0xFF64B5F6),
    'ラベンダー': Color(0xFFB39DDB),
    'アイボリー': Color(0xFFFFF9C4),
    'ダスティローズ': Color(0xFFE57373),
  };

  void _changeColor(WidgetRef ref, Color color) {
    final settingsService = ref.read(settingsServiceProvider);
    settingsService.setPrimaryColor(color).then((_) {
      ref.invalidate(settingsServiceProvider);
    });
  }

  void _showColorPicker(BuildContext context, WidgetRef ref) {
    final settingsService = ref.read(settingsServiceProvider);
    Color pickerColor = settingsService.getPrimaryColor();
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
                _changeColor(ref, pickerColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showThemeColorDialog(BuildContext context, WidgetRef ref) {
    final settingsService = ref.read(settingsServiceProvider);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('テーマカラーを選択'),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _predefinedColors_.entries.map((entry) {
                final color = entry.value;
                final name = entry.key;
                return ChoiceChip(
                  label: Text(name),
                  selected: settingsService.getPrimaryColor() == color,
                  onSelected: (selected) {
                    if (selected) {
                      _changeColor(ref, color);
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsService = ref.watch(settingsServiceProvider);
    final primaryColor = settingsService.getPrimaryColor();
    final theme = Theme.of(context);

    return Card(
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
                  title: const Text('現在のテーマカラー',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    _predefinedColors_.entries
                        .firstWhere((entry) => entry.value == primaryColor,
                            orElse: () => const MapEntry('カスタム', Colors.grey))
                        .key,
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _showThemeColorDialog(context, ref),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.color_lens_outlined),
                  label: const Text('カスタムカラーを選択...'),
                  onPressed: () => _showColorPicker(context, ref),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}