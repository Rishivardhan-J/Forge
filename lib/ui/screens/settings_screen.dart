import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/user_settings_provider.dart';
import '../../models/user_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Use simple list view'),
            subtitle: const Text('Show the interim list instead of the Transit Map'),
            value: settings.listViewDefault,
            activeColor: AppTheme.accentGrowthFill,
            onChanged: (val) {
              final updated = UserSettings()
                ..id = settings.id
                ..dayStartTime = settings.dayStartTime
                ..reduceMotion = settings.reduceMotion
                ..listViewDefault = val;
              ref.read(userSettingsProvider.notifier).updateSettings(updated);
            },
          ),
        ],
      ),
    );
  }
}
