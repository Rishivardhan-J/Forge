import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/screens/onboarding_screen.dart';
import 'providers/user_settings_provider.dart';

import 'database/isar_provider.dart';
import 'theme/app_theme.dart';
import 'ui/shell/app_shell.dart';

import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isar = await DatabaseHelper.initIsar();
  
  await NotificationService().init();

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
      ],
      child: const ForgeApp(),
    ),
  );
}

class ForgeApp extends ConsumerWidget {
  const ForgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(userSettingsProvider);

    return MaterialApp(
      title: 'Forge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: settingsAsync.onboardingCompleted
          ? const AppShell()
          : const OnboardingScreen(),
    );
  }
}
