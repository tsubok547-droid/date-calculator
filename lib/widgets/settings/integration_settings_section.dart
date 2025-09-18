import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/services_provider.dart';
import '../../services/settings_service.dart';

class IntegrationSettingsSection extends ConsumerStatefulWidget {
  const IntegrationSettingsSection({super.key});

  @override
  ConsumerState<IntegrationSettingsSection> createState() =>
      _IntegrationSettingsSectionState();
}

class _IntegrationSettingsSectionState extends ConsumerState<IntegrationSettingsSection> {
  late bool _isAddEventToCalendarEnabled;
  late final SettingsService _settingsService;

  @override
  void initState() {
    super.initState();
    _settingsService = ref.read(settingsServiceProvider);
    _isAddEventToCalendarEnabled = _settingsService.shouldAddEventToCalendar();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: const PageStorageKey('integration_settings'),
        leading: const Icon(Icons.extension_outlined),
        title: Text('連携機能', style: theme.textTheme.titleLarge),
        subtitle: const Text('他のアプリとの連携を設定します'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
            child: SwitchListTile(
              title: const Text('カレンダーに予定を追加',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle:
                  const Text('計算完了後、カレンダーアプリに予定を追加する確認画面を表示します。'),
              value: _isAddEventToCalendarEnabled,
              onChanged: (bool value) {
                setState(() {
                  _isAddEventToCalendarEnabled = value;
                });
                _settingsService.setAddEventToCalendar(value);
                ref.invalidate(settingsServiceProvider);
              },
              secondary: const Icon(Icons.calendar_today_outlined),
              contentPadding: const EdgeInsets.symmetric(horizontal: 0),
            ),
          ),
        ],
      ),
    );
  }
}