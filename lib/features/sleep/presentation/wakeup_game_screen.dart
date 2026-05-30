import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/services/analytics_service.dart';

class WakeupGameScreen extends StatefulWidget {
  const WakeupGameScreen({super.key});
  @override
  State<WakeupGameScreen> createState() => _WakeupGameScreenState();
}

class _WakeupGameScreenState extends State<WakeupGameScreen> {
  static const _ch = MethodChannel('rutin/sleep');
  static const _nativeCh = MethodChannel('habit_app/native_reminder');

  late int _gameIndex;
  int _streak = 0;
  Timer? _skipTimer;
  bool _showSkip = false;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _gameIndex = _todayGameIndex();
    _skipTimer = Timer(const Duration(seconds: 15), () {
      if (mounted) setState(() => _showSkip = true);
    });
    _ch.invokeMethod('setGameActive', true);
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    if (!Hive.isBoxOpen('morning_streaks')) {
      await Hive.openBox<int>('morning_streaks');
    }
    if (mounted) setState(() => _streak = _calcStreak());
  }

  @override
  void dispose() {
    _skipTimer?.cancel();
    _ch.invokeMethod('setGameActive', false);
    super.dispose();
  }

  static int _todayGameIndex() {
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    // Only games 0 (Sequence) and 2 (Rhythm) are implemented
    return const [0, 2][Random(seed).nextInt(2)];
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int _calcStreak() {
    if (!Hive.isBoxOpen('morning_streaks')) return 0;
    final box = Hive.box<int>('morning_streaks');
    final today = DateTime.now();
    int streak = 0;
    for (int i = 1; i <= 365; i++) {
      final key = _dateKey(today.subtract(Duration(days: i)));
      if (box.get(key) == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  Future<void> _onGameComplete() async {
    final now = DateTime.now();
    final key = _dateKey(now);
    if (!Hive.isBoxOpen('morning_streaks')) {
      await Hive.openBox<int>('morning_streaks');
    }
    await Hive.box<int>('morning_streaks').put(key, 1);

    if (mounted) {
      setState(() {
        _streak = _calcStreak() + 1; // +1 for today just completed
        _showCelebration = true;
      });
    }

    // Play chime via native
    try {
      await _nativeCh.invokeMethod('playChime');
    } catch (_) {}

    // Mark dismissed normally so AccessibilityService won't intercept
    try {
      await _ch.invokeMethod('setGameDismissedNormally', true);
    } catch (_) {}

    // Log analytics
    AnalyticsService.gameCompleted();

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _onSkip() async {
    try {
      await _ch.invokeMethod('setGameDismissedNormally', true);
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E1A),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFFFF6D00),
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Hari ke-$_streak 🔥',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _gameIndex == 0
                      ? _SequenceGame(onComplete: _onGameComplete)
                      : _RhythmGame(onComplete: _onGameComplete),
                ),
              ],
            ),
            if (_showSkip)
              Positioned(
                bottom: 28,
                right: 24,
                child: AnimatedOpacity(
                  opacity: _showSkip ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: TextButton(
                    onPressed: _onSkip,
                    child: const Text(
                      'Lewati →',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ),
                ),
              ),
            if (_showCelebration)
              Positioned.fill(child: _CelebrationOverlay()),
          ],
        ),
      ),
    );
  }
}

// ─── Game 0: Sequence Memory ────────────────────────────────────────────────

class _SequenceGame extends StatefulWidget {
  const _SequenceGame({required this.onComplete});
  final VoidCallback onComplete;
  @override
  State<_SequenceGame> createState() => _SequenceGameState();
}

