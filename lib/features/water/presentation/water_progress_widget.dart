import 'package:flutter/material.dart';

class WaterProgressWidget extends StatelessWidget {
  const WaterProgressWidget({
    super.key,
    required this.current,
    required this.goal,
  });

  final int current;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final progress = (current / goal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$current / $goal gelas'),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: progress),
      ],
    );
  }
}
