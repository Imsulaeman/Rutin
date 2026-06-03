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
  String get waterToday => 'AIR HARI INI';

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

  @override
  String get history => 'Riwayat';

  @override
  String get activityLogAcrossFeatures => 'Log aktivitas dari semua fitur';

  @override
  String get treatmentProgram => 'Program Pengobatan';

  @override
  String get noActiveProgramYet => 'Belum ada program aktif';

  @override
  String programDay(int count) {
    return 'hari ke-$count';
  }

  @override
  String get routineName => 'Nama rutinitas';

  @override
  String get habitName => 'Nama kebiasaan';

  @override
  String get routineLabel => 'RUTINITAS';

  @override
  String get scheduleLabel => 'JADWAL';

  @override
  String get reminderLabel => 'PENGINGAT';

  @override
  String get noHabitsYet => 'Belum ada kebiasaan';

  @override
  String get noMedicineScheduledToday => 'Belum ada jadwal obat hari ini.';

  @override
  String get noHabitsScheduledToday =>
      'Belum ada kebiasaan terjadwal hari ini.';

  @override
  String get waterProgressToday => 'Progress air hari ini';

  @override
  String get homePullDownHint =>
      'Tarik ke bawah, nikmati suasananya.\nScroll sedikit, lihat hari ini.';

  @override
  String get waterMascotNudge => 'Tetap semangat! Kamu hebat.';

  @override
  String waterOfMl(Object value) {
    return 'dari $value ml';
  }

  @override
  String waterAmountAdded(int value) {
    return '+$value ml ditambahkan';
  }

  @override
  String get waterWhoGuidance =>
      'WHO merekomendasikan 2.0L (wanita) - 2.5L (pria) per hari. Di iklim panas seperti Indonesia, tambahkan 0.5-1.0L.';

  @override
  String waterReminderRange(int minutes) {
    return 'Setiap $minutes menit dalam rentang aktif';
  }

  @override
  String get archiveMedicineTitle => 'Arsipkan obat?';

  @override
  String archiveMedicineBody(Object name) {
    return '$name disembunyikan dari daftar hari ini. Riwayat tetap tersimpan.';
  }

  @override
  String deleteMedicineBody(Object name) {
    return '$name akan dihapus permanen beserta riwayatnya.';
  }

  @override
  String nextDose(Object dayLabel, Object time) {
    return 'Berikutnya $dayLabel $time';
  }

  @override
  String get bestStreakDays => 'hari streak terbaik';

  @override
  String get smallStepsBigChange =>
      'Langkah kecil setiap hari\nmembawa perubahan besar ✨';

  @override
  String streakDaysRow(int count) {
    return '$count hari berturut-turut';
  }

  @override
  String get noStreakYet => 'Belum ada streak';

  @override
  String get medals => 'Medali';

  @override
  String get noMedalsYet => 'Belum ada medali';

  @override
  String get retireFirstHabitForMedal =>
      'Pensiun kebiasaan pertamamu\nuntuk mendapatkan medali pertama.';

  @override
  String bestStreakLabel(int count) {
    return '🔥 Streak terbaik: $count hari';
  }

  @override
  String earnedOn(Object date) {
    return 'Dicapai $date';
  }

  @override
  String get all => 'Semua';

  @override
  String get greetingMorning => 'Selamat pagi';

  @override
  String get greetingAfternoon => 'Selamat siang';

  @override
  String get greetingEvening => 'Selamat sore';

  @override
  String get greetingNight => 'Selamat malam';

  @override
  String get tutorialSkip => 'LEWATI';

  @override
  String get tutorialHintContinue => 'Ketuk di mana saja untuk lanjut';

  @override
  String get tutorialHintFinish => 'Ketuk di mana saja untuk selesai';

  @override
  String get tutorialWelcomeTitle => 'Selamat datang di Rutin!';

  @override
  String get tutorialWelcomeBody =>
      'Dashboard harian kamu - semua ada di sini. Ketuk di mana saja untuk lanjut.';

  @override
  String get tutorialAddButtonTitle => 'Tombol +';

  @override
  String get tutorialAddButtonBody =>
      'Tambah obat atau kebiasaan baru dari sini.';

  @override
  String get tutorialMedicineBody =>
      'Jadwal obat lengkap dan pencatatan dosis harian.';

  @override
  String get tutorialWaterBody =>
      'Catat asupan air dan aktifkan pengingat minum.';

  @override
  String get tutorialHabitsBody =>
      'Buat dan centang kebiasaan harian. Bangun streak dan raih medali.';

  @override
  String homeHiddenHabitsMore(int count) {
    return '+ $count lainnya';
  }

  @override
  String homeHabitsDoneSummary(int done, int due) {
    return '$done / $due selesai';
  }

  @override
  String get permissionNotificationsTitle => 'Izinkan Notifikasi';

  @override
  String get permissionNotificationsBody =>
      'Diperlukan agar pengingat obat dan air muncul di layar.';

  @override
  String get permissionExactAlarmTitle => 'Izinkan Exact Alarm';

  @override
  String get permissionExactAlarmBody =>
      'Agar pengingat muncul tepat waktu - buka Alarm & Pengingat lalu aktifkan Rutin.';

  @override
  String get permissionFullScreenTitle => 'Izinkan Layar Penuh';

  @override
  String get permissionFullScreenBody =>
      'Pengingat obat bisa muncul menyeluruh saat perangkat terkunci.';

  @override
  String get skip => 'Lewati';

  @override
  String get treatmentProgramComplete => 'Program selesai';

  @override
  String treatmentDaysRemaining(int day, int left) {
    return 'Hari ke-$day - $left hari tersisa';
  }
}