class _SequenceGameState extends State<_SequenceGame>
    with SingleTickerProviderStateMixin {
  static const _colors = [
    Color(0xFFE91E63), // pink
    Color(0xFF2196F3), // blue
    Color(0xFF4CAF50), // green
    Color(0xFFFFB300), // amber
  ];

  late List<int> _sequence;
  List<int> _userInput = [];
  int _round = 0; // 0,1,2 → lengths 3,4,5
  int? _lit;
  bool _isPlaying = false;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: -14.0), weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: -14.0, end: 14.0), weight: 2),
      TweenSequenceItem(
          tween: Tween(begin: 14.0, end: 0.0), weight: 1),
    ]).animate(_shakeCtrl);
    _startRound(0);
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _startRound(int round) {
    final len = round + 3;
    final rng = Random();
    _sequence = List.generate(len, (_) => rng.nextInt(4));
    _userInput = [];
    _round = round;
    Future.delayed(const Duration(milliseconds: 500), _playSequence);
  }

  Future<void> _playSequence() async {
    if (!mounted) return;
    setState(() {
      _isPlaying = true;
      _lit = null;
    });
    for (final colorIdx in _sequence) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      setState(() => _lit = colorIdx);
      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      setState(() => _lit = null);
    }
    if (mounted) setState(() => _isPlaying = false);
  }

  void _onTap(int colorIdx) {
    if (_isPlaying) return;
    final newInput = [..._userInput, colorIdx];
    setState(() => _userInput = newInput);

    final pos = newInput.length - 1;
    if (newInput[pos] != _sequence[pos]) {
      HapticFeedback.heavyImpact();
      _shakeCtrl.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _startRound(_round));
      });
      return;
    }

    if (newInput.length == _sequence.length) {
      HapticFeedback.mediumImpact();
      if (_round == 2) {
        Future.delayed(
            const Duration(milliseconds: 300), widget.onComplete);
      } else {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) setState(() => _startRound(_round + 1));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Putaran ${_round + 1} dari 3',
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Text(
          _isPlaying ? 'Perhatikan urutan...' : 'Ketuk urutannya!',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${_userInput.length} / ${_sequence.length}',
          style: const TextStyle(color: Colors.white38, fontSize: 13),
        ),
        const SizedBox(height: 48),
        AnimatedBuilder(
          animation: _shakeAnim,
          builder: (context, child) => Transform.translate(
            offset: Offset(_shakeAnim.value, 0),
            child: child,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final lit = _lit == i;
              return GestureDetector(
                onTap: () => _onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: lit
                        ? _colors[i]
                        : _colors[i].withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: lit
                        ? [
                            BoxShadow(
                              color: _colors[i].withValues(alpha: 0.6),
                              blurRadius: 22,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ─── Game 2: Tap Rhythm ──────────────────────────────────────────────────────

class _RhythmGame extends StatefulWidget {
  const _RhythmGame({required this.onComplete});
  final VoidCallback onComplete;
  @override
  State<_RhythmGame> createState() => _RhythmGameState();
}

class _RhythmGameState extends State<_RhythmGame>
    with SingleTickerProviderStateMixin {
  static const _total = 10;
  static const _required = 7;

  int _current = 0;
  int _hits = 0;
  bool _done = false;
  bool _hitFlash = false;
  bool _tooEarly = false;
  bool _tapped = false; // track if current circle was tapped

  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _ctrl.addStatusListener(_onStatus);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_done) {
      setState(() {
        _current++;
        _tapped = false;
      });
      if (_current < _total) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) _ctrl.forward(from: 0);
        });
      }
    }
  }

  void _onTap() {
    if (_done || _tapped) return;
    final pos = _ctrl.value;
    if (pos >= 0.68) {
      // In zone
      HapticFeedback.lightImpact();
      _tapped = true;
      _ctrl.stop();
      setState(() {
        _hits++;
        _hitFlash = true;
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _hitFlash = false);
      });

      if (_hits >= _required) {
        setState(() => _done = true);
        Future.delayed(
            const Duration(milliseconds: 300), widget.onComplete);
        return;
      }

      _current++;
      _tapped = false;
      if (_current < _total) {
        Future.delayed(
            const Duration(milliseconds: 250), () {
          if (mounted) _ctrl.forward(from: 0);
        });
      }
    } else {
      setState(() => _tooEarly = true);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _tooEarly = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final gameH = size.height * 0.55;
    final zoneH = gameH * 0.22;

    return GestureDetector(
      onTapDown: (_) => _onTap(),
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(_current + 1).clamp(1, _total)}/$_total',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF4CAF50), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$_hits / $_required dibutuhkan',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            _tooEarly
                ? 'Terlalu cepat!'
                : 'Ketuk saat di zona hijau!',
            style: TextStyle(
              color: _tooEarly ? const Color(0xFFFFB300) : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: gameH,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                final y = _ctrl.value;
                final circleTop = y * (gameH - zoneH - 60);
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Tap zone
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: zoneH,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: _hitFlash
                              ? const Color(0xFF4CAF50).withValues(alpha: 0.35)
                              : const Color(0xFF4CAF50).withValues(alpha: 0.1),
                          border: Border(
                            top: BorderSide(
                              color: const Color(0xFF4CAF50)
                                  .withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'TAP ZONE',
                            style: TextStyle(
                              color: const Color(0xFF4CAF50)
                                  .withValues(alpha: 0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Falling circle
                    if (_current < _total && !_done)
                      Positioned(
                        top: circleTop,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: y >= 0.68
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFF2196F3),
                              boxShadow: [
                                BoxShadow(
                                  color: (y >= 0.68
                                          ? const Color(0xFF4CAF50)
                                          : const Color(0xFF2196F3))
                                      .withValues(alpha: 0.45),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${_current + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Celebration overlay ─────────────────────────────────────────────────────

class _CelebrationOverlay extends StatefulWidget {
  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = Tween(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _fade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.4)),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => Opacity(
        opacity: _fade.value,
        child: Container(
          color: Colors.black.withValues(alpha: 0.75),
          child: Center(
            child: Transform.scale(
              scale: _scale.value,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF4CC56A),
                    size: 88,
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Selesai! 🔥',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Selamat pagi!',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
