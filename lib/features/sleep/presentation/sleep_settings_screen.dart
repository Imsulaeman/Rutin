import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../l10n/l10n.dart';
import '../data/sleep_model.dart';

class SleepSettingsScreen extends StatefulWidget {
  const SleepSettingsScreen({super.key});
  @override
  State<SleepSettingsScreen> createState() => _SleepSettingsScreenState();
}

class _SleepSettingsScreenState extends State<SleepSettingsScreen>
    with WidgetsBindingObserver {
  static const _ch = MethodChannel('rutin/sleep');

  late SleepSettings _settings;
  bool _accessibilityGranted = false;
  bool _batteryOptimizationIgnored = false;
  Timer? _statusRetryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _settings = _loadOrCreate();
    _scheduleStatusRefresh();
  }

  @override
  void dispose() {
    _statusRetryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _scheduleStatusRefresh();
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

  Future<void> _refreshStatuses() async {
    try {
      final accessibilityGranted =
          await _ch.invokeMethod<bool>('isAccessibilityGranted') ?? false;
      final batteryOptimizationIgnored =
          await _ch.invokeMethod<bool>('isBatteryOptimizationIgnored') ?? false;
      if (mounted) {
        setState(() {
          _accessibilityGranted = accessibilityGranted;
          _batteryOptimizationIgnored = batteryOptimizationIgnored;
          _settings.accessibilityGranted = accessibilityGranted;
          _settings.save();
        });
      }
    } catch (_) {}
  }

  void _scheduleStatusRefresh() {
    _statusRetryTimer?.cancel();
    _refreshStatuses();
    _statusRetryTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) _refreshStatuses();
    });
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _settings.sleepModeEnabled = false;
        _saveNative();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.sleepModeStartError)),
      );
    }
  }

  Future<void> _openBatteryOptimization() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.allowBackgroundTitle),
        content: Text(context.l10n.allowBackgroundBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.later),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.configure),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      await _ch.invokeMethod('openBatteryOptimization');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.sleepMode),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Card(
            children: [
              SwitchListTile(
                value: _settings.sleepModeEnabled,
                onChanged: _onToggle,
                title: Text(
                  context.l10n.sleepMode,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(context.l10n.enableMorningGate),
              ),
              if (_settings.sleepModeEnabled && !_accessibilityGranted)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.errorContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cs.error.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: cs.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.l10n.enableAccessibilityHint,
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onErrorContainer,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              _ch.invokeMethod('openAccessibilitySettings'),
                          child: Text(context.l10n.enable),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _Card(
            children: [
              _TimeTile(
                icon: Icons.bedtime_rounded,
                label: context.l10n.sleepTime,
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
                label: context.l10n.wakeWindowStart,
                value: _fmt(_settings.wakeWindowStartMinutes),
                onTap: () => _pickTime(_settings.wakeWindowStartMinutes, (v) {
                  setState(() {
                    _settings.wakeWindowStartMinutes = v;
                    _saveNative();
                  });
                }),
              ),
              const Divider(height: 1),
              _TimeTile(
                icon: Icons.light_mode_rounded,
                label: context.l10n.wakeWindowEnd,
                value: _fmt(_settings.wakeWindowEndMinutes),
                onTap: () => _pickTime(_settings.wakeWindowEndMinutes, (v) {
                  setState(() {
                    _settings.wakeWindowEndMinutes = v;
                    _saveNative();
                  });
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Card(
            children: [
              ListTile(
                leading: Icon(
                  _accessibilityGranted
                      ? Icons.check_circle_rounded
                      : Icons.warning_amber_rounded,
                  color: _accessibilityGranted ? Colors.green : cs.error,
                ),
                title: Text(context.l10n.accessibilityService),
                subtitle: Text(
                  _accessibilityGranted
                      ? context.l10n.allowed
                      : context.l10n.notAllowedYet,
                ),
                trailing: _accessibilityGranted
                    ? null
                    : TextButton(
                        onPressed: () =>
                            _ch.invokeMethod('openAccessibilitySettings'),
                        child: Text(context.l10n.allow),
                      ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  _batteryOptimizationIgnored
                      ? Icons.check_circle_rounded
                      : Icons.warning_amber_rounded,
                  color: _batteryOptimizationIgnored ? Colors.green : cs.error,
                ),
                title: Text(context.l10n.batteryOptimization),
                subtitle: Text(
                  _batteryOptimizationIgnored
                      ? context.l10n.backgroundAllowed
                      : context.l10n.backgroundNotConfirmed,
                ),
                trailing: TextButton(
                  onPressed: _openBatteryOptimization,
                  child: Text(context.l10n.configure),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _GameTestButton(
                icon: Icons.grid_view_rounded,
                label: context.l10n.testSequence,
                onTap: () => context.push('/wakeup-game', extra: 0),
              ),
              _GameTestButton(
                icon: Icons.music_note_rounded,
                label: context.l10n.testRhythm,
                onTap: () => context.push('/wakeup-game', extra: 2),
              ),
              _GameTestButton(
                icon: Icons.gesture_rounded,
                label: context.l10n.testDots,
                onTap: () => context.push('/wakeup-game', extra: 5),
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
              final messenger = ScaffoldMessenger.of(context);
              final message = context.l10n.sleepTriggerSimulated;
              await _ch.invokeMethod('simulateSleepTrigger');
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(message),
                  duration: Duration(seconds: 4),
                ),
              );
            },
            icon: const Icon(Icons.bedtime_rounded, size: 18),
            label: Text(context.l10n.testSleepGate),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _GameTestButton extends StatelessWidget {
  const _GameTestButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: (MediaQuery.sizeOf(context).width - 42) / 2,
    child: OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
    child: Column(mainAxisSize: MainAxisSize.min, children: children),
  );
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
