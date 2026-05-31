// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Rutin';

  @override
  String get home => 'Beranda';

  @override
  String get medicine => 'Obat';

  @override
  String get water => 'Air';

  @override
  String get habits => 'Kebiasaan';

  @override
  String get taken => 'Sudah diminum';

  @override
  String get snooze => 'Tunda 1 menit';

  @override
  String get missed => 'Terlewat';

  @override
  String streak(int count) {
    return '$count hari berturut-turut';
  }

  @override
  String get addMedicine => 'Tambah Obat';

  @override
  String get addHabit => 'Tambah Kebiasaan';

  @override
  String get dailyGoal => 'Target Harian';

  @override
  String glasses(int count) {
    return '$count gelas';
  }

  @override
  String get settings => 'Pengaturan';

  @override
  String get sleepMode => 'Mode Tidur';

  @override
  String get accessibility => 'Aksesibilitas';

  @override
  String get language => 'BAHASA';

  @override
  String get about => 'TENTANG';

  @override
  String get active => 'Aktif';

  @override
  String get inactive => 'Nonaktif';

  @override
  String get allowed => 'Diizinkan';

  @override
  String get allow => 'Izinkan';

  @override
  String get version => 'Versi';

  @override
  String get builtBy => 'Dibuat oleh';

  @override
  String get freeForever => 'Kesehatan harian, gratis selamanya.';

  @override
  String get medicineToday => 'OBAT HARI INI';

  @override
  String get habitsToday => 'KEBIASAAN HARI INI';

  @override
  String get done => 'Selesai';

  @override
  String get save => 'Simpan';

  @override
  String get cancel => 'Batal';

  @override
  String get delete => 'Hapus';

  @override
  String get edit => 'Edit';

  @override
  String get archive => 'Arsipkan';

  @override
  String get undo => 'Urungkan';

  @override
  String get testSequence => 'Tes Sequence';

  @override
  String get testRhythm => 'Tes Rhythm';

  @override
  String get testDots => 'Tes Dots';

  @override
  String get testSleepGate => 'Tes Gerbang Tidur';

  @override
  String get sleepTime => 'Jam tidur';

  @override
  String get wakeWindowStart => 'Mulai jendela bangun';

  @override
  String get wakeWindowEnd => 'Akhir jendela bangun';

  @override
  String get batteryOptimization => 'Optimasi Baterai';

  @override
  String get allowBackground => 'Izinkan berjalan di latar belakang';

  @override
  String get configure => 'Atur';

  @override
  String get enableMorningGate => 'Aktifkan gerbang bangun pagi';

  @override
  String get mealFree => 'Bebas';

  @override
  String get mealBefore => 'Sebelum makan';

  @override
  String get mealAfter => 'Sesudah makan';

  @override
  String get mealDuring => 'Saat makan';

  @override
  String get waterReminderTitle => 'Waktunya minum air';

  @override
  String get waterReminderBody => 'Sudah minum segelas belum?';

  @override
  String get waterTaken => 'Sudah minum';

  @override
  String get habitReminderChannel => 'Pengingat Kebiasaan';

  @override
  String get habitReminderBody => 'Waktunya melakukan kebiasaanmu!';

  @override
  String get medicineReminderChannel => 'Pengingat Obat';

  @override
  String get medicineReminderDescription => 'Alarm minum obat';

  @override
  String get medicineReminderTitle => 'Waktunya minum obat';

  @override
  String get medicineFallback => 'Obat';

  @override
  String get medicineTaken => 'Sudah diminum';

  @override
  String get medicineRepeat => 'Pengingat berulang sampai dikonfirmasi.';

  @override
  String get sleepActive => 'Mode tidur aktif';

  @override
  String get sleepPaused => 'Mode tidur dijeda 30 menit';

  @override
  String get sleepWaiting => 'Menunggu waktu tidur...';

  @override
  String get stillAwake => 'Saya masih terjaga';

  @override
  String get sleepChannel => 'Mode Tidur';

  @override
  String get sleepChannelDescription => 'Layanan deteksi tidur';
}
