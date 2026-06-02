import 'package:flutter/foundation.dart';

class TutorialTrigger {
  TutorialTrigger._();

  static final _notifier = ValueNotifier<int>(0);

  static void fire() => _notifier.value++;

  static ValueListenable<int> get notifier => _notifier;
}
