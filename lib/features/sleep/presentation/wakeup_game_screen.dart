import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/services/analytics_service.dart';
import '../../../core/services/haptics_service.dart';

// ─── Lane colors (matches app palette) ────────────────────────────────────────
const _laneColors = [
  Color(0xFFE91E63), // pink  — medicine
  Color(0xFF2196F3), // blue  — water
  Color(0xFF7C3AED), // purple— habits
  Color(0xFFFF6D00), // orange— streak
];

// ─── Root screen ─────────────────────────────────────────────────────────────

class WakeupGameScreen extends StatefulWidget {
  const WakeupGameScreen({super.key, this.forceGameIndex});
  final int? forceGameIndex;

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
    _gameIndex = widget.forceGameIndex ?? _todayGameIndex();
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
    _nativeCh.invokeMethod('stopMusic');
    super.dispose();
  }

  static int _todayGameIndex() {
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
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
      if (box.get(_dateKey(today.subtract(Duration(days: i)))) == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  Future<void> _onGameComplete() async {
    if (!Hive.isBoxOpen('morning_streaks')) {
      await Hive.openBox<int>('morning_streaks');
    }
    await Hive.box<int>('morning_streaks').put(_dateKey(DateTime.now()), 1);

    if (mounted) {
      setState(() {
        _streak = _calcStreak() + 1;
        _showCelebration = true;
      });
    }

    try { await _nativeCh.invokeMethod('stopMusic'); } catch (_) {}
    try { await _nativeCh.invokeMethod('playChime'); } catch (_) {}
    try { await _ch.invokeMethod('setGameDismissedNormally', true); } catch (_) {}
    AnalyticsService.gameCompleted();

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _onSkip() async {
    try { await _nativeCh.invokeMethod('stopMusic'); } catch (_) {}
    try { await _ch.invokeMethod('setGameDismissedNormally', true); } catch (_) {}
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E1A),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(streak: _streak),
                Expanded(
                  child: _gameIndex == 0
                      ? _SequenceGame(onComplete: _onGameComplete)
                      : _PianoTilesGame(onComplete: _onGameComplete),
                ),
              ],
            ),
            if (_showSkip)
              Positioned(
                bottom: 24,
                right: 20,
                child: AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 600),
                  child: TextButton(
                    onPressed: _onSkip,
                    child: const Text(
                      'Lewati →',
                      style: TextStyle(color: Colors.white30, fontSize: 13),
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

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6D00).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFFFF6D00).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 5),
                Text(
                  streak == 0 ? 'Hari pertama!' : 'Hari ke-$streak',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF6D00),
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

// ─── Game 0: Sequence Memory ──────────────────────────────────────────────────

class _SequenceGame extends StatefulWidget {
  const _SequenceGame({required this.onComplete});
  final VoidCallback onComplete;
  @override
  State<_SequenceGame> createState() => _SequenceGameState();
}

