import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/services_provider.dart';
import '../../services/settings_service.dart';

class ShortcutSettingsSection extends ConsumerStatefulWidget {
  const ShortcutSettingsSection({super.key});

  @override
  ConsumerState<ShortcutSettingsSection> createState() =>
      _ShortcutSettingsSectionState();
}

class _ShortcutSettingsSectionState extends ConsumerState<ShortcutSettingsSection> {
  late List<int> _currentShortcuts;
  late final SettingsService _settingsService;

  final List<int> _weekOptions = const [7, 14, 21, 28, 42, 49, 56, 63, 70, 77, 84, 91, 98];
  final List<int> _monthOptions = const [30, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _settingsService = ref.read(settingsServiceProvider);
    _currentShortcuts = List.from(_settingsService.getShortcutValues());
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

  void _onShortcutChanged(int slotIndex, int? newValue) async {
    if (newValue == null) return;
    setState(() {
      _currentShortcuts[slotIndex] = newValue;
    });
    await _settingsService.saveShortcutValues(_currentShortcuts);
    ref.invalidate(settingsServiceProvider);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
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
        ],
      ),
    );
  }
}