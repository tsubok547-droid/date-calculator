import 'package:flutter/material.dart';
import '../widgets/settings/history_settings_section.dart';
import '../widgets/settings/integration_settings_section.dart';
import '../widgets/settings/shortcut_settings_section.dart';
import '../widgets/settings/theme_settings_section.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('機能設定'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          ShortcutSettingsSection(),
          SizedBox(height: 16),
          ThemeSettingsSection(),
          SizedBox(height: 16),
          HistorySettingsSection(),
          SizedBox(height: 16),
          IntegrationSettingsSection(),
        ],
      ),
    );
  }
}