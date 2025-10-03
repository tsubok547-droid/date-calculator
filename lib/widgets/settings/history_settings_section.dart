import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/history_duplicate_policy.dart';
import '../../providers/services_provider.dart';

class HistorySettingsSection extends ConsumerStatefulWidget {
  const HistorySettingsSection({super.key});

  @override
  ConsumerState<HistorySettingsSection> createState() =>
      _HistorySettingsSectionState();
}

class _HistorySettingsSectionState extends ConsumerState<HistorySettingsSection> {
  late HistoryDuplicatePolicy _historyDuplicatePolicy;

  @override
  void initState() {
    super.initState();
    _historyDuplicatePolicy =
        ref.read(settingsServiceProvider).getHistoryDuplicatePolicy();
  }

  void _setHistoryDuplicatePolicy(HistoryDuplicatePolicy? newPolicy) async {
    if (newPolicy != null) {
      setState(() {
        _historyDuplicatePolicy = newPolicy;
      });
      await ref
          .read(settingsServiceProvider)
          .setHistoryDuplicatePolicy(newPolicy);
      ref.invalidate(settingsServiceProvider);
    }
  }

  Widget _buildPolicyRadioListTile({
    required String title,
    required String subtitle,
    required HistoryDuplicatePolicy value,
    required HistoryDuplicatePolicy groupValue,
    required ValueChanged<HistoryDuplicatePolicy?> onChanged,
  }) {
    return RadioListTile<HistoryDuplicatePolicy>(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle:
          Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      value: value,
      // ignore: deprecated_member_use
      groupValue: groupValue,
      // ignore: deprecated_member_use
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      controlAffinity: ListTileControlAffinity.leading,
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: const PageStorageKey('history_settings'),
        leading: const Icon(Icons.history_outlined),
        title: Text('履歴設定', style: theme.textTheme.titleLarge),
        subtitle: const Text('計算履歴の管理方法を設定します'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '履歴の重複削除ポリシー',
                  style: theme.textTheme.titleMedium!
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const Text(
                  '履歴保存時に、過去の重複する履歴をどのように扱うかを設定します。',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                _buildPolicyRadioListTile(
                  title: '常に新しい履歴を追加',
                  subtitle: 'コメントや計算内容が同じでも、全ての履歴を保存します。',
                  value: HistoryDuplicatePolicy.keepAll,
                  groupValue: _historyDuplicatePolicy,
                  onChanged: _setHistoryDuplicatePolicy,
                ),
                _buildPolicyRadioListTile(
                  title: 'コメントが同じ場合、古い履歴を削除',
                  subtitle: 'コメントが同じであれば、古い計算履歴を削除して新しいものに置き換えます（デフォルト）。',
                  value: HistoryDuplicatePolicy.removeSameComment,
                  groupValue: _historyDuplicatePolicy,
                  onChanged: _setHistoryDuplicatePolicy,
                ),
                _buildPolicyRadioListTile(
                  title: 'コメントと計算内容が同じ場合のみ削除',
                  subtitle: 'コメント、基準日、日数表現が全て同じ場合にのみ、古い履歴を削除します。',
                  value: HistoryDuplicatePolicy.removeSameCalculation,
                  groupValue: _historyDuplicatePolicy,
                  onChanged: _setHistoryDuplicatePolicy,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}