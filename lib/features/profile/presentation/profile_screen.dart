import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../habits/data/habit_model.dart';
import '../../habits/data/habit_repository.dart';
import '../../habits/data/medal_model.dart';
import '../../habits/data/medal_repository.dart';
import '../data/user_profile_model.dart';
import '../../tb/data/tb_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _profileKey = 'primary';

  final _medals = MedalRepository();
  final _habits = HabitRepository();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();

  late final Box<UserProfile> _profileBox;
  List<Medal> _list = [];
  int _bestActiveStreak = 0;
  int _habitsDoneTotal = 0;
  int _editAvatarId = 0;
  UserProfile? _profile;
  TBTreatmentProfile? _treatment;

  @override
  void initState() {
    super.initState();
    _profileBox = Hive.box<UserProfile>('user_profile');
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  void _load() {
    final sorted = _medals.getAll()
      ..sort((a, b) => b.awardedAt.compareTo(a.awardedAt));
    final allHabits = _habits.getAll();
    final best = allHabits.isEmpty
        ? 0
        : allHabits
              .map((habit) => _habits.getStreak(habit.id))
              .reduce((a, b) => a > b ? a : b);

    setState(() {
      _list = sorted;
      _bestActiveStreak = best;
      _habitsDoneTotal = Hive.box<HabitLog>('habit_logs').length;
      _profile = _profileBox.get(_profileKey);
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
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(context.l10n.sleepModeSubtitle),
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
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(context.l10n.settingsSubtitle),
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
                itemBuilder: (context, index) =>
                    _MedalCard(medal: _list[index]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final profile = _profile;
    final hasName = profile?.name.trim().isNotEmpty == true;
    final hasAge = (profile?.age ?? 0) > 0;

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
            GestureDetector(
              onTap: _openEditSheet,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          AppTheme.habitsColor,
                          AppTheme.medicineColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.medicineColor.withValues(alpha: 0.24),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Color(0xFF101826),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: profile == null
                            ? const Icon(
                                Icons.person_rounded,
                                size: 40,
                                color: Colors.white54,
                              )
                            : Image.asset(
                                _avatarAsset(profile.avatarId),
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 2,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2027),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (hasName)
              Text(
                profile!.name.trim(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              )
            else
              GestureDetector(
                onTap: _openEditSheet,
                child: Text(
                  context.l10n.tapToSetName,
                  style: const TextStyle(fontSize: 15, color: Colors.white38),
                ),
              ),
            if (hasAge) ...[
              const SizedBox(height: 4),
              Text(
                context.l10n.ageYearsOld(profile!.age),
                style: const TextStyle(fontSize: 13, color: Colors.white54),
              ),
            ],
            const SizedBox(height: 24),
            const Icon(
              Icons.local_fire_department_rounded,
              size: 52,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
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
              context.l10n.bestStreakDays,
              style: const TextStyle(fontSize: 15, color: Colors.white60),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatChip(
                  icon: Icons.local_fire_department_rounded,
                  value: '$_bestActiveStreak',
                  label: context.l10n.bestStreak,
                ),
                _StatChip(
                  icon: Icons.workspace_premium_rounded,
                  value: '${_list.length}',
                  label: context.l10n.medals,
                ),
                _StatChip(
                  icon: Icons.check_circle_rounded,
                  value: '$_habitsDoneTotal',
                  label: context.l10n.habitsDone,
                ),
              ],
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
              context.l10n.habitsAchieved,
              style: const TextStyle(fontSize: 13, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditSheet() async {
    final profile = _profile ?? UserProfile();
    _nameCtrl.text = profile.name;
    _ageCtrl.text = profile.age > 0 ? '${profile.age}' : '';
    _editAvatarId = profile.avatarId;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.chooseCharacter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                  itemCount: 10,
                  itemBuilder: (_, index) => GestureDetector(
                    onTap: () => setSheetState(() => _editAvatarId = index),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _editAvatarId == index
                              ? const Color(0xFFF4A92B)
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          _avatarAsset(index),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameCtrl,
                  maxLength: 30,
                  style: const TextStyle(color: Colors.white),
                  decoration: _sheetInputDecoration(context.l10n.name),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ageCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: Colors.white),
                  decoration: _sheetInputDecoration(context.l10n.age),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF4A92B),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      final next = UserProfile()
                        ..name = _nameCtrl.text.trim()
                        ..age = int.tryParse(_ageCtrl.text) ?? 0
                        ..avatarId = _editAvatarId;
                      await _profileBox.put(_profileKey, next);
                      if (!mounted) return;
                      setState(() => _profile = next);
                      if (!sheetContext.mounted) return;
                      Navigator.of(sheetContext).pop();
                    },
                    child: Text(context.l10n.save),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _sheetInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF9AA3B2)),
      counterStyle: const TextStyle(color: Color(0xFF9AA3B2)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF26324A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF4A92B)),
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
            const Icon(
              Icons.workspace_premium_rounded,
              size: 56,
              color: AppTheme.streakColor,
            ),
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

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xCC111A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF26324A)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFF4A92B)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9AA3B2)),
          ),
        ],
      ),
    );
  }
}

int _treatmentDay(TBTreatmentProfile profile) =>
    DateTime.now().difference(profile.startDate).inDays + 1;

String _avatarAsset(int avatarId) => 'assets/avatar/avatar_$avatarId.png';
