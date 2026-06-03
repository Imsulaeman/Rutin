import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../sleep/data/sleep_model.dart';
import '../../../core/services/tutorial_trigger.dart';
import '../data/backup_service.dart';
import '../data/language_service.dart';

const _navy = Color(0xFF0B0E1A);
const _green = Color(0xFF4CC56A);
const _amber = Color(0xFFF4A92B);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  static const _ch = MethodChannel('rutin/sleep');
  static const _nativeCh = MethodChannel('habit_app/native_reminder');

  SleepSettings? _sleep;
  bool _accessibilityGranted = false;
  bool _fullScreenIntentAllowed = true;
  String _lang = LanguageService.current;
  String _notificationSound = 'chime';
  String _alarmSound = 'ringtone';
  String _notificationSoundTitle = '';
  String _alarmSoundTitle = '';
  bool _backupBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _checkAccessibility();
    _checkFullScreenIntent();
    _loadSoundSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load();
      _checkAccessibility();
      _checkFullScreenIntent();
      _loadSoundSettings();
    }
  }

  void _load() {
    final sleepBox = Hive.box<SleepSettings>('sleep_settings');
    if (!mounted) return;
    setState(() {
      _sleep = sleepBox.isEmpty ? null : sleepBox.getAt(0);
      _lang = LanguageService.current;
    });
  }

  Future<void> _checkAccessibility() async {
    try {
      final granted =
          await _ch.invokeMethod<bool>('isAccessibilityGranted') ?? false;
      if (mounted) setState(() => _accessibilityGranted = granted);
    } catch (_) {}
  }

  Future<void> _setLanguage(String lang) async {
    await LanguageService.setLanguage(lang);
    if (mounted) setState(() => _lang = lang);
  }

  Future<void> _checkFullScreenIntent() async {
    try {
      final allowed =
          await _nativeCh.invokeMethod<bool>('canUseFullScreenIntent') ?? true;
      if (mounted) setState(() => _fullScreenIntentAllowed = allowed);
    } catch (_) {}
  }

  Future<void> _openAccessibilitySettings() async {
    await _ch.invokeMethod('openAccessibilitySettings');
  }

  Future<void> _exportBackup() async {
    if (_backupBusy) return;
    setState(() => _backupBusy = true);
    try {
      await BackupService.exportJson();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.exportBackupFailed(e.toString())),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _openFullScreenIntentSettings() async {
    await _nativeCh.invokeMethod('openFullScreenIntentSettings');
  }

  Future<void> _loadSoundSettings() async {
    try {
      final raw = await _nativeCh.invokeMethod<Map<Object?, Object?>>(
        'getReminderSoundSettings',
      );
      if (raw == null || !mounted) return;
      final notif = (raw['notificationSound'] as String?) ?? _notificationSound;
      final alarm = (raw['alarmSound'] as String?) ?? _alarmSound;
      setState(() {
        _notificationSound = notif;
        _alarmSound = alarm;
      });
      await _refreshSoundTitles(notif, alarm);
    } catch (_) {}
  }

  Future<void> _refreshSoundTitles(String notif, String alarm) async {
    final notifTitle = await _getSoundTitle(notif);
    final alarmTitle = await _getSoundTitle(alarm);
    if (!mounted) return;
    setState(() {
      _notificationSoundTitle = notifTitle;
      _alarmSoundTitle = alarmTitle;
    });
  }

  Future<String> _getSoundTitle(String value) async {
    if (value == 'chime' || value == 'ringtone' || value == 'system') return '';
    try {
      return await _nativeCh.invokeMethod<String>('getSoundTitle', {'uri': value}) ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _setSoundSettings({
    String? notificationSound,
    String? alarmSound,
  }) async {
    await _nativeCh.invokeMethod('setReminderSoundSettings', {
      if (notificationSound != null) 'notificationSound': notificationSound,
      if (alarmSound != null) 'alarmSound': alarmSound,
    });
    if (!mounted) return;
    setState(() {
      if (notificationSound != null) _notificationSound = notificationSound;
      if (alarmSound != null) _alarmSound = alarmSound;
    });
    await _refreshSoundTitles(
      notificationSound ?? _notificationSound,
      alarmSound ?? _alarmSound,
    );
  }

  Future<void> _previewSound(String value, String soundType) async {
    try {
      await _nativeCh.invokeMethod('previewReminderSound', {
        'type': soundType,
        'value': value,
      });
    } catch (_) {}
  }

  Future<void> _pickSound({
    required String title,
    required String currentValue,
    required String soundType,
    required Future<void> Function(String value) onSelected,
  }) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            _SoundOption(
              value: 'chime',
              groupValue: currentValue,
              title: context.l10n.appSound,
              subtitle: context.l10n.appSoundSubtitle,
              onChanged: (value) => Navigator.pop(ctx, value),
              onPreview: () => _previewSound('chime', soundType),
            ),
            _SoundOption(
              value: 'ringtone',
              groupValue: currentValue,
              title: context.l10n.appRingtone,
              subtitle: context.l10n.appRingtoneSubtitle,
              onChanged: (value) => Navigator.pop(ctx, value),
              onPreview: () => _previewSound('ringtone', soundType),
            ),
            ListTile(
              leading: const Icon(Icons.library_music_rounded),
              title: Text(context.l10n.browsePhoneSounds),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.pop(ctx, '__browse__'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == '__browse__') {
      final uri = await _browsePhoneSounds(soundType);
      if (uri != null) await onSelected(uri);
    } else if (picked != null) {
      await onSelected(picked);
    }
  }

  Future<String?> _browsePhoneSounds(String soundType) async {
    try {
      return await _nativeCh.invokeMethod<String>('pickSystemSound', {'type': soundType});
    } catch (_) {
      return null;
    }
  }

  String _soundLabel(String value, {bool isAlarm = false}) {
    return switch (value) {
      'system'   => context.l10n.phoneDefaultSound,
      'ringtone' => context.l10n.appRingtone,
      'chime'    => context.l10n.appSound,
      _ => isAlarm
          ? (_alarmSoundTitle.isNotEmpty ? _alarmSoundTitle : context.l10n.browsePhoneSounds)
          : (_notificationSoundTitle.isNotEmpty ? _notificationSoundTitle : context.l10n.browsePhoneSounds),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(context.l10n.settings),
            backgroundColor: _navy,
            foregroundColor: Colors.white,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            sliver: SliverList.list(
              children: [
                _SectionLabel(context.l10n.sleepMode.toUpperCase()),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.bedtime_rounded,
                          color: AppTheme.habitsColor,
                        ),
                        title: Text(context.l10n.sleepMode),
                        subtitle: Text(
                          _sleep?.sleepModeEnabled == true
                              ? context.l10n.active
                              : context.l10n.inactive,
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () async {
                          await context.push('/sleep-settings');
                          _load();
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          _accessibilityGranted
                              ? Icons.accessibility_new_rounded
                              : Icons.warning_amber_rounded,
                          color: _accessibilityGranted ? _green : _amber,
                        ),
                        title: Text(context.l10n.accessibility),
                        subtitle: Text(
                          _accessibilityGranted
                              ? context.l10n.allowed
                              : context.l10n.accessibilityNotAllowed,
                        ),
                        trailing: _accessibilityGranted
                            ? null
                            : TextButton(
                                onPressed: _openAccessibilitySettings,
                                child: Text(context.l10n.allow),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _SectionLabel(context.l10n.medicineAlarmSection),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: Icon(
                      _fullScreenIntentAllowed
                          ? Icons.fullscreen_rounded
                          : Icons.warning_amber_rounded,
                      color: _fullScreenIntentAllowed ? _green : _amber,
                    ),
                    title: Text(context.l10n.fullScreenAlarm),
                    subtitle: Text(
                      _fullScreenIntentAllowed
                          ? context.l10n.fullScreenAlarmAllowed
                          : context.l10n.fullScreenAlarmNotAllowed,
                    ),
                    trailing: _fullScreenIntentAllowed
                        ? null
                        : TextButton(
                            onPressed: _openFullScreenIntentSettings,
                            child: Text(context.l10n.allow),
                          ),
                  ),
                ),
                const SizedBox(height: 22),
                _SectionLabel(context.l10n.language),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'id', label: Text('🇮🇩 ID')),
                        ButtonSegment(value: 'en', label: Text('🇬🇧 EN')),
                      ],
                      selected: {_lang},
                      onSelectionChanged: (selection) =>
                          _setLanguage(selection.first),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                _SectionLabel(context.l10n.soundSection),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.notifications_active_rounded,
                        ),
                        title: Text(context.l10n.notificationSound),
                        subtitle: Text(context.l10n.notificationSoundSubtitle),
                        trailing: Text(
                          _soundLabel(_notificationSound, isAlarm: false),
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () => _pickSound(
                          title: context.l10n.notificationSound,
                          currentValue: _notificationSound,
                          soundType: 'notification',
                          onSelected: (value) =>
                              _setSoundSettings(notificationSound: value),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.music_note_rounded),
                        title: Text(context.l10n.medicineAlarmSound),
                        subtitle: Text(context.l10n.medicineAlarmSoundSubtitle),
                        trailing: Text(
                          _soundLabel(_alarmSound, isAlarm: true),
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () => _pickSound(
                          title: context.l10n.medicineAlarmSound,
                          currentValue: _alarmSound,
                          soundType: 'alarm',
                          onSelected: (value) =>
                              _setSoundSettings(alarmSound: value),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _SectionLabel(context.l10n.otherSection),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.play_circle_outline_rounded),
                    title: Text(context.l10n.tutorial),
                    subtitle: Text(context.l10n.tutorialSubtitle),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      TutorialTrigger.fire();
                      context.go('/');
                    },
                  ),
                ),
                const SizedBox(height: 22),
                _SectionLabel(context.l10n.dataSection),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.download_rounded),
                    title: Text(context.l10n.exportBackup),
                    subtitle: Text(context.l10n.exportBackupSubtitle),
                    trailing: _backupBusy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: _exportBackup,
                  ),
                ),
                const SizedBox(height: 22),
                _SectionLabel(context.l10n.about),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.info_outline_rounded),
                        title: Text(context.l10n.version),
                        trailing: const Text('1.0.0 (build 1)'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.person_outline_rounded),
                        title: Text(context.l10n.builtBy),
                        trailing: const Text('Ilham Maulana Sulaeman'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.favorite_outline_rounded),
                        title: const Text('Rutin'),
                        subtitle: Text(context.l10n.freeForever),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SoundOption extends StatelessWidget {
  const _SoundOption({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.subtitle,
    required this.onChanged,
    required this.onPreview,
  });

  final String value;
  final String groupValue;
  final String title;
  final String subtitle;
  final ValueChanged<String?> onChanged;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RadioListTile<String>(
            value: value,
            groupValue: groupValue,
            title: Text(title),
            subtitle: Text(subtitle),
            onChanged: onChanged,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.play_circle_outline_rounded),
          tooltip: 'Preview',
          onPressed: onPreview,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(color: AppTheme.muted),
    );
  }
}
