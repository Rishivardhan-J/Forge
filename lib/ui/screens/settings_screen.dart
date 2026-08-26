import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../theme/app_theme.dart';
import '../../providers/user_settings_provider.dart';
import '../../database/isar_provider.dart';
import '../../services/backup_restore_service.dart';
import '../../services/export_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with WidgetsBindingObserver {
  PermissionStatus? _notificationStatus;
  PermissionStatus? _locationForegroundStatus;
  PermissionStatus? _locationBackgroundStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPermissionStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPermissionStatuses();
    }
  }

  Future<void> _loadPermissionStatuses() async {
    final notif = await Permission.notification.status;
    final locFg = await Permission.locationWhenInUse.status;
    final locBg = await Permission.locationAlways.status;
    if (mounted) {
      setState(() {
        _notificationStatus = notif;
        _locationForegroundStatus = locFg;
        _locationBackgroundStatus = locBg;
      });
    }
  }

  Widget _buildPermissionStatusIndicator(PermissionStatus? status) {
    if (status == null) return const SizedBox();
    Color color;
    String text;
    if (status.isGranted) {
      color = AppTheme.accentGrowthFill;
      text = 'Granted';
    } else if (status.isDenied || status.isPermanentlyDenied) {
      color = AppTheme.accentRecoverFill; // Amber instead of red
      text = 'Denied';
    } else {
      color = AppTheme.textMuted;
      text = 'Not asked';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(userSettingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.bgBase,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        children: [
          Text('Permissions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppTheme.spacingMd),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Notifications'),
                  subtitle: const Text('Context-aware reminders'),
                  trailing: _buildPermissionStatusIndicator(_notificationStatus),
                  onTap: () {
                    if (_notificationStatus?.isDenied == true || _notificationStatus?.isPermanentlyDenied == true) {
                      openAppSettings();
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Location (Foreground)'),
                  subtitle: const Text('For setting up geofence cues'),
                  trailing: _buildPermissionStatusIndicator(_locationForegroundStatus),
                  onTap: () {
                    if (_locationForegroundStatus?.isDenied == true || _locationForegroundStatus?.isPermanentlyDenied == true) {
                      openAppSettings();
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Location (Background)'),
                  subtitle: const Text('For triggering geofence cues'),
                  trailing: _buildPermissionStatusIndicator(_locationBackgroundStatus),
                  onTap: () {
                    if (_locationBackgroundStatus?.isDenied == true || _locationBackgroundStatus?.isPermanentlyDenied == true) {
                      openAppSettings();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),
          Text('Preferences', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppTheme.spacingMd),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Day Start Time'),
                  subtitle: Text('Current: ${settings.dayStartTime}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final parts = settings.dayStartTime.split(':');
                    final initialTime = TimeOfDay(
                      hour: int.tryParse(parts[0]) ?? 0,
                      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
                    );
                    final time = await showTimePicker(
                      context: context,
                      initialTime: initialTime,
                    );
                    if (time != null) {
                      final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                      ref.read(userSettingsProvider.notifier).updateSettings(settings.copyWith(dayStartTime: timeStr));
                    }
                  },
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Weekly Review Notification'),
                  subtitle: const Text('Sent on Sunday evenings'),
                  value: settings.weeklyReviewEnabled,
                  activeThumbColor: AppTheme.accentGrowthFill,
                  onChanged: (val) {
                    ref.read(userSettingsProvider.notifier).updateSettings(settings.copyWith(weeklyReviewEnabled: val));
                  },
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Reduce Motion'),
                  subtitle: const Text('Disable animations like the Identity Orbit'),
                  value: settings.reduceMotion,
                  activeThumbColor: AppTheme.accentGrowthFill,
                  onChanged: (val) {
                    ref.read(userSettingsProvider.notifier).updateSettings(settings.copyWith(reduceMotion: val));
                  },
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Use simple list view'),
                  subtitle: const Text('Show the interim list instead of the Transit Map'),
                  value: settings.listViewDefault,
                  activeThumbColor: AppTheme.accentGrowthFill,
                  onChanged: (val) {
                    ref.read(userSettingsProvider.notifier).updateSettings(settings.copyWith(listViewDefault: val));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
            child: Text(
              'Data Export',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Export CSV (Spreadsheet)'),
                  subtitle: const Text('Raw habit logs for analysis'),
                  trailing: const Icon(Icons.table_chart_outlined, color: AppTheme.textSecondary),
                  onTap: () async {
                    final isar = ref.read(isarProvider);
                    final success = await ExportService.exportCsv(isar);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(success ? 'CSV Export Successful' : 'CSV Export Failed')),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Export PDF (Report)'),
                  subtitle: const Text('Readable consistency report'),
                  trailing: const Icon(Icons.picture_as_pdf_outlined, color: AppTheme.textSecondary),
                  onTap: () async {
                    final isar = ref.read(isarProvider);
                    final success = await ExportService.exportPdf(isar);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(success ? 'PDF Export Successful' : 'PDF Export Failed')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
            child: Text(
              'Backup & Restore',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Backup Data (JSON)'),
                  subtitle: const Text('Export your data to a file'),
                  trailing: const Icon(Icons.upload_file, color: AppTheme.textSecondary),
                  onTap: () async {
                    final isar = ref.read(isarProvider);
                    final success = await BackupRestoreService.backupData(isar);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(success ? 'Backup Successful' : 'Backup Failed')),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Restore Data (JSON)'),
                  subtitle: const Text('Import data from a file'),
                  trailing: const Icon(Icons.download, color: AppTheme.textSecondary),
                  onTap: () async {
                    final isar = ref.read(isarProvider);
                    final success = await BackupRestoreService.restoreData(isar);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(success ? 'Restore Successful' : 'Restore Failed')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
