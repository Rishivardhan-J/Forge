import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/habit.dart';
import '../../providers/environment_tag_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/identity_provider.dart';
import '../../providers/stack_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/permission_service.dart';

class AddEditHabitSheet extends ConsumerStatefulWidget {
  final Habit? existingHabit;
  final String? initialName;
  final bool isOnboarding;
  final VoidCallback? onSaved;

  const AddEditHabitSheet({
    super.key, 
    this.existingHabit, 
    this.initialName,
    this.isOnboarding = false,
    this.onSaved,
  });

  @override
  ConsumerState<AddEditHabitSheet> createState() => _AddEditHabitSheetState();
}

class _AddEditHabitSheetState extends ConsumerState<AddEditHabitSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _identityController;
  late final TextEditingController _cueValueController;
  late final TextEditingController _twoMinuteController;
  late final TextEditingController _temptationController;
  late final TextEditingController _envTagController;

  CueType _cueType = CueType.time;
  FrequencyType _freqType = FrequencyType.daily;
  List<int> _selectedWeekdays = [];
  int _timesPerWeek = 3;

  String? _selectedIdentityId;
  String? _selectedEnvTagId;
  String? _selectedStackId;

  double? _locationLat;
  double? _locationLng;
  double? _locationRadius;

  @override
  void initState() {
    super.initState();
    final h = widget.existingHabit;
    
    _nameController = TextEditingController(text: h?.name ?? widget.initialName ?? '');
    _identityController = TextEditingController(); // Used only if creating a new one
    _selectedIdentityId = h?.identityStatementId;

    _cueType = h?.cueType ?? CueType.time;
    _cueValueController = TextEditingController(text: h?.cueValue ?? '');
    
    _twoMinuteController = TextEditingController(text: h?.twoMinuteVersion ?? '');
    _temptationController = TextEditingController(text: h?.temptationBundle ?? '');
    
    _envTagController = TextEditingController();
    _selectedEnvTagId = h?.environmentTagId;
    _selectedStackId = h?.stackId;

    _freqType = h?.frequency.type ?? FrequencyType.daily;
    _selectedWeekdays = h?.frequency.weekdays?.toList() ?? [];
    _timesPerWeek = h?.frequency.timesPerWeek ?? 3;

    _locationLat = h?.cueLocationLat;
    _locationLng = h?.cueLocationLng;
    _locationRadius = h?.cueLocationRadius;

    // Add listeners to trigger rebuild for Save button validation
    _nameController.addListener(() => setState(() {}));
    _twoMinuteController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _identityController.dispose();
    _cueValueController.dispose();
    _twoMinuteController.dispose();
    _temptationController.dispose();
    _envTagController.dispose();
    super.dispose();
  }

  bool get _isValid {
    if (_nameController.text.trim().isEmpty) return false;
    if (_twoMinuteController.text.trim().isEmpty) return false;
    if (_freqType == FrequencyType.specificWeekdays && _selectedWeekdays.isEmpty) return false;
    return true;
  }

  Future<void> _save() async {
    if (!_isValid) return;

    // Resolve Identity
    String? identityId = _selectedIdentityId;
    if (identityId == null && _identityController.text.trim().isNotEmpty) {
      final newId = await ref.read(identityNotifierProvider).getOrCreateIdentity(_identityController.text.trim());
      identityId = newId.id.toString();
    }

    // Resolve EnvTag
    String? envTagId = _selectedEnvTagId;
    if (envTagId == null && _envTagController.text.trim().isNotEmpty) {
      final newTag = await ref.read(environmentTagNotifierProvider).getOrCreateTag(_envTagController.text.trim());
      envTagId = newTag.id.toString();
    }

    final habit = widget.existingHabit ?? Habit();
    habit
      ..name = _nameController.text.trim()
      ..identityStatementId = identityId
      ..cueType = _cueType
      ..cueValue = _cueValueController.text.trim()
      ..twoMinuteVersion = _twoMinuteController.text.trim()
      ..temptationBundle = _temptationController.text.trim().isEmpty ? null : _temptationController.text.trim()
      ..environmentTagId = envTagId
      ..cueLocationLat = _locationLat
      ..cueLocationLng = _locationLng
      ..cueLocationRadius = _locationRadius
      ..frequency = Frequency()
      ..frequency.type = _freqType
      ..frequency.weekdays = _freqType == FrequencyType.specificWeekdays ? _selectedWeekdays : null
      ..frequency.timesPerWeek = _freqType == FrequencyType.timesPerWeek ? _timesPerWeek : null;

    final savedHabit = await ref.read(habitNotifierProvider).saveHabit(habit);
    
    // Add to stack if changed
    if (_selectedStackId != widget.existingHabit?.stackId) {
      if (_selectedStackId == null) {
        await ref.read(stackNotifierProvider).moveHabitAfter(savedHabit.id.toString(), null);
      } else {
        // Find last habit in the chosen stack
        final stacks = ref.read(stackListProvider).value;
        if (stacks != null) {
          final stack = stacks.where((s) => s.id.toString() == _selectedStackId).firstOrNull;
          if (stack != null && stack.habitIds.isNotEmpty) {
            final lastHabitId = stack.habitIds.last;
            await ref.read(stackNotifierProvider).moveHabitAfter(savedHabit.id.toString(), lastHabitId);
          }
        }
      }
    }

    if (mounted) {
      if (!(await PermissionService.hasAskedNotification())) {
        await PermissionService.checkAndRequestNotificationPermission(context);
      }
      if (mounted) {
        if (widget.isOnboarding) {
          widget.onSaved?.call();
        } else {
          Navigator.pop(context);
        }
      }
    }
  }

  Future<void> _setLocation() async {
    final granted = await PermissionService.requestForegroundLocationPermission(context);
    if (granted) {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      // Also request background permission right after so geofencing can actually work
      if (mounted) {
        await PermissionService.requestBackgroundLocationPermission(context);
      }

      setState(() {
        _locationLat = pos.latitude;
        _locationLng = pos.longitude;
        _locationRadius = 100.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgSurfaceRaised,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSurfaceRaised,
        title: Text(widget.existingHabit == null ? 'New Habit' : 'Edit Habit'),
        actions: [
          TextButton(
            onPressed: _isValid ? _save : null,
            child: Text(
              'Save',
              style: TextStyle(color: _isValid ? AppTheme.accentGrowthFill : AppTheme.textMuted),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        children: [
          // 1. Name
          _buildTextField('Habit name', _nameController, maxLength: 60, requiredField: true),
          if (_nameController.text.trim().isEmpty) _buildErrorText('Name is required'),
          const SizedBox(height: AppTheme.spacingXl),

          // 2. Identity
          Text('Identity statement', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppTheme.spacingSm),
          _buildIdentitySelector(),
          if (_selectedIdentityId == null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            _buildTextField('This habit is evidence I am...', _identityController),
          ],
          const SizedBox(height: AppTheme.spacingXl),

          // 3. Cue
          Text('Cue', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppTheme.spacingSm),
          SegmentedButton<CueType>(
            segments: const [
              ButtonSegment(value: CueType.time, label: Text('Time')),
              ButtonSegment(value: CueType.location, label: Text('Location')),
              ButtonSegment(value: CueType.afterHabit, label: Text('After Habit')),
            ],
            selected: {_cueType},
            onSelectionChanged: (set) => setState(() => _cueType = set.first),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _buildCueInput(),
          const SizedBox(height: AppTheme.spacingXl),

          // 4. Frequency
          Text('Frequency', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppTheme.spacingSm),
          SegmentedButton<FrequencyType>(
            segments: const [
              ButtonSegment(value: FrequencyType.daily, label: Text('Daily')),
              ButtonSegment(value: FrequencyType.specificWeekdays, label: Text('Specific Days')),
              ButtonSegment(value: FrequencyType.timesPerWeek, label: Text('X Times')),
            ],
            selected: {_freqType},
            onSelectionChanged: (set) => setState(() => _freqType = set.first),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _buildFrequencyInput(),
          const SizedBox(height: AppTheme.spacingXl),

          // 5. 2-Minute Version
          _buildTextField('2-minute version', _twoMinuteController, requiredField: true, placeholder: "e.g. 'Put on running shoes.'"),
          if (_twoMinuteController.text.trim().isEmpty) _buildErrorText('2-minute version is required'),
          const SizedBox(height: AppTheme.spacingXl),

          // 6. Temptation Bundle
          _buildTextField('Temptation bundling (Optional)', _temptationController, placeholder: "Pair this with something you enjoy"),
          const SizedBox(height: AppTheme.spacingXl),

          // 7. Environment Tag
          Text('Environment tag (Optional)', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppTheme.spacingSm),
          _buildEnvTagSelector(),
          if (_selectedEnvTagId == null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            _buildTextField('New tag...', _envTagController),
          ],
          const SizedBox(height: AppTheme.spacingXl),

          // 8. Add to Stack
          Text('Add to stack (Optional)', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppTheme.spacingSm),
          _buildStackSelector(),

          const SizedBox(height: 100), // padding for scroll
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int? maxLength, bool requiredField = false, String? placeholder}) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label + (requiredField ? ' *' : ''),
        hintText: placeholder,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildErrorText(String error) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(error, style: const TextStyle(color: AppTheme.accentRecoverFill, fontSize: 12)),
    );
  }

  Widget _buildIdentitySelector() {
    final identitiesAsync = ref.watch(identityListProvider);
    return identitiesAsync.when(
      data: (identities) {
        if (identities.isEmpty) return const SizedBox.shrink();
        return Wrap(
          spacing: AppTheme.spacingSm,
          children: identities.map((id) {
            final isSelected = id.id.toString() == _selectedIdentityId;
            return FilterChip(
              label: Text(id.statement),
              selected: isSelected,
              selectedColor: AppTheme.accentIdentityFill.withOpacity(0.2),
              checkmarkColor: AppTheme.accentIdentityFill,
              labelStyle: TextStyle(color: isSelected ? AppTheme.accentIdentityText : AppTheme.textPrimary),
              onSelected: (selected) {
                setState(() {
                  _selectedIdentityId = selected ? id.id.toString() : null;
                });
              },
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildEnvTagSelector() {
    final tagsAsync = ref.watch(environmentTagListProvider);
    return tagsAsync.when(
      data: (tags) {
        if (tags.isEmpty) return const SizedBox.shrink();
        return Wrap(
          spacing: AppTheme.spacingSm,
          children: tags.map((t) {
            final isSelected = t.id.toString() == _selectedEnvTagId;
            return FilterChip(
              label: Text(t.label),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedEnvTagId = selected ? t.id.toString() : null;
                });
              },
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCueInput() {
    switch (_cueType) {
      case CueType.time:
        return _buildTextField('Time (HH:mm)', _cueValueController);
      case CueType.location:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField('Location description', _cueValueController),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _locationLat != null ? 'Location set (100m radius)' : 'Exact location for reminders (optional)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: _setLocation,
                  child: Text(_locationLat != null ? 'Update' : 'Set', style: const TextStyle(color: AppTheme.accentGrowthFill)),
                ),
              ],
            ),
          ],
        );
      case CueType.afterHabit:
        // Dropdown of non-archived habits
        final habitsAsync = ref.watch(habitListProvider);
        return habitsAsync.when(
          data: (habits) {
            final filtered = habits.where((h) => h.id != widget.existingHabit?.id).toList();
            if (filtered.isEmpty) {
              return const Text('No other habits available', style: TextStyle(color: AppTheme.textMuted));
            }
            return DropdownButtonFormField<String>(
              value: filtered.any((h) => h.id.toString() == _cueValueController.text) ? _cueValueController.text : null,
              items: filtered.map((h) => DropdownMenuItem(value: h.id.toString(), child: Text(h.name))).toList(),
              onChanged: (val) {
                if (val != null) _cueValueController.text = val;
              },
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Select Habit'),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (_, __) => const SizedBox.shrink(),
        );
    }
  }

  Widget _buildFrequencyInput() {
    switch (_freqType) {
      case FrequencyType.daily:
        return const SizedBox.shrink();
      case FrequencyType.timesPerWeek:
        return Row(
          children: [
            const Text('Times per week: '),
            IconButton(icon: const Icon(Icons.remove), onPressed: () => setState(() => _timesPerWeek = (_timesPerWeek > 1) ? _timesPerWeek - 1 : 1)),
            Text('$_timesPerWeek', style: Theme.of(context).textTheme.titleLarge),
            IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _timesPerWeek = (_timesPerWeek < 7) ? _timesPerWeek + 1 : 7)),
          ],
        );
      case FrequencyType.specificWeekdays:
        final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final isSelected = _selectedWeekdays.contains(index);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedWeekdays.remove(index);
                      } else {
                        _selectedWeekdays.add(index);
                      }
                    });
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppTheme.accentGrowthFill : AppTheme.bgBase,
                      border: Border.all(color: AppTheme.borderStrong),
                    ),
                    alignment: Alignment.center,
                    child: Text(days[index], style: TextStyle(color: isSelected ? AppTheme.bgBase : AppTheme.textPrimary)),
                  ),
                );
              }),
            ),
            if (_selectedWeekdays.isEmpty) _buildErrorText('At least one day must be selected'),
          ],
        );
    }
  }

  Widget _buildStackSelector() {
    final stacksAsync = ref.watch(stackListProvider);
    return stacksAsync.when(
      data: (stacks) {
        if (stacks.isEmpty) return const Text('No stacks available. Create one in the Chain Builder.', style: TextStyle(color: AppTheme.textMuted));
        
        return DropdownButtonFormField<String>(
          value: stacks.any((s) => s.id.toString() == _selectedStackId) ? _selectedStackId : null,
          items: [
            const DropdownMenuItem(value: null, child: Text('None (Standalone)')),
            ...stacks.map((s) => DropdownMenuItem(value: s.id.toString(), child: Text(s.name))),
          ],
          onChanged: (val) {
            setState(() {
              _selectedStackId = val;
            });
          },
          decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Select Stack'),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
