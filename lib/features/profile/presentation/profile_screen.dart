import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../habits/data/habit_repository.dart';
import '../../habits/data/medal_model.dart';
import '../../habits/data/medal_repository.dart';
import '../../tb/data/tb_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _medals = MedalRepository();
  final _habits = HabitRepository();
  List<Medal> _list = [];
  int _bestActiveStreak = 0;
  TBTreatmentProfile? _treatment;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final sorted = _medals.getAll()
      ..sort((a, b) => b.awardedAt.compareTo(a.awardedAt));
    final allHabits = _habits.getAll();
    final best = allHabits.isEmpty
        ? 0
        : allHabits
              .map((h) => _habits.getStreak(h.id))
              .reduce((a, b) => a > b ? a : b);
    setState(() {
      _list = sorted;
      _bestActiveStreak = best;
      _treatment = Hive.box<TBTreatmentProfile>(
        'tb_profiles',
      ).values.where((profile) => profile.isActive).firstOrNull;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildHeader(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.history_rounded,
                    color: AppTheme.habitsColor,
                  ),
                  title: Text(
                    context.l10n.history,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(context.l10n.activityLogAcrossFeatures),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/history'),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.bedtime_rounded,
                    color: Color(0xFF7C3AED),
                  ),
                  title: Text(
                    context.l10n.sleepMode,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    localized(
                      context,
                      id: 'Pengaturan & game bangun pagi',
                      en: 'Settings & morning wake-up games',
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/sleep-settings'),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.health_and_safety_rounded,
                    color: AppTheme.medicineColor,
                  ),
                  title: Text(
                    context.l10n.treatmentProgram,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _treatment == null
                        ? context.l10n.noActiveProgramYet
                        : '${_treatment!.conditionName} - ${context.l10n.programDay(_treatmentDay(_treatment!))}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(
                    _treatment == null
                        ? '/treatment/onboarding'
                        : '/treatment/detail',
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.settings_rounded,
                    color: AppTheme.muted,
                  ),
                  title: Text(
                    context.l10n.settings,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    localized(
                      context,
                      id: 'Bahasa, aksesibilitas, tentang',
                      en: 'Language, accessibility, about',
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/settings'),
                ),
              ),
            ),
          ),
          if (_list.isEmpty)
            _buildEmpty(context)
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList.separated(
                itemCount: _list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _MedalCard(medal: _list[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF0F2027)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Animated flame
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.92, end: 1.06),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeInOut,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              onEnd: () => setState(() {}), // loops by rebuilding
              child: const Text('🔥', style: TextStyle(fontSize: 64)),
            ),
            const SizedBox(height: 12),
            Text(
              '$_bestActiveStreak',
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -2,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              localized(
                context,
                id: 'hari streak terbaik',
                en: 'best streak days',
              ),
              style: TextStyle(fontSize: 15, color: Colors.white60),
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.medals,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(
              localized(
                context,
                id: 'Kebiasaan yang sudah kamu capai',
                en: 'Habits you have achieved',
              ),
              style: TextStyle(fontSize: 13, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏅', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              context.l10n.noMedalsYet,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.retireFirstHabitForMedal,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _MedalCard extends StatelessWidget {
  const _MedalCard({required this.medal});
  final Medal medal;

  @override
  Widget build(BuildContext context) {
    final awarded = medal.awardedAt;
    final dateStr = formatLongDate(context, awarded);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.streakColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(medal.emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medal.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    context.l10n.bestStreakLabel(medal.peakStreak),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.streakColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.earnedOn(dateStr),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int _treatmentDay(TBTreatmentProfile profile) =>
    DateTime.now().difference(profile.startDate).inDays + 1;
