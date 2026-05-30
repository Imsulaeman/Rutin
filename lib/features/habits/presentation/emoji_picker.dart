import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

const _categories = [
  (
    'Aktivitas',
    ['🏃','💪','🧘','🏋️','🚶','🤸','🏊','🚴','⚽','🏀','🎾','🥊','🧗','🤾','🏄'],
  ),
  (
    'Pagi & Malam',
    ['☀️','🌙','🌅','🌄','😴','⏰','🛁','🚿','🪥','🧴','🪞','👕','🛏️','💤','🌛'],
  ),
  (
    'Makan & Minum',
    ['🍽️','☕','🥗','🍎','🥛','🍵','🧃','🥦','🍌','🥝','🫐','🥤','🍳','🥚','🍱'],
  ),
  (
    'Belajar & Kerja',
    ['📚','✏️','💡','🎯','📝','🖊️','🎓','📖','🧠','🔬','💻','📊','🗒️','📐','🔭'],
  ),
  (
    'Kesehatan',
    ['❤️','💊','🩺','🌡️','🩹','💉','🧬','🫀','🦷','👁️','🧘','🩻','💆','🏥','🫁'],
  ),
  (
    'Umum',
    ['✅','🔔','🏆','🎉','🌈','🔥','💫','⭐','🌟','✨','🎵','🎸','🎨','🌿','🪴'],
  ),
];

// Flat list for any code that still needs it
const kEmojiList = [
  '✅','💪','🧘','🏃','🚶','🏋️','🤸','🏊','⚽','🚴',
  '☀️','🌙','⭐','😴','🛁','🚿','🪥','🧴','⏰','🌅',
  '🍽️','🥤','☕','🥗','🍎','🥛','🍵','🧃','🍌','🥦',
  '📚','✏️','💡','🎯','📝','🖊️','🎓','📖','🧠','🔬',
  '❤️','💊','🩺','🌡️','🩹','💉','🧬','🫀','🦷','👁️',
  '🌿','🌱','🎵','🏆','📋','🔔','🎉','🌈','🔥','💫',
];

Future<String?> showEmojiPicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _EmojiPickerSheet(),
  );
}

class _EmojiPickerSheet extends StatefulWidget {
  @override
  State<_EmojiPickerSheet> createState() => _EmojiPickerSheetState();
}

class _EmojiPickerSheetState extends State<_EmojiPickerSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Pilih emoji',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          const SizedBox(height: 8),
          // Category tabs
          TabBar(
            controller: _tab,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: AppTheme.border,
            indicatorColor: AppTheme.habitsColor,
            labelColor: AppTheme.habitsColor,
            unselectedLabelColor: AppTheme.muted,
            labelStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600),
            tabs: [
              for (final cat in _categories) Tab(text: cat.$1),
            ],
          ),
          // Emoji grid per category
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                for (final cat in _categories)
                  GridView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: cat.$2.length,
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => Navigator.pop(context, cat.$2[i]),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceHigh,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(cat.$2[i],
                              style: const TextStyle(fontSize: 24)),
                        ),
                      ),
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
