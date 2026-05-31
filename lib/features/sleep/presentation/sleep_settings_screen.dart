import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/sleep_model.dart';

class SleepSettingsScreen extends StatefulWidget {
  const SleepSettingsScreen({super.key});
  @override
  State<SleepSettingsScreen> createState() => _SleepSettingsScreenState();
}

class _SleepSettingsScreenState extends State<SleepSettingsScreen> {
  static const _ch = MethodChannel('rutin/sleep');

  late SleepSettings _settings;
  bool _accessibilityGranted = false;

  @override
  void initState() {
    super.initState();
    _settings = _loadOrCreate();
    _checkAccessibility();
  }

  SleepSettings _loadOrCreate() {
    final box = Hive.box<SleepSettings>('sleep_settings');
    if (box.isEmpty) {
      final s = SleepSettings()
        ..sleepModeStartMinutes = 1260
        ..wakeWindowStartMinutes = 300
        ..wakeWindowEndMinutes = 600
        ..sleepModeEnabled = false
        ..accessibilityGranted = false;
      box.add(s);
      return s;
    }
    return box.getAt(0)!;
  }

  Future<void> _checkAccessibility() async {
    try {
      final granted =
          await _ch.invokeMethod<bool>('isAccessibilityGranted') ?? false;
      if (mounted) {
        setState(() {
          _accessibilityGranted = granted;
          _settings.accessibilityGranted = granted;
          _settings.save();
        });
      }
    } catch (_) {}
  }

  void _saveNative() {
    _settings.save();
    _ch.invokeMethod('saveSleepSettings', {
      'sleepStartMin': _settings.sleepModeStartMinutes,
      'wakeWindowStart': _settings.wakeWindowStartMinutes,
      'wakeWindowEnd': _settings.wakeWindowEndMinutes,
      'enabled': _settings.sleepModeEnabled,
    });
  }

  Future<void> _pickTime(int current, void Function(int) onPicked) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked != null && mounted) onPicked(picked.hour * 60 + picked.minute);
  }

  String _fmt(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  Future<void> _onToggle(bool val) async {
    setState(() {
      _settings.sleepModeEnabled = val;
      _saveNative();
    });
    try {
      await _ch.invokeMethod(val ? 'startService' : 'stopService');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode Tidur'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Card(children: [
            SwitchListTile(
              value: _settings.sleepModeEnabled,
              onChanged: _onToggle,
              title: const Text(
                'Mode Tidur',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Aktifkan gerbang bangun pagi'),
            ),
            if (_settings.sleepModeEnabled && !_accessibilityGranted)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: cs.error.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: cs.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Untuk pengalaman terbaik, aktifkan Accessibility Service.',
                          style: TextStyle(
                              fontSize: 13, color: cs.onErrorContainer),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            _ch.invokeMethod('openAccessibilitySettings'),
                        child: const Text('Aktifkan'),
                      ),
                    ],
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          _Card(children: [
            _TimeTile(
              icon: Icons.bedtime_rounded,
              label: 'Jam tidur',
              value: _fmt(_settings.sleepModeStartMinutes),
              onTap: () => _pickTime(_settings.sleepModeStartMinutes, (v) {
                setState(() {
                  _settings.sleepModeStartMinutes = v;
                  _saveNative();
                });
              }),
            ),
            const Divider(height: 1),
            _TimeTile(
              icon: Icons.wb_sunny_rounded,
              label: 'Mulai jendela bangun',
              value: _fmt(_settings.wakeWindowStartMinutes),
              onTap: () =>
                  _pickTime(_settings.wakeWindowStartMinutes, (v) {
                setState(() {
                  _settings.wakeWindowStartMinutes = v;
                  _saveNative();
                });
              }),
            ),
            const Divider(height: 1),
            _TimeTile(
              icon: Icons.light_mode_rounded,
              label: 'Akhir jendela bangun',
              value: _fmt(_settings.wakeWindowEndMinutes),
              onTap: () =>
                  _pickTime(_settings.wakeWindowEndMinutes, (v) {
                setState(() {
                  _settings.wakeWindowEndMinutes = v;
                  _saveNative();
                });
              }),
            ),
          ]),
          const SizedBox(height: 12),
          _Card(children: [
            ListTile(
              leading: Icon(
                _accessibilityGranted
                    ? Icons.check_circle_rounded
                    : Icons.warning_amber_rounded,
                color:
                    _accessibilityGranted ? Colors.green : cs.error,
              ),
              title: const Text('Accessibility Service'),
              subtitle: Text(
                  _accessibilityGranted ? 'Diizinkan ✓' : 'Belum diizinkan'),
              trailing: _accessibilityGranted
                  ? null
                  : TextButton(
                      onPressed: () =>
                          _ch.invokeMethod('openAccessibilitySettings'),
                      child: const Text('Izinkan'),
                    ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.battery_saver_rounded),
              title: const Text('Optimasi Baterai'),
              subtitle: const Text('Izinkan berjalan di latar belakang'),
              trailing: TextButton(
                onPressed: () =>
                    _ch.invokeMethod('openBatteryOptimization'),
                child: const Text('Atur'),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/wakeup-game', extra: 0),
                  icon: const Icon(Icons.grid_view_rounded, size: 18),
                  label: const Text('Test Sequence'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/wakeup-game', extra: 2),
                  icon: const Icon(Icons.music_note_rounded, size: 18),
                  label: const Text('Test Rhythm'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.15),
              foregroundColor: const Color(0xFF7C3AED),
              side: const BorderSide(color: Color(0xFF7C3AED), width: 1),
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: () async {
              await _ch.invokeMethod('simulateSleepTrigger');
              if (!mounted) return;
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Game seharusnya muncul sekarang. Jika tidak, cek apakah Mode Tidur aktif.',
                  ),
                  duration: Duration(seconds: 4),
                ),
              );
            },
            icon: const Icon(Icons.bedtime_rounded, size: 18),
            label: const Text('Test Sleep Gate'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) =>
      Card(child: Column(mainAxisSize: MainAxisSize.min, children: children));
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: cs.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}
