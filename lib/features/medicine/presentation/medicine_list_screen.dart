import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../notifications/alarm_service.dart';
import '../data/medicine_model.dart';
import '../data/medicine_repository.dart';
import '../../../shared/providers/providers.dart';

// ─── Palette (matches preview/03_medicine_list + the dark home) ───────────────
const _navy         = Color(0xFF0B0E1A);
const _surface      = Color(0xFF161D2E);
const _surfaceLine  = Color(0xFF222C42);
const _medGradient  = [Color(0xFFEE5A8C), Color(0xFFD93A6E)];
const _green        = Color(0xFF4CC56A);
const _grey         = Color(0xFF9AA3B2);

const _days   = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

/// One medicine occurrence on the selected day.
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
  DateTime _selected = _dateOnly(DateTime.now());

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _drainPending();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The native alarm screen runs while we're backgrounded; re-sync on return.
    if (state == AppLifecycleState.resumed) _drainPending();
  }

  /// Pulls "taken" taps made on the native reminder screen and records them as
  /// MedicineLogs so the matching dose shows checked.
  Future<void> _drainPending() async {
    final events = await AlarmService.getPendingTaken();
    if (events.isEmpty || !mounted) return;
    final repo = ref.read(medicineRepositoryProvider);
    for (final e in events) {
      final parts = e.split('|');
      if (parts.length != 2) continue;
      final alarmId = int.tryParse(parts[0]);
      final firedMs = int.tryParse(parts[1]);
      if (alarmId == null || firedMs == null) continue;
      final med = _medicineForAlarm(repo, alarmId);
      if (med == null || med.scheduleTimes.isEmpty) continue;
      final fired = DateTime.fromMillisecondsSinceEpoch(firedMs);
      final firedMin = fired.hour * 60 + fired.minute;
      // Match the dose whose scheduled time is closest to when it fired.
      final min = med.scheduleTimes.reduce(
          (a, b) => (a - firedMin).abs() <= (b - firedMin).abs() ? a : b);
      final scheduled =
          DateTime(fired.year, fired.month, fired.day, min ~/ 60, min % 60);
      await repo.setTaken(med.id, scheduled, true);
    }
    if (mounted) setState(() {});
  }

  static Medicine? _medicineForAlarm(MedicineRepository repo, int alarmId) {
    for (final m in repo.getAll()) {
      if ((m.id.hashCode & 0x7fffffff) == alarmId) return m;
    }
    return null;
  }

  bool get _isToday => _selected == _dateOnly(DateTime.now());

  List<_Dose> _dosesFor(MedicineRepository repo) {
    final out = <_Dose>[];
    for (final m in repo.getAll()) {
      for (final t in m.scheduleTimes) {
        out.add(_Dose(
          m,
          t,
          DateTime(_selected.year, _selected.month, _selected.day,
              t ~/ 60, t % 60),
        ));
      }
    }
    out.sort((a, b) => a.minute.compareTo(b.minute));
    return out;
  }

  Future<void> _toggle(MedicineRepository repo, _Dose dose, bool taken) async {
    HapticFeedback.selectionClick();
    await repo.setTaken(dose.medicine.id, dose.scheduled, taken);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(medicineRepositoryProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: _navy,
        body: SafeArea(
          bottom: false,
          child: ValueListenableBuilder<Box<Medicine>>(
            valueListenable: Hive.box<Medicine>('medicines').listenable(),
            builder: (context, _, __) {
              final doses = _dosesFor(repo);
              return Column(
                children: [
                  _header(),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _DateBar(label: _dateLabel(), onTap: _pickDate),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: doses.isEmpty
                        ? _empty()
                        : ListView(
                            padding:
                                const EdgeInsets.fromLTRB(20, 0, 20, 28),
                            children: [
                              for (final d in doses) ...[
                                _DoseCard(
                                  dose: d,
                                  taken: repo.isTaken(d.medicine.id, d.scheduled),
                                  onToggle: (v) => _toggle(repo, d, v),
                                  onLongPress: () => _confirmDelete(repo, d.medicine),
                                ),
                                const SizedBox(height: 12),
                              ],
                              const SizedBox(height: 4),
                              _PastRow(onTap: _comingSoon),
                              const SizedBox(height: 18),
                              const _EncouragementCard(),
                            ],
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 16, 0),
      child: Row(
        children: [
          _Pressable(
            scale: 0.85,
            onTap: () => context.go('/'),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 24),
            ),
          ),
          const Expanded(
            child: Text(
              'Obat',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ),
          _Pressable(
            scale: 0.85,
            onTap: () => context.push('/medicine/add'),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.add_rounded, color: Colors.white, size: 26),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────────
  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _medGradient.first.withOpacity(0.16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.medication_rounded,
                  size: 36, color: Color(0xFFEE5A8C)),
            ),
            const SizedBox(height: 16),
            Text(
              _isToday ? 'Belum ada obat' : 'Tidak ada jadwal',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tambah jadwal minum obat\ndengan tombol + di atas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _grey, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  // ── Date helpers + picker ───────────────────────────────────────────────────
  String _dateLabel() {
    if (_isToday) return 'Hari Ini, ${_selected.day} ${_months[_selected.month - 1]}';
    return '${_days[_selected.weekday % 7]}, ${_selected.day} ${_months[_selected.month - 1]}';
  }

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    final today = _dateOnly(DateTime.now());
    // Past 30 days (review adherence) through the next 7 (plan ahead).
    final dates = [
      for (int i = -30; i <= 7; i++) today.add(Duration(days: i)),
    ];
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Pilih tanggal',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  reverse: true, // start near "today" at the bottom-ish
                  children: [
                    for (final d in dates)
                      _dateTile(sheetCtx, d, d == today, d == _selected),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked != null) setState(() => _selected = picked);
  }

  Widget _dateTile(BuildContext ctx, DateTime d, bool isToday, bool isSel) {
    final label = isToday
        ? 'Hari Ini'
        : '${_days[d.weekday % 7]}, ${d.day} ${_months[d.month - 1]} ${d.year}';
    return ListTile(
      onTap: () => Navigator.pop(ctx, d),
      title: Text(label,
          style: TextStyle(
              color: isSel ? _green : Colors.white,
              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500)),
      trailing: isSel
          ? const Icon(Icons.check_rounded, color: _green, size: 20)
          : null,
    );
  }

  Future<void> _confirmDelete(MedicineRepository repo, Medicine m) async {
    HapticFeedback.mediumImpact();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Hapus obat?', style: TextStyle(color: Colors.white)),
        content: Text('${m.name} akan dihapus permanen.',
            style: const TextStyle(color: _grey)),
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
    );
    if (ok != true) return;
    await AlarmService.cancelAllForAlarm(m.id.hashCode & 0x7fffffff);
    await repo.delete(m.id);
    if (mounted) setState(() {});
  }

  void _comingSoon() {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Riwayat pengingat segera hadir'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _surface,
      ),
    );
  }
}

// ─── Pink day-switcher bar ────────────────────────────────────────────────────
class _DateBar extends StatelessWidget {
  const _DateBar({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF3789F), ..._medGradient],
            stops: [0.0, 0.3, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _medGradient.last.withOpacity(0.45),
              blurRadius: 24,
              spreadRadius: -6,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// ─── A single medicine dose card ──────────────────────────────────────────────
class _DoseCard extends StatelessWidget {
  const _DoseCard({
    required this.dose,
    required this.taken,
    required this.onToggle,
    required this.onLongPress,
  });

  final _Dose dose;
  final bool taken;
  final ValueChanged<bool> onToggle;
  final VoidCallback onLongPress;

  static String _fmt(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _surfaceLine),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pink accent stripe
              Container(width: 5, color: _medGradient.first),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dose.medicine.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                decoration: taken
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: _grey,
                              ),
                            ),
                            if ((dose.medicine.dosage ?? '').isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                dose.medicine.dosage!,
                                style: const TextStyle(
                                    color: _grey, fontSize: 13),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _TimePill(label: _fmt(dose.minute)),
                      const SizedBox(width: 12),
                      _CheckCircle(
                        checked: taken,
                        onTap: () => onToggle(!taken),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
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
    return _Pressable(
      scale: 0.8,
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
            color: checked ? _green : _grey.withOpacity(0.6),
            width: 2,
          ),
        ),
        child: Icon(
          Icons.check_rounded,
          size: 18,
          color: checked ? Colors.white : _grey.withOpacity(0.5),
        ),
      ),
    );
  }
}

// ─── "Past reminders" row ─────────────────────────────────────────────────────
class _PastRow extends StatelessWidget {
  const _PastRow({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _surfaceLine),
        ),
        child: Row(
          children: [
            const Icon(Icons.history_rounded, color: _grey, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Pengingat sebelumnya',
                  style: TextStyle(color: Colors.white, fontSize: 15)),
            ),
            Icon(Icons.chevron_right_rounded,
                color: _grey.withOpacity(0.8), size: 22),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom encouragement card with the pill mascot ──────────────────────────
class _EncouragementCard extends StatelessWidget {
  const _EncouragementCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF3789F), ..._medGradient],
          stops: [0.0, 0.3, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _medGradient.last.withOpacity(0.45),
            blurRadius: 30,
            spreadRadius: -6,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            const SizedBox(width: 8),
            // Mascot peeks from the left; bottom is clipped by the card edge.
            Align(
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                'assets/med_pill_mascot.webp',
                height: 104,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hampir selesai!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Kamu pasti bisa ❤️',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Press-to-scale + haptic wrapper (transform/opacity only) ────────────────
class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, required this.onTap, this.scale = 0.97});
  final Widget child;
  final VoidCallback onTap;
  final double scale;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
