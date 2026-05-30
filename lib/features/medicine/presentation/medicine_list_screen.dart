import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../shared/providers/providers.dart';
import '../../notifications/alarm_service.dart';
import '../data/medicine_model.dart';
import '../data/medicine_repository.dart';

const _navy = Color(0xFF0B0E1A);
const _surface = Color(0xFF161D2E);
const _surfaceLine = Color(0xFF222C42);
const _medGradient = [Color(0xFFEE5A8C), Color(0xFFD93A6E)];
const _green = Color(0xFF4CC56A);
const _amber = Color(0xFFF4A92B);
const _grey = Color(0xFF9AA3B2);

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
    HapticFeedback.selectionClick();
    await repo.setTaken(dose.medicine.id, dose.scheduled, taken);
    if (mounted) setState(() {});
  }

  Future<void> _confirmDelete(MedicineRepository repo, Medicine medicine) async {
    HapticFeedback.mediumImpact();
    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: _surface,
            title: const Text('Hapus obat?', style: TextStyle(color: Colors.white)),
            content: Text(
              '${medicine.name} akan dihapus permanen.',
              style: const TextStyle(color: _grey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _medGradient.last),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;

    for (final minutes in medicine.scheduleTimes) {
      await AlarmService.cancelAllForAlarm(
        AlarmService.medicineRootAlarmId(medicine.id, minutes),
      );
    }
    await repo.delete(medicine.id);
    await _refreshReminderDebug(repo, force: true);
    if (mounted) setState(() {});
  }

  String? _debugTextFor(_Dose dose) {
    final alarmId = AlarmService.medicineRootAlarmId(dose.medicine.id, dose.minute);
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
    final doses = _todayDoses(repo);
    final nowDoses = [for (final d in doses) if (_bucketFor(repo, d) == _DoseBucket.now) d];
    final upcomingDoses = [
      for (final d in doses)
        if (_bucketFor(repo, d) == _DoseBucket.upcoming) d,
    ];
    final takenDoses = [for (final d in doses) if (_bucketFor(repo, d) == _DoseBucket.taken) d];
    final missedDoses = [for (final d in doses) if (_bucketFor(repo, d) == _DoseBucket.missed) d];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: _navy,
        body: SafeArea(
          bottom: false,
          child: ValueListenableBuilder<Box<Medicine>>(
            valueListenable: Hive.box<Medicine>('medicines').listenable(),
            builder: (context, _, __) {
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
                                icon: Icons.calendar_month_rounded,
                                onTap: () => context.push('/medicine/history'),
                              ),
                              const SizedBox(width: 6),
                              _HeaderButton(
                                icon: Icons.add_rounded,
                                onTap: () => context.push('/medicine/add'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _HeroSummary(
                            nowCount: nowDoses.length,
                            upcomingCount: upcomingDoses.length,
                            takenCount: takenDoses.length,
                            missedCount: missedDoses.length,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (doses.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(),
                    )
                  else ...[
                    _DoseSectionSliver(
                      title: 'Perlu diminum sekarang',
                      subtitle: 'Yang sedang aktif dan terus diingatkan.',
                      accent: _medGradient.first,
                      doses: nowDoses,
                      repo: repo,
                      onToggle: _toggle,
                      onDelete: _confirmDelete,
                      debugTextFor: _debugTextFor,
                    ),
                    _DoseSectionSliver(
                      title: 'Berikutnya',
                      subtitle: 'Dosis berikutnya untuk hari ini.',
                      accent: _amber,
                      doses: upcomingDoses,
                      repo: repo,
                      onToggle: _toggle,
                      onDelete: _confirmDelete,
                      debugTextFor: _debugTextFor,
                    ),
                    _DoseSectionSliver(
                      title: 'Sudah diminum',
                      subtitle: 'Yang sudah selesai hari ini.',
                      accent: _green,
                      doses: takenDoses,
                      repo: repo,
                      onToggle: _toggle,
                      onDelete: _confirmDelete,
                      debugTextFor: _debugTextFor,
                    ),
                    _DoseSectionSliver(
                      title: 'Terlewat',
                      subtitle: 'Belum diminum lebih dari 1 jam.',
                      accent: const Color(0xFFF36B5B),
                      doses: missedDoses,
                      repo: repo,
                      onToggle: _toggle,
                      onDelete: _confirmDelete,
                      debugTextFor: _debugTextFor,
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

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({
    required this.nowCount,
    required this.upcomingCount,
    required this.takenCount,
    required this.missedCount,
  });

  final int nowCount;
  final int upcomingCount;
  final int takenCount;
  final int missedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF3789F), ..._medGradient],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _medGradient.last.withValues(alpha: 0.4),
            blurRadius: 26,
            spreadRadius: -8,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hari ini',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _todayLabel(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _SummaryChip(label: 'Sekarang', value: nowCount.toString())),
              const SizedBox(width: 10),
              Expanded(child: _SummaryChip(label: 'Berikutnya', value: upcomingCount.toString())),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _SummaryChip(label: 'Selesai', value: takenCount.toString())),
              const SizedBox(width: 10),
              Expanded(child: _SummaryChip(label: 'Terlewat', value: missedCount.toString())),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.86),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoseSectionSliver extends StatelessWidget {
  const _DoseSectionSliver({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.doses,
    required this.repo,
    required this.onToggle,
    required this.onDelete,
    required this.debugTextFor,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final List<_Dose> doses;
  final MedicineRepository repo;
  final Future<void> Function(MedicineRepository repo, _Dose dose, bool taken) onToggle;
  final Future<void> Function(MedicineRepository repo, Medicine medicine) onDelete;
  final String? Function(_Dose dose) debugTextFor;

  @override
  Widget build(BuildContext context) {
    if (doses.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: _SectionShell(
            title: title,
            subtitle: subtitle,
            accent: accent,
            child: const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Belum ada item di bagian ini.',
                style: TextStyle(color: _grey, fontSize: 13),
              ),
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        child: _SectionShell(
          title: title,
          subtitle: subtitle,
          accent: accent,
          child: Column(
            children: [
              for (int i = 0; i < doses.length; i++) ...[
                _SwipeToDeleteMedicine(
                  key: ValueKey(
                    'dose_${doses[i].medicine.id}_${doses[i].minute}_${title}_$i',
                  ),
                  medicine: doses[i].medicine,
                  onDelete: () => onDelete(repo, doses[i].medicine),
                  child: _DoseTile(
                    dose: doses[i],
                    taken: repo.isTaken(doses[i].medicine.id, doses[i].scheduled),
                    debugText: debugTextFor(doses[i]),
                    onToggle: (value) => onToggle(repo, doses[i], value),
                  ),
                ),
                if (i != doses.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _surfaceLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: _grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DoseTile extends StatelessWidget {
  const _DoseTile({
    required this.dose,
    required this.taken,
    required this.debugText,
    required this.onToggle,
  });

  final _Dose dose;
  final bool taken;
  final String? debugText;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1524),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _surfaceLine),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dose.medicine.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            decoration: taken ? TextDecoration.lineThrough : null,
                            decorationColor: _grey,
                          ),
                        ),
                      ),
                      _TimePill(label: _fmtMinute(dose.minute)),
                    ],
                  ),
                  if ((dose.medicine.dosage ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      dose.medicine.dosage!,
                      style: const TextStyle(color: _grey, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Badge(
                        icon: Icons.restaurant_rounded,
                        label: MedicineMealTiming.label(dose.medicine.mealTimingKey),
                      ),
                      if (debugText != null)
                        _Badge(
                          icon: Icons.alarm_rounded,
                          label: debugText!,
                          foreground: _green,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _CheckCircle(
              checked: taken,
              onTap: () => onToggle(!taken),
            ),
          ],
        ),
      ),
    );
  }
}

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

class _SwipeToDeleteMedicine extends StatelessWidget {
  const _SwipeToDeleteMedicine({
    required super.key,
    required this.medicine,
    required this.onDelete,
    required this.child,
  });

  final Medicine medicine;
  final Future<void> Function() onDelete;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: key!,
      direction: DismissDirection.endToStart,
      background: Container(
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
      confirmDismiss: (_) async => await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: _surface,
              title: const Text('Hapus obat?', style: TextStyle(color: Colors.white)),
              content: Text(
                '${medicine.name} akan dihapus permanen.',
                style: const TextStyle(color: _grey),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _medGradient.last),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Hapus'),
                ),
              ],
            ),
          ) ??
          false,
      onDismissed: (_) => onDelete(),
      child: child,
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: _medGradient),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.checked, required this.onTap});

  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: checked ? _green : Colors.transparent,
          border: Border.all(
            color: checked ? _green : _grey.withValues(alpha: 0.6),
            width: 2,
          ),
        ),
        child: Icon(
          Icons.check_rounded,
          size: 18,
          color: checked ? Colors.white : _grey.withValues(alpha: 0.5),
        ),
      ),
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
              'Tambah jadwal obat dari tombol + agar dosis hari ini langsung muncul di dashboard.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _grey, fontSize: 13, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

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
  const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  final now = DateTime.now();
  return '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}';
}
