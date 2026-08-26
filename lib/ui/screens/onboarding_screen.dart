import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/scorecard_entry.dart';
import '../../providers/user_settings_provider.dart';
import '../../database/isar_provider.dart';
import '../../theme/app_theme.dart';
import '../shell/app_shell.dart';
import '../widgets/add_edit_habit_sheet.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final List<TextEditingController> _scorecardControllers = [TextEditingController()];
  final List<ScorecardVerdict> _scorecardVerdicts = [ScorecardVerdict.neutral];

  @override
  void dispose() {
    _pageController.dispose();
    for (var c in _scorecardControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  void _skipToScorecard() {
    _pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  void _addScorecardEntry() {
    setState(() {
      _scorecardControllers.add(TextEditingController());
      _scorecardVerdicts.add(ScorecardVerdict.neutral);
    });
  }

  Future<void> _submitScorecard() async {
    final isar = ref.read(isarProvider);
    final entries = <ScorecardEntry>[];
    String? negativeLabel;

    for (int i = 0; i < _scorecardControllers.length; i++) {
      final label = _scorecardControllers[i].text.trim();
      if (label.isNotEmpty) {
        final verdict = _scorecardVerdicts[i];
        if (verdict == ScorecardVerdict.negative && negativeLabel == null) {
          negativeLabel = label;
        }
        entries.add(ScorecardEntry()
          ..label = label
          ..verdict = verdict);
      }
    }

    if (entries.isEmpty) return; // Validation: require at least 1

    await isar.writeTxn(() async {
      await isar.scorecardEntrys.putAll(entries);
    });

    _nextPage();
    setState(() {
      _prefillHabitName = negativeLabel;
    });
  }

  String? _prefillHabitName;

  Future<void> _completeOnboarding() async {
    final settingsNotifier = ref.read(userSettingsProvider.notifier);
    await settingsNotifier.updateSettings(
      ref.read(userSettingsProvider).copyWith(onboardingCompleted: true),
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // Manual navigation only
          children: [
            _buildPrimerPage(
              "Most habit trackers measure whether you did it.",
              showSkip: true,
            ),
            _buildPrimerPage(
              "Forge helps you build the system that makes it automatic.",
              showSkip: true,
            ),
            _buildScorecardPage(),
            _buildCreateHabitPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimerPage(String text, {required bool showSkip}) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing2xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Spacer(),
          Text(
            text,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          Spacer(),
          if (showSkip)
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: _skipToScorecard,
                child: Text('Skip', style: TextStyle(color: AppTheme.textSecondary)),
              ),
            ),
          const SizedBox(height: AppTheme.spacingXl),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGrowthFill,
              foregroundColor: AppTheme.textPrimary,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusButton),
            ),
            onPressed: _nextPage,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildScorecardPage() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "The Habit Scorecard",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            "List your current daily habits and score them.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacing2xl),
          Expanded(
            child: ListView.builder(
              itemCount: _scorecardControllers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingLg),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _scorecardControllers[index],
                          decoration: InputDecoration(
                            hintText: 'e.g. Wake up, Check phone...',
                            filled: true,
                            fillColor: AppTheme.bgSurface,
                            border: OutlineInputBorder(
                              borderRadius: AppTheme.radiusButton,
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: TextStyle(color: AppTheme.textPrimary),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      _buildVerdictSelector(index),
                    ],
                  ),
                );
              },
            ),
          ),
          TextButton.icon(
            onPressed: _addScorecardEntry,
            icon: const Icon(Icons.add, color: AppTheme.accentGrowthFill),
            label: Text('Add another', style: TextStyle(color: AppTheme.accentGrowthFill)),
          ),
          const SizedBox(height: AppTheme.spacingXl),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGrowthFill,
              foregroundColor: AppTheme.textPrimary,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusButton),
            ),
            onPressed: () {
              bool hasValid = _scorecardControllers.any((c) => c.text.trim().isNotEmpty);
              if (hasValid) {
                _submitScorecard();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please add at least one habit.')),
                );
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildVerdictSelector(int index) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgSurfaceRaised,
        borderRadius: AppTheme.radiusButton,
        border: Border.all(color: AppTheme.borderStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildVerdictButton(index, ScorecardVerdict.positive, '+'),
          _buildVerdictButton(index, ScorecardVerdict.neutral, '='),
          _buildVerdictButton(index, ScorecardVerdict.negative, '-'),
        ],
      ),
    );
  }

  Widget _buildVerdictButton(int index, ScorecardVerdict verdict, String label) {
    final isSelected = _scorecardVerdicts[index] == verdict;
    Color activeColor = AppTheme.textPrimary;
    if (isSelected) {
      if (verdict == ScorecardVerdict.positive) activeColor = AppTheme.accentGrowthFill;
      if (verdict == ScorecardVerdict.negative) activeColor = AppTheme.accentRecoverFill; // Not using danger by design
    }

    return Semantics(
      button: true,
      label: 'Score $label',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _scorecardVerdicts[index] = verdict;
          });
        },
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          color: isSelected ? AppTheme.bgSurface : Colors.transparent,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? activeColor : AppTheme.textMuted,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateHabitPage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Text(
            "Create Your First Habit",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        Expanded(
          child: AddEditHabitSheet(
            initialName: _prefillHabitName,
            isOnboarding: true,
            onSaved: _completeOnboarding,
          ),
        ),
      ],
    );
  }
}
