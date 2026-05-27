import 'package:flutter/material.dart';

import '../data/water_model.dart';
import '../data/water_repository.dart';
import '../../notifications/alarm_service.dart';
import 'water_progress_widget.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  final _repo = WaterRepository();
  late WaterGoal _goal;
  int _current = 0;
  bool _reminderActive = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _goal = _repo.getGoal();
    final log = _repo.getTodayLog();
    setState(() {
      _current = log?.glassesLogged ?? 0;
      _reminderActive = _goal.reminderActive;
    });
  }

  Future<void> _addGlass() async {
    await _repo.logGlass();
    final log = _repo.getTodayLog();
    setState(() => _current = log?.glassesLogged ?? _current + 1);
  }

  Future<void> _removeGlass() async {
    if (_current == 0) return;
    await _repo.removeGlass();
    setState(() => _current = _current - 1);
  }

  Future<void> _toggleReminder(bool value) async {
    _goal.reminderActive = value;
    await _repo.saveGoal(_goal);
    if (value) {
      await AlarmService.scheduleWater(
        intervalMinutes: _goal.reminderIntervalMinutes,
        startTimeMinutes: _goal.startTimeMinutes,
        endTimeMinutes: _goal.endTimeMinutes,
      );
    } else {
      await AlarmService.cancelWater();
    }
    setState(() => _reminderActive = value);
  }

  String _minutesToTime(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final period = h < 12 ? 'AM' : 'PM';
    final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour:${m.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDone = _current >= _goal.dailyGoalGlasses;

    return Scaffold(
      appBar: AppBar(title: const Text('Air')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WaterProgressWidget(current: _current, goal: _goal.dailyGoalGlasses),
            const SizedBox(height: 8),
            if (isDone)
              const Text(
                'Target hari ini tercapai!',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _removeGlass,
                  icon: const Icon(Icons.remove_circle_outline),
                  iconSize: 36,
                  tooltip: 'Kurangi',
                ),
                const SizedBox(width: 24),
                Column(
                  children: [
                    Text(
                      '$_current',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const Text('gelas hari ini'),
                  ],
                ),
                const SizedBox(width: 24),
                IconButton(
                  onPressed: _addGlass,
                  icon: const Icon(Icons.add_circle_outline),
                  iconSize: 36,
                  tooltip: 'Tambah segelas',
                ),
              ],
            ),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pengingat minum air', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('Setiap 2 jam, 07:00 – 22:00', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Switch(
                  value: _reminderActive,
                  onChanged: _toggleReminder,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Aktif: ${_minutesToTime(_goal.startTimeMinutes)} – ${_minutesToTime(_goal.endTimeMinutes)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
