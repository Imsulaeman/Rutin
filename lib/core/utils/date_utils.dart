class AppDateUtils {
  static String toDateString(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String todayString() => toDateString(DateTime.now());

  static int minutesSinceMidnight(DateTime time) =>
      time.hour * 60 + time.minute;

  static DateTime fromMinutesSinceMidnight(int minutes) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, minutes ~/ 60, minutes % 60);
  }
}
