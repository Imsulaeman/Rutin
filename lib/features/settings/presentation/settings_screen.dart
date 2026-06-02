import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../sleep/data/sleep_model.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _checkAccessibility();
    _checkFullScreenIntent();
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

  Future<void> _openFullScreenIntentSettings() async {
    await _nativeCh.invokeMethod('openFullScreenIntentSettings');
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
                              : localized(
                                  context,
                                  id: 'Belum diizinkan, diperlukan untuk Mode Tidur',
                                  en: 'Not allowed yet, required for Sleep Mode',
                                ),
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
                _SectionLabel(
                  localized(
                    context,
                    id: 'ALARM OBAT',
                    en: 'MEDICINE ALARM',
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: Icon(
                      _fullScreenIntentAllowed
                          ? Icons.fullscreen_rounded
                          : Icons.warning_amber_rounded,
                      color: _fullScreenIntentAllowed ? _green : _amber,
                    ),
                    title: Text(
                      localized(
                        context,
                        id: 'Alarm layar penuh',
                        en: 'Full-screen alarm',
                      ),
                    ),
                    subtitle: Text(
                      _fullScreenIntentAllowed
                          ? localized(
                              context,
                              id: 'Diizinkan, alarm bisa mengambil alih layar',
                              en: 'Allowed, alarms can take over the screen',
                            )
                          : localized(
                              context,
                              id: 'Belum diizinkan, alarm bisa turun jadi heads-up saja',
                              en: 'Not allowed yet, alarms may stay as heads-up only',
                            ),
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
