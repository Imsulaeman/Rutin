import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../habits/data/medal_model.dart';
import '../../habits/data/medal_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _medals = MedalRepository();
  List<Medal> _list = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final sorted = _medals.getAll()
      ..sort((a, b) => b.awardedAt.compareTo(a.awardedAt));
    setState(() => _list = sorted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildHeader(context),
          if (_list.isEmpty)
            _buildEmpty(context)
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList.separated(
                itemCount: _list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
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
            colors: [AppTheme.streakColor, Color(0xFFFF9800)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🏅',
              style: TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 12),
            Text(
              'Medali',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Kebiasaan yang sudah kamu capai',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
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
              'Belum ada medali',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Pensiun kebiasaan pertamamu\nuntuk mendapatkan medali pertama.',
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
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final dateStr =
        '${awarded.day} ${months[awarded.month - 1]} ${awarded.year}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.streakColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  medal.emoji,
                  style: const TextStyle(fontSize: 26),
                ),
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
                    '🔥 Streak terbaik: ${medal.peakStreak} hari',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.streakColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Dicapai $dateStr',
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
