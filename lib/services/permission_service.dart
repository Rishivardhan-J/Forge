import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

class PermissionService {
  static const _notificationAskedKey = 'forge_notification_asked';

  static Future<bool> hasAskedNotification() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationAskedKey) ?? false;
  }

  static Future<void> markNotificationAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationAskedKey, true);
  }

  static Future<bool> checkAndRequestNotificationPermission(BuildContext context) async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;

    if (!context.mounted) return false;
    // Soft ask first
    final bool? proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSurfaceRaised,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusCard),
        title: Text(
          'Enable Reminders',
          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Reminders make your cue obvious, so you don\'t have to rely on memory to show up.',
          style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGrowthFill,
              foregroundColor: AppTheme.bgBase,
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusButton),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enable Reminders'),
          ),
        ],
      ),
    );

    await markNotificationAsked();

    if (proceed == true) {
      final newStatus = await Permission.notification.request();
      return newStatus.isGranted;
    }
    return false;
  }

  static Future<bool> requestForegroundLocationPermission(BuildContext context) async {
    final status = await Permission.locationWhenInUse.status;
    if (status.isGranted) return true;

    if (!context.mounted) return false;
    final bool? proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSurfaceRaised,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusCard),
        title: Text(
          'Location Access',
          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Forge needs access to your location while using the app to help you set up geofence reminders.',
          style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGrowthFill,
              foregroundColor: AppTheme.bgBase,
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusButton),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (proceed == true) {
      final newStatus = await Permission.locationWhenInUse.request();
      if (newStatus.isPermanentlyDenied) {
        // We can show a dialog or snackbar to go to settings if needed, 
        // but spec says don't nag. The user can go to Settings tab to see it.
        return false;
      }
      return newStatus.isGranted;
    }
    return false;
  }

  static Future<bool> requestBackgroundLocationPermission(BuildContext context) async {
    // Requires foreground to be granted first
    if (!(await Permission.locationWhenInUse.isGranted)) {
      return false;
    }

    final status = await Permission.locationAlways.status;
    if (status.isGranted) return true;

    if (!context.mounted) return false;
    final bool? proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSurfaceRaised,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusCard),
        title: Text(
          'Background Location',
          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary),
        ),
        content: Text(
          'To notify you when you arrive, Forge needs location access even when the app is closed. You may need to select "Allow all the time" in the system settings.',
          style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGrowthFill,
              foregroundColor: AppTheme.bgBase,
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusButton),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (proceed == true) {
      final newStatus = await Permission.locationAlways.request();
      if (newStatus.isPermanentlyDenied) {
        // Deep link to settings will be handled from the Settings Tab
        return false;
      }
      return newStatus.isGranted;
    }
    return false;
  }
}
