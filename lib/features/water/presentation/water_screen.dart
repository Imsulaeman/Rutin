import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/analytics_service.dart';
import '../../../core/services/haptics_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../data/water_model.dart';
import '../data/water_repository.dart';
import 'water_reminder_service.dart';
import 'water_progress_widget.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> with WidgetsBindingObserver {
  final _repo = WaterRepository();
  late WaterGoal _goal;
  int _currentMl = 0;
  int? _undoAmountMl;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _checkPendingLogs();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPendingLogs();
  }

  void _load() {
    _goal = _repo.getGoal();
    setState(() => _currentMl = _repo.getTodayMl());
  }

  // Each pending native reminder the user confirmed = one glass.
  void _checkPendingLogs() async {
    final pending = await WaterReminderService.getPendingLogs();
    if (pending <= 0 || !mounted) return;
    await _repo.addMl(pending * _goal.glassSizeMl);
    if (mounted) setState(() => _currentMl = _repo.getTodayMl());
  }

  Future<void> _addMl(int amount) async {
    HapticsService.tap();
    await _repo.addMl(amount);
    AnalyticsService.waterAdded(amount);
    if (!mounted) return;
    setState(() {
      _currentMl = _repo.getTodayMl();
      _undoAmountMl = amount;
    });
  }

  Future<void> _undoLastAdd() async {
    final amount = _undoAmountMl;
    if (amount == null) return;
    HapticsService.success();
    await _repo.removeMl(amount);
    if (!mounted) return;
    setState(() {
      _currentMl = _repo.getTodayMl();
      _undoAmountMl = null;
    });
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _WaterSettingsSheet(
        goal: _goal,
        onSave: (updated) async {
          _goal = updated;
          await _repo.saveGoal(_goal);
          if (_goal.reminderActive) {
            await WaterReminderService.schedule(_goal);
          } else {
            await WaterReminderService.cancel();
          }
          setState(() {});
        },
      ),
    );
  }

  String? _nextReminderLabel() {
    if (!_goal.reminderActive) return null;
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;

    if (nowMin < _goal.startTimeMinutes) {
      return '${context.l10n.remindersStart} ${_pad(_goal.startTimeMinutes ~/ 60)}:${_pad(_goal.startTimeMinutes % 60)}';
    }
    if (nowMin >= _goal.endTimeMinutes) {
      return context.l10n.remindersFinished;
    }

    final elapsed = nowMin - _goal.startTimeMinutes;
    final interval = _goal.reminderIntervalMinutes;
    final nextMin =
        _goal.startTimeMinutes + ((elapsed / interval).ceil() * interval);

    if (nextMin >= _goal.endTimeMinutes) {
      return context.l10n.remindersFinished;
    }

    final diff = nextMin - nowMin;
    if (diff <= 0) {
      return context.l10n.comingSoon;
    }
    if (diff < 60) {
      return context.l10n.reminderInMinutes(diff);
    }
    final hours = diff ~/ 60;
    final minutes = diff % 60;
    return minutes == 0
        ? context.l10n.reminderInHours(hours)
        : context.l10n.reminderInHoursMinutes(hours, minutes);
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final targetMl = _goal.dailyTargetMl;
    final pct = targetMl > 0 ? (_currentMl / targetMl).clamp(0.0, 1.0) : 0.0;
    final pctInt = (pct * 100).round();
    final isDone = _currentMl >= targetMl;
    final nextReminderLabel = _nextReminderLabel();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.go('/'),
                  ),
                  const Spacer(),
                  Text(
                    context.l10n.water,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.tune_rounded),
                    tooltip: context.l10n.waterSettings,
                    onPressed: _openSettings,
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mascot + speech bubble
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/water_drop_mascot.webp',
                          height: 76,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceHigh,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              isDone
                                  ? context.l10n.waterGoalReached
                                  : context.l10n.waterMascotNudge,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Hero ring
                    Center(
                      child: WaterProgressWidget(
                        current: _currentMl,
                        goal: targetMl,
                        size: 240,
                        strokeWidth: 16,
                        trackColor: AppTheme.waterColor.withValues(alpha: 0.15),
                        fillColor: AppTheme.waterColor,
                        center: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TweenAnimationBuilder<int>(
                                  tween: IntTween(begin: 0, end: _currentMl),
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOutCubic,
                                  builder: (_, v, _) => Text(
                                    _fmtMl(v),
                                    style: const TextStyle(
                                      fontSize: 46,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1.5,
                                      color: Colors.white,
                                      height: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    'ml',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.waterColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.l10n.waterOfMl(_fmtMl(targetMl)),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$pctInt%',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.waterColor,
                                height: 1,
                              ),
                            ),
                            if (nextReminderLabel != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                nextReminderLabel,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.waterColor.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Primary add button (one glass)
                    FilledButton(
                      onPressed: () => _addMl(_goal.glassSizeMl),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.waterColor,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text('+ ${_goal.glassSizeMl} ml'),
                    ),

                    if (_undoAmountMl != null) ...[
                      const SizedBox(height: 12),
                      _UndoBar(amountMl: _undoAmountMl!, onUndo: _undoLastAdd),
                    ],

                    const SizedBox(height: 12),

                    // Quick-add chips
                    Row(
                      children: [
                        _QuickAddChip(
                          amount: 100,
                          icon: Icons.local_cafe_rounded,
                          onTap: () => _addMl(100),
                        ),
                        const SizedBox(width: 12),
                        _QuickAddChip(
                          amount: 250,
                          icon: Icons.local_drink_rounded,
                          onTap: () => _addMl(250),
                        ),
                        const SizedBox(width: 12),
                        _QuickAddChip(
                          amount: 500,
                          icon: Icons.water_drop_rounded,
                          onTap: () => _addMl(500),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Daily goal row
                    InkWell(
                      onTap: _openSettings,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceHigh,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Text(
                              context.l10n.dailyGoal,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Spacer(),
                            Text(
                              '${_fmtMl(targetMl)} ml',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.edit_rounded,
                              size: 18,
                              color: AppTheme.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtMl(int ml) {
    if (ml >= 1000) {
      return ml.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
    }
    return ml.toString();
  }
}

// Quick-add chip

class _QuickAddChip extends StatefulWidget {
  const _QuickAddChip({
    required this.amount,
    required this.icon,
    required this.onTap,
  });
  final int amount;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_QuickAddChip> createState() => _QuickAddChipState();
}

class _QuickAddChipState extends State<_QuickAddChip> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: () {
          HapticsService.softTap();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _down ? 0.95 : 1,
          duration: const Duration(milliseconds: 110),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(widget.icon, color: AppTheme.waterColor, size: 22),
                const SizedBox(height: 6),
                Text(
                  '+${widget.amount} ml',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Settings bottom sheet

class _UndoBar extends StatelessWidget {
  const _UndoBar({required this.amountMl, required this.onUndo});

  final int amountMl;
  final Future<void> Function() onUndo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.waterColor.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppTheme.waterColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.waterAmountAdded(amountMl),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          TextButton(onPressed: onUndo, child: Text(context.l10n.undo)),
        ],
      ),
    );
  }
}

class _WaterSettingsSheet extends StatefulWidget {
  const _WaterSettingsSheet({required this.goal, required this.onSave});
  final WaterGoal goal;
  final Future<void> Function(WaterGoal) onSave;

  @override
  State<_WaterSettingsSheet> createState() => _WaterSettingsSheetState();
}

class _WaterSettingsSheetState extends State<_WaterSettingsSheet> {
  late double _targetL;
  late int _glassSizeMl;
  late int _startHour;
  late int _endHour;
  late bool _reminderActive;

  static const _glassSizes = [150, 200, 250, 300, 350, 500];

  @override
  void initState() {
    super.initState();
    _targetL = widget.goal.dailyTargetMl / 1000;
    _glassSizeMl = widget.goal.glassSizeMl;
    _startHour = widget.goal.startTimeMinutes ~/ 60;
    _endHour = widget.goal.endTimeMinutes ~/ 60;
    _reminderActive = widget.goal.reminderActive;
  }

  int get _glasses => (_targetL * 1000 / _glassSizeMl).ceil();
  int get _windowHours => _endHour - _startHour;
  int get _intervalMin {
    if (_glasses <= 0 || _windowHours <= 0) return 120;
    return ((_windowHours * 60) / _glasses).floor().clamp(15, 240);
  }

  Future<void> _save() async {
    widget.goal
      ..dailyTargetMl = (_targetL * 1000).round()
      ..glassSizeMl = _glassSizeMl
      ..startTimeMinutes = _startHour * 60
      ..endTimeMinutes = _endHour * 60
      ..reminderActive = _reminderActive;
    await widget.onSave(widget.goal);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.waterSettings,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.waterWhoGuidance,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(context.l10n.dailyGoal),
              const Spacer(),
              Text(
                '${_targetL.toStringAsFixed(1)} L',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Slider(
            value: _targetL,
            min: 1.0,
            max: 5.0,
            divisions: 16,
            label: '${_targetL.toStringAsFixed(1)}L',
            activeColor: AppTheme.waterColor,
            onChanged: (v) => setState(() => _targetL = v),
          ),
          Row(
            children: [
              Text(context.l10n.glassSize),
              const Spacer(),
              DropdownButton<int>(
                value: _glassSizeMl,
                items: _glassSizes
                    .map(
                      (s) => DropdownMenuItem(value: s, child: Text('${s}ml')),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _glassSizeMl = v!),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(context.l10n.start),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: _startHour,
                items: List.generate(24, (i) => i)
                    .map(
                      (h) => DropdownMenuItem(
                        value: h,
                        child: Text('${h.toString().padLeft(2, '0')}:00'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _startHour = v!),
              ),
              const Spacer(),
              Text(context.l10n.done),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: _endHour,
                items: List.generate(24, (i) => i)
                    .where((h) => h > _startHour)
                    .map(
                      (h) => DropdownMenuItem(
                        value: h,
                        child: Text('${h.toString().padLeft(2, '0')}:00'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _endHour = v!),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Reminder toggle (moved here to keep the main screen clean)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.reminder,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.waterReminderRange(_intervalMin),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Switch(
                value: _reminderActive,
                onChanged: (v) => setState(() => _reminderActive = v),
                activeThumbColor: AppTheme.waterColor,
                activeTrackColor: AppTheme.waterColor.withAlpha(100),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.waterGlassesSummary(_glasses, _intervalMin),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(backgroundColor: AppTheme.waterColor),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
  }
}
