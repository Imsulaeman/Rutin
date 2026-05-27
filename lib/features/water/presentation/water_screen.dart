import 'package:flutter/material.dart';

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
  int _current = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _checkPendingLogs();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPendingLogs();
  }

  void _load() {
    _goal = _repo.getGoal();
    setState(() => _current = _repo.getTodayLog()?.glassesLogged ?? 0);
  }

  void _checkPendingLogs() async {
    final pending = await WaterReminderService.getPendingLogs();
    if (pending <= 0 || !mounted) return;
    for (var i = 0; i < pending; i++) {
      await _repo.logGlass();
    }
    if (mounted) setState(() => _current = _repo.getTodayLog()?.glassesLogged ?? 0);
  }

  Future<void> _addGlass() async {
    await _repo.logGlass();
    setState(() => _current++);
  }

  Future<void> _removeGlass() async {
    if (_current == 0) return;
    await _repo.removeGlass();
    setState(() => _current--);
  }

  Future<void> _toggleReminder(bool value) async {
    _goal.reminderActive = value;
    await _repo.saveGoal(_goal);
    if (value) {
      await WaterReminderService.schedule(_goal);
    } else {
      await WaterReminderService.cancel();
    }
    setState(() {});
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
          }
          setState(() {});
        },
      ),
    );
  }

  String _fmtTime(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final goal = _goal.goalGlasses;
    final isDone = _current >= goal;
    final totalMl = _current * _goal.glassSizeMl;
    final targetL = (_goal.dailyTargetMl / 1000).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Air'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Pengaturan air',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WaterProgressWidget(current: _current, goal: goal),
            const SizedBox(height: 6),
            Text(
              '${(totalMl / 1000).toStringAsFixed(2)}L dari ${targetL}L target',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (isDone) ...[
              const SizedBox(height: 4),
              Text(
                'Target hari ini tercapai!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _removeGlass,
                  icon: const Icon(Icons.remove_circle_outline),
                  iconSize: 40,
                ),
                const SizedBox(width: 32),
                Column(
                  children: [
                    Text(
                      '$_current',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    Text('dari $goal gelas'),
                  ],
                ),
                const SizedBox(width: 32),
                IconButton(
                  onPressed: _addGlass,
                  icon: const Icon(Icons.add_circle_outline),
                  iconSize: 40,
                ),
              ],
            ),
            const SizedBox(height: 48),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pengingat', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        'Setiap ${_goal.reminderIntervalMinutes} menit  ·  ${_fmtTime(_goal.startTimeMinutes)} – ${_fmtTime(_goal.endTimeMinutes)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _goal.reminderActive,
                  onChanged: _toggleReminder,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Settings bottom sheet ────────────────────────────────────────────────────

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

  static const _glassSizes = [150, 200, 250, 300, 350, 500];

  @override
  void initState() {
    super.initState();
    _targetL = widget.goal.dailyTargetMl / 1000;
    _glassSizeMl = widget.goal.glassSizeMl;
    _startHour = widget.goal.startTimeMinutes ~/ 60;
    _endHour = widget.goal.endTimeMinutes ~/ 60;
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
      ..endTimeMinutes = _endHour * 60;
    await widget.onSave(widget.goal);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Pengaturan Air', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          // Science note
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'WHO merekomendasikan 2.0L (wanita) – 2.5L (pria) per hari dari minuman. '
              'Di iklim panas seperti Indonesia, tambahkan 0.5–1.0L.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),

          // Target
          Row(
            children: [
              const Text('Target harian'),
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
            onChanged: (v) => setState(() => _targetL = v),
          ),

          // Glass size
          Row(
            children: [
              const Text('Ukuran gelas'),
              const Spacer(),
              DropdownButton<int>(
                value: _glassSizeMl,
                items: _glassSizes
                    .map((s) => DropdownMenuItem(value: s, child: Text('${s}ml')))
                    .toList(),
                onChanged: (v) => setState(() => _glassSizeMl = v!),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Start / end hour
          Row(
            children: [
              const Text('Mulai'),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: _startHour,
                items: List.generate(24, (i) => i)
                    .map((h) => DropdownMenuItem(value: h, child: Text('${h.toString().padLeft(2, '0')}:00')))
                    .toList(),
                onChanged: (v) => setState(() => _startHour = v!),
              ),
              const Spacer(),
              const Text('Selesai'),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: _endHour,
                items: List.generate(24, (i) => i)
                    .where((h) => h > _startHour)
                    .map((h) => DropdownMenuItem(value: h, child: Text('${h.toString().padLeft(2, '0')}:00')))
                    .toList(),
                onChanged: (v) => setState(() => _endHour = v!),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Summary
          Text(
            '$_glasses gelas/hari  ·  pengingat setiap $_intervalMin menit',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),

          FilledButton(onPressed: _save, child: const Text('Simpan')),
        ],
      ),
    );
  }
}
