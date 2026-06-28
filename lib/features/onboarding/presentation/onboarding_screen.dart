import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/services/tutorial_trigger.dart';
import '../../../l10n/l10n.dart';
import '../../../main.dart';

const _bg = Color(0xFF0B0E1A);
const _surface = Color(0xFF111A2A);
const _border = Color(0xFF1E2A3D);
const _muted = Color(0xFF9AA3B2);
const _accent = Color(0xFFF4A92B);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  bool _busy = false;

  Future<void> _finish() async {
    await Hive.box<String>('app_settings').put('onboarding_done', 'true');
    if (mounted) context.go('/');
  }

  Future<void> _requestAndFinish() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final android = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        await android.requestNotificationsPermission();
        await android.requestExactAlarmsPermission();
      }
    } catch (_) {}
    TutorialTrigger.fire();
    await _finish();
  }

  void _next() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == 2;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  context.l10n.skip,
                  style: const TextStyle(color: _muted, fontSize: 14),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _OnboardingPage(
                    headline: context.l10n.onboarding1Headline,
                    body: context.l10n.onboarding1Body,
                  ),
                  _OnboardingPage(
                    asset: 'assets/star_mascot.webp',
                    headline: context.l10n.onboarding2Headline,
                    body: context.l10n.onboarding2Body,
                  ),
                  _OnboardingPage(
                    asset: 'assets/flame_mascot.webp',
                    headline: context.l10n.onboarding3Headline,
                    body: context.l10n.onboarding3Body,
                  ),
                ],
              ),
            ),
            _DotIndicator(count: 3, current: _page),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: _busy
                      ? null
                      : isLast
                          ? _requestAndFinish
                          : _next,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black54,
                          ),
                        )
                      : Text(
                          isLast ? context.l10n.enableAndStart : context.l10n.next,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    this.asset,
    required this.headline,
    required this.body,
  });

  final String? asset;
  final String headline;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (asset != null) ...[
            Image.asset(asset!, height: 200, fit: BoxFit.contain),
            const SizedBox(height: 40),
          ],
          Text(
            headline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: _muted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? _accent : _surface,
            borderRadius: BorderRadius.circular(4),
            border: active ? null : Border.all(color: _border),
          ),
        );
      }),
    );
  }
}
