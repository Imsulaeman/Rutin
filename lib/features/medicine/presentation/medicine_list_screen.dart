import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/services/analytics_service.dart';
import '../../../core/services/haptics_service.dart';
import '../../../shared/providers/providers.dart';
import '../../notifications/alarm_service.dart';
import '../data/medicine_model.dart';
import '../data/medicine_repository.dart';

const _navy = Color(0xFF0B0E1A);
const _surface = Color(0xFF161D2E);
const _surfaceLine = Color(0xFF222C42);
const _medGradient = [Color(0xFFEE5A8C), Color(0xFFD93A6E)];
const _green = Color(0xFF4CC56A);
const _grey = Color(0xFF9AA3B2);
const _missed = Color(0xFFF36B5B);

enum _DoseBucket { now, upcoming, taken, missed }

class _Dose {
  _Dose(this.medicine, this.minute, this.scheduled);

  final Medicine medicine;
  final int minute;
  final DateTime scheduled;
}

class MedicineListScreen extends ConsumerStatefulWidget {
  const MedicineListScreen({super.key});

  @override
  ConsumerState<MedicineListScreen> createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends ConsumerState<MedicineListScreen>
    with WidgetsBindingObserver {
  Map<int, Map<String, int>> _reminderDebug = const {};
  String _debugFingerprint = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _drainPending();
    _refreshReminderDebug(ref.read(medicineRepositoryProvider));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _drainPending();
      _refreshReminderDebug(ref.read(medicineRepositoryProvider), force: true);
    }
  }

  Future<void> _drainPending() async {
    final events = await AlarmService.getPendingTaken();
    if (events.isEmpty || !mounted) return;
    final repo = ref.read(medicineRepositoryProvider);
    for (final e in events) {
      final parts = e.split('|');
      if (parts.length < 2) continue;
      final alarmId = int.tryParse(parts[0]);
      final scheduledMin = parts.length >= 3 ? int.tryParse(parts[1]) : null;
      final firedMs = int.tryParse(parts.length >= 3 ? parts[2] : parts[1]);
      if (alarmId == null || firedMs == null) continue;
      final med = _medicineForAlarm(repo, alarmId);
      if (med == null || med.scheduleTimes.isEmpty) continue;
      final fired = DateTime.fromMillisecondsSinceEpoch(firedMs);
      final firedMin = fired.hour * 60 + fired.minute;
      final minute = scheduledMin ??
          med.scheduleTimes.reduce(
            (a, b) => (a - firedMin).abs() <= (b - firedMin).abs() ? a : b,
          );
      final scheduled = DateTime(
        fired.year,
        fired.month,
        fired.day,
        minute ~/ 60,
        minute % 60,
      );
      await repo.setTaken(med.id, scheduled, true);
    }
    await _refreshReminderDebug(repo, force: true);
    if (mounted) setState(() {});
  }

  Future<void> _refreshReminderDebug(
    MedicineRepository repo, {
    bool force = false,
  }) async {
    final ids = <int>[
      for (final medicine in repo.getAll())
        for (final minute in medicine.scheduleTimes)
          AlarmService.medicineRootAlarmId(medicine.id, minute),
    ]..sort();
    final fingerprint = ids.join(',');
    if (!force && fingerprint == _debugFingerprint) return;

    final next = <int, Map<String, int>>{};
    for (final id in ids) {
      next[id] = await AlarmService.getReminderDebug(id);
    }
    if (!mounted) return;
    setState(() {
      _debugFingerprint = fingerprint;
      _reminderDebug = next;
    });
  }

  static Medicine? _medicineForAlarm(MedicineRepository repo, int alarmId) {
    for (final medicine in repo.getAll()) {
      for (final minute in medicine.scheduleTimes) {
        if (AlarmService.medicineRootAlarmId(medicine.id, minute) == alarmId) {
          return medicine;
        }
      }
    }
    return null;
  }

  List<_Dose> _todayDoses(MedicineRepository repo) {
    final now = DateTime.now();
    final out = <_Dose>[];
    for (final medicine in repo.getAll()) {
      for (final minute in medicine.scheduleTimes) {
        out.add(
          _Dose(
            medicine,
            minute,
            DateTime(now.year, now.month, now.day, minute ~/ 60, minute % 60),
          ),
        );
      }
    }
    out.sort((a, b) => a.minute.compareTo(b.minute));
    return out;
  }

  _DoseBucket _bucketFor(MedicineRepository repo, _Dose dose) {
    if (repo.isTaken(dose.medicine.id, dose.scheduled)) return _DoseBucket.taken;
    final now = DateTime.now();
    final diff = now.difference(dose.scheduled);
    if (diff.inMinutes >= 60) return _DoseBucket.missed;
    if (!dose.scheduled.isAfter(now)) return _DoseBucket.now;
    return _DoseBucket.upcoming;
  }

  Future<void> _toggle(MedicineRepository repo, _Dose dose, bool taken) async {
    if (taken) {
      HapticsService.success();
    } else {
      HapticsService.tap();
    }
    await repo.setTaken(dose.medicine.id, dose.scheduled, taken);
    if (taken) AnalyticsService.medicineTaken(dose.medicine.name);
    if (mounted) setState(() {});
  }

  Future<void> _executeDelete(MedicineRepository repo, Medicine medicine) async {
    for (final minutes in medicine.scheduleTimes) {
      await AlarmService.cancelAllForAlarm(
        AlarmService.medicineRootAlarmId(medicine.id, minutes),
      );
    }
    await repo.delete(medicine.id);
    AnalyticsService.medicineDeleted();
    await _refreshReminderDebug(repo, force: true);
    if (mounted) setState(() {});
  }

  Future<void> _executeArchive(MedicineRepository repo, Medicine medicine) async {
    for (final minutes in medicine.scheduleTimes) {
      await AlarmService.cancelAllForAlarm(
        AlarmService.medicineRootAlarmId(medicine.id, minutes),
      );
    }
    await repo.archive(medicine.id);
    AnalyticsService.medicineArchived();
    await _refreshReminderDebug(repo, force: true);
    if (mounted) setState(() {});
  }

  String? _debugTextFor(_Dose dose) {
    final alarmId =
        AlarmService.medicineRootAlarmId(dose.medicine.id, dose.minute);
    final debug = _reminderDebug[alarmId];
    if (debug == null) return null;
    final baseMillis = debug['baseMillis'];
    if (baseMillis == null || baseMillis <= 0) return null;
    final base = DateTime.fromMillisecondsSinceEpoch(baseMillis);
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final dayLabel = _sameDay(base, DateTime.now())
        ? 'hari ini'
        : _sameDay(base, tomorrow)
            ? 'besok'
            : '${base.day}/${base.month}';
    return 'Berikutnya $dayLabel ${_fmtClock(base)}';
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(medicineRepositoryProvider);
    final medicines = repo.getAll();
    final allDoses = _todayDoses(repo);

    // group doses by medicine id (order from getAll())
    final dosesByMedicine = <String, List<_Dose>>{};
    for (final d in allDoses) {
      dosesByMedicine.putIfAbsent(d.medicine.id, () => []).add(d);
    }

    // counts for the slim banner
    int nowCount = 0, takenCount = 0, missedCount = 0;
    for (final d in allDoses) {
      switch (_bucketFor(repo, d)) {
        case _DoseBucket.now:
          nowCount++;
        case _DoseBucket.taken:
          takenCount++;
        case _DoseBucket.missed:
          missedCount++;
        case _DoseBucket.upcoming:
          break;
      }
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _navy,
        body: SafeArea(
          bottom: false,
          child: ValueListenableBuilder<Box<Medicine>>(
            valueListenable: Hive.box<Medicine>('medicines').listenable(),
            builder: (context, _, _) {
              _refreshReminderDebug(repo);
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _HeaderButton(
                                icon: Icons.arrow_back_rounded,
                                onTap: () => context.go('/'),
                              ),
                              const Expanded(
                                child: Text(
                                  'Obat',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              _HeaderButton(
                                icon: Icons.archive_outlined,
                                onTap: () =>
                                    context.push('/medicine/archive'),
                              ),
                              const SizedBox(width: 4),
                              _HeaderButton(
                                icon: Icons.calendar_month_rounded,
                                onTap: () =>
                                    context.push('/medicine/history'),
                              ),
                              const SizedBox(width: 4),
                              _HeaderButton(
                                icon: Icons.add_rounded,
                                onTap: () => context.push('/medicine/add'),
                              ),
                            ],
                          ),
                          if (allDoses.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _DayBanner(
                              total: allDoses.length,
                              taken: takenCount,
                              nowCount: nowCount,
                              missedCount: missedCount,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (medicines.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(),
                    )
                  else ...[
                    for (final medicine in medicines)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          child: _SwipeMedicine(
                            key: ValueKey('med_${medicine.id}'),
                            medicine: medicine,
                            onDelete: () => _executeDelete(repo, medicine),
                            onArchive: () => _executeArchive(repo, medicine),
                            child: _MedicineCard(
                              medicine: medicine,
                              doses: dosesByMedicine[medicine.id] ?? [],
                              bucketFor: (d) => _bucketFor(repo, d),
                              onToggle: (dose, taken) =>
                                  _toggle(repo, dose, taken),
                              debugTextFor: _debugTextFor,
                            ),
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 28)),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Header button ───────────────────────────────────────────────────────────

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, color: Colors.white, size: 23),
      ),
    );
  }
}

// ─── Slim day banner ─────────────────────────────────────────────────────────

class _DayBanner extends StatelessWidget {
  const _DayBanner({
    required this.total,
    required this.taken,
    required this.nowCount,
    required this.missedCount,
  });

  final int total;
  final int taken;
  final int nowCount;
  final int missedCount;

  @override
  Widget build(BuildContext context) {
    final String statusText;

    if (nowCount > 0) {
      statusText = '$nowCount perlu diminum';
    } else if (missedCount > 0) {
      statusText = '$missedCount terlewat';
    } else if (taken == total) {
      statusText = 'Semua sudah diminum';
    } else {
      statusText = '$taken/$total selesai';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF3789F), Color(0xFFEE5A8C), Color(0xFFD93A6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD93A6E).withValues(alpha: 0.38),
            blurRadius: 22,
            spreadRadius: -6,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            _todayLabel(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Per-medicine card with dose chips ───────────────────────────────────────

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({
    required this.medicine,
    required this.doses,
    required this.bucketFor,
    required this.onToggle,
    required this.debugTextFor,
  });

  final Medicine medicine;
  final List<_Dose> doses;
  final _DoseBucket Function(_Dose) bucketFor;
  final Future<void> Function(_Dose dose, bool taken) onToggle;
  final String? Function(_Dose) debugTextFor;

  @override
  Widget build(BuildContext context) {
    // Show next alarm for the most relevant dose:
    // prefer upcoming/now doses; fall back to any dose if all taken/missed.
    final relevantDose = doses.firstWhere(
      (d) {
        final b = bucketFor(d);
        return b == _DoseBucket.now || b == _DoseBucket.upcoming;
      },
      orElse: () => doses.first,
    );
    final debugText = debugTextFor(relevantDose)
        ?? doses.map(debugTextFor).where((t) => t != null).firstOrNull;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1524),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _surfaceLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  medicine.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _Badge(
                icon: Icons.restaurant_rounded,
                label: MedicineMealTiming.label(medicine.mealTimingKey),
              ),
            ],
          ),
          if ((medicine.dosage ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              medicine.dosage!,
              style: const TextStyle(color: _grey, fontSize: 13),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final dose in doses)
                _DoseChip(
                  dose: dose,
                  bucket: bucketFor(dose),
                  onTap: () =>
                      onToggle(dose, bucketFor(dose) != _DoseBucket.taken),
                ),
            ],
          ),
          if (debugText != null) ...[
            const SizedBox(height: 8),
            _Badge(
              icon: Icons.alarm_rounded,
              label: debugText,
              foreground: _green,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Dose chip ───────────────────────────────────────────────────────────────

class _DoseChip extends StatelessWidget {
  const _DoseChip({
    required this.dose,
    required this.bucket,
    required this.onTap,
  });

  final _Dose dose;
  final _DoseBucket bucket;
  final VoidCallback onTap;

  Color get _bg => switch (bucket) {
    _DoseBucket.taken => _green.withValues(alpha: 0.12),
    _DoseBucket.missed => _missed.withValues(alpha: 0.12),
    _ => const Color(0xFF1A2236),
  };

  Color get _fg => switch (bucket) {
    _DoseBucket.taken => _green,
    _DoseBucket.now => Colors.white,
    _DoseBucket.missed => _missed,
    _DoseBucket.upcoming => _grey,
  };

  @override
  Widget build(BuildContext context) {
    final isNow = bucket == _DoseBucket.now;
    final isTaken = bucket == _DoseBucket.taken;
    final isMissed = bucket == _DoseBucket.missed;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient:
              isNow ? const LinearGradient(colors: _medGradient) : null,
          color: isNow ? null : _bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isTaken
                ? _green.withValues(alpha: 0.4)
                : isMissed
                    ? _missed.withValues(alpha: 0.3)
                    : isNow
                        ? Colors.transparent
                        : _surfaceLine,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isTaken) ...[
              const Icon(Icons.check_rounded, size: 13, color: _green),
              const SizedBox(width: 4),
            ] else if (isMissed) ...[
              Icon(Icons.close_rounded, size: 13, color: _missed),
              const SizedBox(width: 4),
            ],
            Text(
              _fmtMinute(dose.minute),
              style: TextStyle(
                color: _fg,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    this.foreground = _grey,
  });

  final IconData icon;
  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeMedicine extends StatelessWidget {
  const _SwipeMedicine({
    required super.key,
    required this.medicine,
    required this.onDelete,
    required this.onArchive,
    required this.child,
  });

  final Medicine medicine;
  final Future<void> Function() onDelete;
  final Future<void> Function() onArchive;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: key!,
      // swipe right → archive (amber)
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF4A92B),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.archive_outlined, color: Colors.white),
      ),
      // swipe left → delete (red)
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: Theme.of(context).colorScheme.onError,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: _surface,
                  title: const Text(
                    'Arsipkan obat?',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: Text(
                    '${medicine.name} disembunyikan dari daftar hari ini. Riwayat tetap tersimpan.',
                    style: const TextStyle(color: _grey),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF4A92B),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Arsipkan'),
                    ),
                  ],
                ),
              ) ??
              false;
        } else {
          return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: _surface,
                  title: const Text(
                    'Hapus obat?',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: Text(
                    '${medicine.name} akan dihapus permanen beserta riwayatnya.',
                    style: const TextStyle(color: _grey),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _medGradient.last,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Hapus'),
                    ),
                  ],
                ),
              ) ??
              false;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          onArchive();
        } else {
          onDelete();
        }
      },
      child: child,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(36),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: _medGradient.first.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.medication_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada obat hari ini',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tambah jadwal obat dari tombol + agar dosis hari ini langsung muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _grey, fontSize: 13, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _fmtMinute(int minutes) {
  final hour = (minutes ~/ 60).toString().padLeft(2, '0');
  final minute = (minutes % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _fmtClock(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _todayLabel() {
  const days = [
    'Minggu',
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
  ];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  final now = DateTime.now();
  return '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}';
}
