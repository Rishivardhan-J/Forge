import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../../models/user_settings.dart';
import '../../models/scorecard_entry.dart';
import '../../providers/user_settings_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/identity_provider.dart';
import '../../database/isar_provider.dart';
import '../../theme/app_theme.dart';
import '../shell/app_shell.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isEditingName = false;
  List<ScorecardEntry>? _scorecardEntries;

  @override
  void initState() {
    super.initState();
    _loadScorecard();
  }

  Future<void> _loadScorecard() async {
    final isar = ref.read(isarProvider);
    final entries = await isar.scorecardEntrys.where().findAll();
    if (mounted) {
      setState(() {
        _scorecardEntries = entries;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _toggleAvatarColor(UserSettings settings) async {
    final newAccent = settings.avatarAccent == AvatarAccent.teal
        ? AvatarAccent.purple
        : AvatarAccent.teal;
    await ref.read(userSettingsProvider.notifier).updateSettings(
          settings.copyWith(avatarAccent: newAccent),
        );
  }

  Future<void> _saveName(UserSettings settings, String newName) async {
    await ref.read(userSettingsProvider.notifier).updateSettings(
          settings.copyWith(displayName: newName.trim().isEmpty ? null : newName.trim()),
        );
    setState(() {
      _isEditingName = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(userSettingsProvider);
    final habitsAsync = ref.watch(habitListProvider);
    final identitiesAsync = ref.watch(identityListProvider);

    DateTime? memberSince;
    int activeHabitsCount = 0;
    int identitiesCount = 0;
    int totalVotes = 0;

    if (habitsAsync.value != null && habitsAsync.value!.isNotEmpty) {
      final habits = habitsAsync.value!.where((h) => !h.isArchived).toList();
      activeHabitsCount = habits.length;
      if (habitsAsync.value!.isNotEmpty) {
        // Find earliest
        memberSince = habitsAsync.value!.map((h) => h.createdAt).reduce((a, b) => a.isBefore(b) ? a : b);
      }
    } else {
      memberSince = DateTime.now();
    }

    if (identitiesAsync.value != null) {
      final identities = identitiesAsync.value!.toList();
      identitiesCount = identities.length;
      for (var i in identities) {
        totalVotes += i.voteCount;
      }
    }

    final avatarColor = settings.avatarAccent == AvatarAccent.purple
        ? AppTheme.accentIdentityFill
        : AppTheme.accentGrowthFill;

    final avatarText = settings.avatarAccent == AvatarAccent.purple
        ? AppTheme.accentIdentityText
        : AppTheme.accentGrowthText;

    final displayName = settings.displayName ?? "Add your name";
    final initials = settings.displayName != null && settings.displayName!.isNotEmpty
        ? settings.displayName!.substring(0, 1).toUpperCase()
        : "?";

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTheme.bgBase,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        children: [
          // Header: Avatar and Name
          Row(
            children: [
              GestureDetector(
                onTap: () => _toggleAvatarColor(settings),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: avatarColor,
                  child: Text(
                    initials,
                    style: TextStyle(fontSize: 28, color: avatarText, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingLg),
              Expanded(
                child: _isEditingName
                    ? TextField(
                        controller: _nameController,
                        autofocus: true,
                        style: Theme.of(context).textTheme.headlineSmall,
                        decoration: const InputDecoration(
                          hintText: 'Enter your name',
                          border: UnderlineInputBorder(),
                        ),
                        onSubmitted: (val) => _saveName(settings, val),
                      )
                    : GestureDetector(
                        onTap: () {
                          _nameController.text = settings.displayName ?? '';
                          setState(() {
                            _isEditingName = true;
                          });
                        },
                        child: Text(
                          displayName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: settings.displayName == null ? AppTheme.textMuted : AppTheme.textPrimary,
                              ),
                        ),
                      ),
              ),
              if (_isEditingName)
                IconButton(
                  icon: const Icon(Icons.check, color: AppTheme.accentGrowthFill),
                  onPressed: () => _saveName(settings, _nameController.text),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Member since ${DateFormat('MMMM yyyy').format(memberSince ?? DateTime.now())}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: AppTheme.spacing2xl),

          // Factual Summary
          Text(
            'You are maintaining $activeHabitsCount active habits across $identitiesCount identities, gathering ',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyLarge,
              children: [
                TextSpan(
                  text: '$totalVotes total votes',
                  style: const TextStyle(color: AppTheme.accentGrowthFill, fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: ' for the person you want to become.'),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing2xl),

          // Original Scorecard
          Text('Your original scorecard', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppTheme.spacingLg),
          if (_scorecardEntries == null)
            const Center(child: CircularProgressIndicator())
          else if (_scorecardEntries!.isEmpty)
            Text(
              'No scorecard entries found. This is normal if you skipped the onboarding exercise.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
            )
          else
            ..._scorecardEntries!.map((entry) {
              String marker = '=';
              if (entry.verdict == ScorecardVerdict.positive) marker = '+';
              if (entry.verdict == ScorecardVerdict.negative) marker = '-';

              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        marker,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Text(entry.label, style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ],
                ),
              );
            }),
          
          const SizedBox(height: AppTheme.spacing2xl),
          const Divider(color: AppTheme.borderStrong),
          const SizedBox(height: AppTheme.spacingMd),
          
          // Links
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('View your identities'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textMuted),
            onTap: () {
              Navigator.pop(context); // Pop profile
              // Navigate to identity tab
              // We can do this by popping back to shell and setting tab?
              // The AppShell uses a local state for _currentIndex.
              // For simplicity, we just pop. The user asked for "navigates to Identity tab", 
              // which implies popping settings and switching tabs, but Riverpod doesn't control the tab index currently.
              // Actually, wait, let's just push replacement to AppShell to Identity tab, or simply push.
              Navigator.pushAndRemoveUntil(
                context, 
                MaterialPageRoute(builder: (_) => const AppShell(initialTab: 1)),
                (route) => false,
              );
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Manage your data'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textMuted),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
