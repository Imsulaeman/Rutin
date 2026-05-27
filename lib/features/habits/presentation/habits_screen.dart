import 'package:flutter/material.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kebiasaan')),
      body: const Center(child: Text('Daftar kebiasaan harian.')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: navigate to add habit screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