class _SequenceGameState extends State<_SequenceGame>
    with TickerProviderStateMixin {
  late List<int> _sequence;
  List<int> _userInput = [];
  int _round = 0;
  int? _lit;
  int? _confirmLit; // briefly lit after correct tap
  bool _isPlaying = false;
  bool _wrongTap = false;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -16.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -16.0, end: 16.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 16.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _pulseAnim =
        Tween(begin: 1.0, end: 1.12).animate(
            CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));
    _startRound(0);
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _startRound(int round) {
    final rng = Random();
    _sequence = List.generate(round + 3, (_) => rng.nextInt(4));
    _userInput = [];
    _round = round;
    _lit = null;
    _isPlaying = false;
    Future.delayed(const Duration(milliseconds: 600), _playSequence);
  }

  Future<void> _playSequence() async {
    if (!mounted) return;
    setState(() => _isPlaying = true);
    for (final colorIdx in _sequence) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      HapticsService.softTap();
      setState(() => _lit = colorIdx);
      await Future.delayed(const Duration(milliseconds: 550));
      if (!mounted) return;
      setState(() => _lit = null);
    }
    if (mounted) setState(() => _isPlaying = false);
  }

  void _onTap(int i) {
    if (_isPlaying || _wrongTap) return;
    HapticsService.tap();
    final newInput = [..._userInput, i];
    setState(() => _userInput = newInput);

    final pos = newInput.length - 1;
    if (newInput[pos] != _sequence[pos]) {
      setState(() => _wrongTap = true);
      HapticsService.fun();
      _shakeCtrl.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() { _wrongTap = false; _startRound(_round); });
      });
      return;
    }

    _pulseCtrl.forward(from: 0);
    // Flash the tile briefly to confirm registration
    setState(() => _confirmLit = i);
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _confirmLit = null);
    });

    if (newInput.length == _sequence.length) {
      HapticsService.success();
      if (_round == 2) {
        Future.delayed(const Duration(milliseconds: 400), widget.onComplete);
      } else {
        Future.delayed(const Duration(milliseconds: 500), () {
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
        // Round progress dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final done = i < _round;
            final active = i == _round;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: active ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: done
                    ? const Color(0xFF4CC56A)
                    : active
                        ? Colors.white
                        : Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        // Instruction
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _isPlaying ? 'Perhatikan...' : 'Ketuk urutannya!',
            key: ValueKey(_isPlaying),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _isPlaying ? Colors.white54 : Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isPlaying
              ? 'Putaran ${_round + 1}/3  •  ${_sequence.length} warna'
              : '${_userInput.length}/${_sequence.length}',
          style: const TextStyle(color: Colors.white38, fontSize: 13),
        ),
        const SizedBox(height: 48),
        // Tiles
        AnimatedBuilder(
          animation: _shakeAnim,
          builder: (context, child) =>
              Transform.translate(offset: Offset(_shakeAnim.value, 0), child: child),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (i) {
                final lit = _lit == i || _confirmLit == i;
                final tapped = _userInput.isNotEmpty &&
                    _userInput.last == i &&
                    !_isPlaying;
                return GestureDetector(
                  onTap: () => _onTap(i),
                  child: AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (context, child) => Transform.scale(
                      scale: tapped ? _pulseAnim.value : 1.0,
                      child: child,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 80),
                      width: 72,
                      height: 80,
                      decoration: BoxDecoration(
                        color: lit
                            ? _laneColors[i]
                            : _wrongTap
                                ? Colors.red.withValues(alpha: 0.25)
                                : _laneColors[i].withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: lit
                              ? _laneColors[i]
                              : _laneColors[i].withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        boxShadow: lit
                            ? [
                                BoxShadow(
                                  color: _laneColors[i].withValues(alpha: 0.6),
                                  blurRadius: 28,
                                  spreadRadius: 4,
                                )
                              ]
                            : null,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_wrongTap)
          Text(
            'Salah! Ulangi putaran...',
            style: TextStyle(
                color: Colors.red.shade400,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
      ],
    );
  }
}

// ─── Game 2: Piano Tiles ──────────────────────────────────────────────────────

class _Tile {
  final int lane;
  double y;
  bool hit;
  bool missed;
  bool visible;
  double popProgress; // 0→1 over 130ms when hit, drives scale+fade

  _Tile(this.lane)
      : y = -0.15,
        hit = false,
        missed = false,
        visible = true,
        popProgress = 0.0;
}

class _Judgment {
  final String text;
  final Color color;
  final int lane;
  double life;   // 1.0 → 0.0 over 600ms
  double yOff;   // rises from 0 to -56px

  _Judgment(this.text, this.color, this.lane)
      : life = 1.0,
        yOff = 0.0;
}

class _PianoTilesGame extends StatefulWidget {
  const _PianoTilesGame({required this.onComplete});
  final VoidCallback onComplete;
  @override
  State<_PianoTilesGame> createState() => _PianoTilesGameState();
}

class _PianoTilesGameState extends State<_PianoTilesGame>
    with SingleTickerProviderStateMixin {
  static const _nativeCh = MethodChannel('habit_app/native_reminder');
  static const _tileCount = 16;   // total tiles to spawn
  static const _required = 10;   // hits needed
  static const _tileSpeed = 0.45; // fraction of screen per second
  static const _hitZoneStart = 0.72; // top of hit zone (fraction)
  static const _tileHeight = 0.16;  // tile height as fraction of game area

  final List<_Tile> _tiles = [];
  final List<_Judgment> _judgments = [];
  int _spawned = 0;
  int _hits = 0;
  bool _done = false;

  final List<Color?> _laneFlash = [null, null, null, null];

  late Ticker _ticker;
  DateTime? _lastTick;
  double _spawnCooldown = 0.0;
  static const _spawnInterval = 0.7; // seconds between spawns

  // For randomising lanes with today's seed
  late Random _rng;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _rng = Random(now.year * 10000 + now.month * 100 + now.day);
    _ticker = createTicker(_onTick)..start();
    _nativeCh.invokeMethod('startMusic');
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_done) return;
    final now = DateTime.now();
    final dt = _lastTick == null
        ? 0.016
        : (now.difference(_lastTick!).inMicroseconds / 1e6).clamp(0.0, 0.1);
    _lastTick = now;

    // Spawn new tiles
    _spawnCooldown -= dt;
    if (_spawnCooldown <= 0 && _spawned < _tileCount) {
      // Pick a lane that's not the same as last tile (avoid doubles)
      int lane;
      do {
        lane = _rng.nextInt(4);
      } while (_tiles.isNotEmpty && _tiles.last.lane == lane);
      _tiles.add(_Tile(lane));
      _spawned++;
      _spawnCooldown = _spawnInterval;
    }

    // Move tiles + drive pop animation
    bool changed = false;
    for (final t in _tiles) {
      if (t.hit) {
        // Drive pop
        t.popProgress = (t.popProgress + dt / 0.13).clamp(0.0, 1.0);
        if (t.popProgress >= 1.0) t.visible = false;
        changed = true;
        continue;
      }
      if (t.missed) continue;
      t.y += _tileSpeed * dt;
      if (t.y > 1.0 + _tileHeight) {
        t.missed = true;
        t.visible = false;
        changed = true;
      }
    }

    // Drive judgment text animations
    for (final j in _judgments) {
      j.life = (j.life - dt / 0.6).clamp(0.0, 1.0);
      j.yOff -= 56 * dt / 0.6;
    }
    _judgments.removeWhere((j) => j.life <= 0);

    // Remove tiles that are fully gone
    _tiles.removeWhere((t) => !t.visible && (t.hit || t.missed));

    // Check end condition
    if (_hits >= _required && !_done) {
      _done = true;
      _ticker.stop();
      Future.delayed(const Duration(milliseconds: 200), widget.onComplete);
    } else if (_spawned >= _tileCount && _tiles.isEmpty && !_done) {
      // All tiles gone, didn't reach target — restart
      setState(() {
        _spawned = 0;
        _hits = 0;
        _spawnCooldown = 0;
        _rng = Random(DateTime.now().millisecondsSinceEpoch);
      });
    } else if (changed || !_done) {
      setState(() {});
    }
  }

  void _onLaneTap(int lane) {
    if (_done) return;

    // Find the lowest tile in this lane that's in or approaching hit zone
    _Tile? best;
    double bestY = -1;
    for (final t in _tiles) {
      if (t.hit || t.missed || t.lane != lane) continue;
      if (t.y >= _hitZoneStart - 0.05 && t.y <= _hitZoneStart + _tileHeight + 0.05) {
        if (t.y > bestY) {
          bestY = t.y;
          best = t;
        }
      }
    }

    if (best != null) {
      // Determine judgment: how centered was the tile in the zone?
      final center = _hitZoneStart + _tileHeight / 2;
      final distance = (best.y - center).abs();
      final isPerfect = distance < _tileHeight * 0.3;
      final label = isPerfect ? 'Perfect' : 'Good';
      final color = isPerfect ? const Color(0xFF4CC56A) : const Color(0xFFFFB300);

      HapticsService.tap();
      setState(() {
        best!.hit = true;
        _hits++;
        _laneFlash[lane] = _laneColors[lane];
        _judgments.add(_Judgment(label, color, lane));
      });
      Future.delayed(const Duration(milliseconds: 180), () {
        if (mounted) setState(() => _laneFlash[lane] = null);
      });
    } else {
      HapticsService.fun();
      setState(() {
        _laneFlash[lane] = Colors.red.withValues(alpha: 0.45);
        _judgments.add(_Judgment('Miss', Colors.redAccent, lane));
      });
      Future.delayed(const Duration(milliseconds: 220), () {
        if (mounted) setState(() => _laneFlash[lane] = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Score bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Progress
              Row(
                children: List.generate(_required, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 3),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _hits
                          ? const Color(0xFF4CC56A)
                          : Colors.white12,
                    ),
                  );
                }),
              ),
              Text(
                '$_hits/$_required',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // Board
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gameH = constraints.maxHeight;
              final gameW = constraints.maxWidth;
              final laneW = gameW / 4;
              final hitZoneTopPx = gameH * _hitZoneStart;
              final tileHeightPx = gameH * _tileHeight;

              return Stack(
                children: [
                  // Lane backgrounds + dividers
                  ...List.generate(4, (lane) {
                    return Positioned(
                      left: lane * laneW,
                      top: 0,
                      width: laneW,
                      height: gameH,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        decoration: BoxDecoration(
                          color: _laneFlash[lane] != null
                              ? _laneFlash[lane]!.withValues(alpha: 0.22)
                              : Colors.transparent,
                          border: Border(
                            right: lane < 3
                                ? BorderSide(
                                    color: Colors.white.withValues(alpha: 0.06),
                                    width: 1)
                                : BorderSide.none,
                          ),
                        ),
                      ),
                    );
                  }),

                  // Hit zone line + glow
                  Positioned(
                    left: 0,
                    right: 0,
                    top: hitZoneTopPx,
                    child: Container(
                      height: tileHeightPx,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        border: Border(
                          top: BorderSide(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1),
                          bottom: BorderSide(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1),
                        ),
                      ),
                    ),
                  ),

                  // Tiles (normal falling + pop animation)
                  ..._tiles.where((t) => t.visible).map((t) {
                    final top = t.y * gameH;
                    // Pop: scale up + fade out
                    final scale = t.hit
                        ? 1.0 + t.popProgress * 0.4
                        : 1.0;
                    final opacity = t.hit
                        ? (1.0 - t.popProgress).clamp(0.0, 1.0)
                        : 1.0;
                    return Positioned(
                      left: t.lane * laneW + 3,
                      top: top,
                      width: laneW - 6,
                      height: tileHeightPx - 4,
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _laneColors[t.lane],
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: _laneColors[t.lane].withValues(alpha: 0.5),
                                  blurRadius: t.hit ? 24 : 12,
                                  spreadRadius: t.hit ? 4 : 1,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  // Tap areas (whole lane, full height)
                  ...List.generate(4, (lane) {
                    return Positioned(
                      left: lane * laneW,
                      top: 0,
                      width: laneW,
                      height: gameH,
                      child: GestureDetector(
                        onTapDown: (_) => _onLaneTap(lane),
                        behavior: HitTestBehavior.opaque,
                        child: const SizedBox.expand(),
                      ),
                    );
                  }),

                  // Judgment text overlays
                  ..._judgments.map((j) {
                    final laneCenter = (j.lane + 0.5) * laneW;
                    return Positioned(
                      left: laneCenter - 40,
                      bottom: gameH * (1 - _hitZoneStart) + (-j.yOff),
                      width: 80,
                      child: Opacity(
                        opacity: j.life.clamp(0.0, 1.0),
                        child: Text(
                          j.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: j.color,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: j.color.withValues(alpha: 0.6),
                                blurRadius: 8,
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  // Lane color dots at bottom
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Row(
                      children: List.generate(4, (lane) {
                        return Expanded(
                          child: Center(
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _laneColors[lane]
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Celebration overlay ──────────────────────────────────────────────────────

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
        vsync: this, duration: const Duration(milliseconds: 800));
    _scale = Tween(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.35)));
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
          color: const Color(0xFF0B0E1A).withValues(alpha: 0.9),
          child: Center(
            child: Transform.scale(
              scale: _scale.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF4CC56A).withValues(alpha: 0.15),
                      border: Border.all(
                          color: const Color(0xFF4CC56A), width: 2),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF4CC56A),
                      size: 52,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Selamat pagi! 🔥',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Game selesai. Selamat beraktivitas!',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
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
