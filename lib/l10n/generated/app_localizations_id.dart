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

  @override
  String get saving => 'Menyimpan...';

  @override
  String get create => 'Buat';

  @override
  String get add => 'Tambah';

  @override
  String get enable => 'Aktifkan';

  @override
  String get later => 'Nanti';

  @override
  String get next => 'Lanjut';

  @override
  String get replace => 'Ganti';

  @override
  String get end => 'Akhiri';

  @override
  String get complete => 'Lengkap';

  @override
  String get incomplete => 'Tidak lengkap';

  @override
  String get completed => 'Selesai';

  @override
  String get logged => 'dicatat';

  @override
  String get partial => 'Sebagian';

  @override
  String get offDay => 'Libur';

  @override
  String get startToday => 'Mulai hari ini';

  @override
  String get everyDay => 'Setiap hari';

  @override
  String get notScheduledToday => 'Tidak dijadwalkan hari ini';

  @override
  String get days => 'hari';

  @override
  String get date => 'Tanggal';

  @override
  String get status => 'Status';

  @override
  String get condition => 'Kondisi';

  @override
  String get startDate => 'Tanggal Mulai';

  @override
  String get duration => 'Durasi';

  @override
  String get dosage => 'Dosis';

  @override
  String get medicineName => 'Nama obat';

  @override
  String get name => 'Nama';

  @override
  String get age => 'Usia';

  @override
  String get perfect => 'Sempurna';

  @override
  String get good => 'Bagus';

  @override
  String get miss => 'Meleset';

  @override
  String get noRoutine => 'Tanpa rutinitas';

  @override
  String get newRoutine => 'Rutinitas baru';

  @override
  String get combineIntoRoutine => 'Gabungkan jadi rutinitas';

  @override
  String get deleteRoutine => 'Hapus rutinitas';

  @override
  String get editRoutine => 'Ubah rutinitas';

  @override
  String get editNameAndEmoji => 'Ubah nama & emoji';

  @override
  String get deleteRoutineBody => 'Rutinitas ini akan dihapus.';

  @override
  String get deleteRoutineOnly => 'Hapus rutinitas saja';

  @override
  String get deleteRoutineAndHabits => 'Hapus beserta kebiasaannya';

  @override
  String get editHabit => 'Edit Kebiasaan';

  @override
  String get habitAlreadyCompleted => 'Sudah dilakukan hari ini';

  @override
  String get habitMoveToRoutine => 'Pindahkan ke rutinitas';

  @override
  String get habitTurnIntoMedal => 'Jadikan medali';

  @override
  String get moveTo => 'Pindahkan ke';

  @override
  String get retireHabitDescription =>
      'Kebiasaan ini akan dihapus dari daftar aktif dan disimpan sebagai medali.';

  @override
  String get retireHabitButton => '🏅  Jadikan Medali';

  @override
  String get habitsEmptyHint =>
      'Tap + untuk menambah kebiasaan, lalu buat rutinitas dari tab Semua.';

  @override
  String get groupEmptyHint =>
      'Belum ada kebiasaan di sini.\nTap + atau gunakan \"Pindahkan ke rutinitas\" dari Semua.';

  @override
  String get allDone => 'Semua selesai! 🎉';

  @override
  String get doneToday => 'Selesai hari ini';

  @override
  String get combine => 'Gabungkan';

  @override
  String get createRoutineHint => 'Buat rutinitas dulu dari tab Kebiasaan';

  @override
  String get enableReminder => 'Aktifkan pengingat';

  @override
  String get addTime => 'Tambah waktu';

  @override
  String get reminderTime => 'Waktu pengingat';

  @override
  String get chooseEmoji => 'Pilih emoji';

  @override
  String get emojiCategoryActivity => 'Aktivitas';

  @override
  String get emojiCategoryMorningNight => 'Pagi & Malam';

  @override
  String get emojiCategoryFoodDrink => 'Makan & Minum';

  @override
  String get emojiCategoryStudyWork => 'Belajar & Kerja';

  @override
  String get emojiCategoryHealth => 'Kesehatan';

  @override
  String get emojiCategoryGeneral => 'Umum';

  @override
  String get habitHistory => 'Riwayat Kebiasaan';

  @override
  String get noHabitsScheduled => 'Tidak ada kebiasaan terjadwal.';

  @override
  String get noHabitsYetShort => 'Belum ada kebiasaan.';

  @override
  String get medicineHistory => 'Riwayat Obat';

  @override
  String get allTaken => 'Semua diminum';

  @override
  String get noSchedule => 'Belum ada jadwal';

  @override
  String get reviewDoses =>
      'Lihat dosis yang diminum, terlewat, atau belum jatuh tempo.';

  @override
  String get noMedicineForDay => 'Tidak ada jadwal obat di hari ini.';

  @override
  String get notDueYet => 'Belum waktunya';

  @override
  String get noLogYet => 'Belum ada log';

  @override
  String get noDoseSchedule => 'Belum ada jadwal dosis';

  @override
  String get deleteMedicineTitle => 'Hapus obat?';

  @override
  String get noMedicineToday => 'Belum ada obat hari ini';

  @override
  String get habitCompletedLog => 'Kebiasaan selesai';

  @override
  String get recentActivityForDay => 'Aktivitas terbaru untuk tanggal ini.';

  @override
  String get nothingLoggedToday => 'Tidak ada aktivitas pada hari ini.';

  @override
  String get scheduleTimes => 'WAKTU MINUM';

  @override
  String get mealRule => 'ATURAN MAKAN';

  @override
  String get medicineNameRequired => 'Nama obat wajib diisi';

  @override
  String get dosageHint => 'Contoh: 1 tablet';

  @override
  String get enableAndStart => 'Aktifkan & Mulai';

  @override
  String get onboarding1Headline => 'Susah konsisten?\nKamu tidak sendirian.';

  @override
  String get onboarding1Body =>
      'Minum obat, minum air, olahraga — kebiasaan kecil yang mudah terlupakan tapi penting untuk kesehatanmu.';

  @override
  String get onboarding2Headline => 'Rutin jaga semua\nrutinitasmu.';

  @override
  String get onboarding2Body =>
      'Pengingat obat, kebiasaan harian, air minum, dan game bangun pagi — gratis, offline, selamanya.';

  @override
  String get onboarding3Headline => 'Satu langkah\nterakhir.';

  @override
  String get onboarding3Body =>
      'Rutin perlu izin notifikasi agar pengingat bisa jalan saat kamu tidak buka aplikasi.';

  @override
  String get tapToSetName => 'Ketuk untuk isi nama';

  @override
  String get bestStreak => 'Streak terbaik';

  @override
  String get habitsDone => 'Habit selesai';

  @override
  String get habitsAchieved => 'Kebiasaan yang sudah kamu capai';

  @override
  String get chooseCharacter => 'Pilih karaktermu';

  @override
  String get sleepModeSubtitle => 'Pengaturan dan game bangun pagi';

  @override
  String get settingsSubtitle => 'Bahasa, aksesibilitas, tentang';

  @override
  String get accessibilityNotAllowed =>
      'Belum diizinkan, diperlukan untuk Mode Tidur';

  @override
  String get medicineAlarmSection => 'ALARM OBAT';

  @override
  String get fullScreenAlarm => 'Alarm layar penuh';

  @override
  String get fullScreenAlarmAllowed =>
      'Diizinkan, alarm bisa mengambil alih layar';

  @override
  String get fullScreenAlarmNotAllowed =>
      'Belum diizinkan, alarm bisa turun jadi heads-up saja';

  @override
  String get soundSection => 'SUARA';

  @override
  String get appSound => 'Suara aplikasi';

  @override
  String get appSoundSubtitle => 'Pakai suara bawaan Rutin';

  @override
  String get phoneDefaultSound => 'Suara bawaan ponsel';

  @override
  String get phoneDefaultSoundSubtitle =>
      'Pakai notifikasi atau ringtone default ponsel';

  @override
  String get notificationSound => 'Suara notifikasi';

  @override
  String get notificationSoundSubtitle =>
      'Dipakai untuk pengingat Air dan Kebiasaan';

  @override
  String get medicineAlarmSound => 'Suara alarm obat';

  @override
  String get medicineAlarmSoundSubtitle =>
      'Dipakai untuk alarm obat layar penuh';

  @override
  String get otherSection => 'LAINNYA';

  @override
  String get tutorial => 'Tutorial';

  @override
  String get tutorialSubtitle => 'Lihat ulang layar pengenalan';

  @override
  String get dataSection => 'DATA';

  @override
  String get exportBackup => 'Ekspor backup (JSON)';

  @override
  String get exportBackupSubtitle => 'Semua obat, kebiasaan, air, dan log';

  @override
  String get skipGateTitle => 'Lewati gerbang?';

  @override
  String get skipGateBody =>
      'Game pagi ini akan dilewati. Streak kamu tetap aman.';

  @override
  String get streakFirstDay => 'Hari pertama!';

  @override
  String get noHabitsToday => 'Tidak ada kebiasaan hari ini';

  @override
  String get sleepModeStartError =>
      'Mode tidur belum dapat dijalankan. Coba aktifkan kembali setelah memperbarui aplikasi.';

  @override
  String get allowBackgroundTitle => 'Izinkan Berjalan di Latar';

  @override
  String get allowBackgroundBody =>
      'Rutin perlu diizinkan berjalan di latar agar alarm obat, pengingat air, dan Mode Tidur tetap muncul tepat waktu.\n\nSetelah halaman Pengaturan Aplikasi Rutin terbuka, masuk ke Baterai lalu matikan optimasi baterai atau izinkan aktivitas latar belakang.';

  @override
  String get enableAccessibilityHint =>
      'Untuk pengalaman terbaik, aktifkan Accessibility Service.';

  @override
  String get accessibilityService => 'Accessibility Service';

  @override
  String get notAllowedYet => 'Belum diizinkan';

  @override
  String get backgroundAllowed => 'Sudah diizinkan berjalan di latar belakang';

  @override
  String get backgroundNotConfirmed =>
      'Belum terkonfirmasi. Di beberapa HP, status ini bisa tetap tidak berubah walaupun izin latar belakang sudah diaktifkan.';

  @override
  String get sleepTriggerSimulated =>
      'Gerbang pagi seharusnya muncul sekarang. Jika tidak, cek apakah Mode Tidur aktif.';

  @override
  String get skipArrow => 'Lewati →';

  @override
  String get watchClosely => 'Perhatikan...';

  @override
  String get tapTheSequence => 'Ketuk urutannya!';

  @override
  String get wrongRepeatRound => 'Salah! Ulangi putaran...';

  @override
  String get connectTheColors => 'Hubungkan Warnanya';

  @override
  String get gameComplete => 'Game selesai. Selamat beraktivitas!';

  @override
  String get noActiveProgramDot => 'Tidak ada program aktif.';

  @override
  String get exportPdf => 'Ekspor PDF';

  @override
  String get endProgram => 'Akhiri program';

  @override
  String get endProgramTitle => 'Akhiri program?';

  @override
  String get endProgramBody => 'Program aktif akan dihentikan.';

  @override
  String get pdfTitle => 'Rutin - Laporan Kepatuhan Pengobatan';

  @override
  String get startDateLabel => 'Tanggal mulai';

  @override
  String get conditionName => 'Nama kondisi';

  @override
  String get treatmentDuration => 'Durasi pengobatan';

  @override
  String get other => 'Lainnya';

  @override
  String get numberOfDays => 'Jumlah hari';

  @override
  String get linkedMedicine => 'Obat yang digunakan (opsional)';

  @override
  String get noLinkedMedicine => 'Tanpa obat terhubung';

  @override
  String get treatmentValidationError =>
      'Isi nama kondisi dan durasi yang valid.';

  @override
  String get replaceActiveProgram => 'Ganti program aktif?';

  @override
  String get replaceProgramBody => 'Program sebelumnya akan dihentikan.';

  @override
  String get waterSettings => 'Pengaturan Air';

  @override
  String get waterGoalReached => 'Target tercapai! Mantap!';

  @override
  String get remindersStart => 'Pengingat mulai';

  @override
  String get remindersFinished => 'Pengingat selesai hari ini';

  @override
  String get comingSoon => 'Sebentar lagi...';

  @override
  String get glassSize => 'Ukuran gelas';

  @override
  String get start => 'Mulai';

  @override
  String get reminder => 'Pengingat';

  @override
  String get scheduledDoses => 'Dosis Terjadwal';

  @override
  String get takenDoses => 'Dosis Diminum';

  @override
  String get exportedFrom => 'Diekspor dari Rutin';

  @override
  String failedToSave(Object error) {
    return 'Gagal menyimpan: $error';
  }

  @override
  String failedToScheduleAlarm(Object error) {
    return 'Gagal menjadwalkan alarm: $error';
  }

  @override
  String exportBackupFailed(Object error) {
    return 'Gagal mengekspor backup: $error';
  }

  @override
  String get deleteHabitTitle => 'Hapus kebiasaan?';

  @override
  String deleteHabitBody(Object name) {
    return '$name akan dihapus permanen.';
  }

  @override
  String deleteRoutineTitle(Object name) {
    return 'Hapus \"$name\"?';
  }

  @override
  String deleteRoutineWithHabitsBody(int count) {
    return 'Rutinitas ini punya $count kebiasaan. Mau diapakan?';
  }

  @override
  String habitsCompletedCount(int completed, int total) {
    return '$completed dari $total kebiasaan selesai';
  }

  @override
  String habitTurnedIntoMedal(Object emoji, Object name) {
    return '$emoji $name dijadikan medali!';
  }

  @override
  String tookMedicine(Object name) {
    return 'Minum $name';
  }

  @override
  String drankWaterMl(int ml) {
    return 'Minum $ml ml air';
  }

  @override
  String ageYearsOld(int age) {
    return '$age tahun';
  }

  @override
  String medicineDueNow(int count) {
    return '$count perlu diminum';
  }

  @override
  String medicineMissedCount(int count) {
    return '$count terlewat';
  }

  @override
  String medicineDoneProgress(int taken, int total) {
    return '$taken/$total selesai';
  }

  @override
  String get noMedicineTodayHint =>
      'Tambah jadwal obat dari tombol + agar dosis hari ini langsung muncul di sini.';

  @override
  String streakDay(int streak) {
    return 'Hari ke-$streak';
  }

  @override
  String daysRemaining(int count) {
    return '$count hari tersisa';
  }

  @override
  String adherenceLabel(int pct) {
    return 'Kepatuhan: $pct%';
  }

  @override
  String last7Days(int taken, int total) {
    return '7 hari terakhir: $taken/$total dosis';
  }

  @override
  String months(Object count) {
    return '$count bulan';
  }

  @override
  String gameRoundInfo(int round, int colors) {
    return 'Putaran $round/3  •  $colors warna';
  }

  @override
  String reminderInMinutes(int minutes) {
    return 'Pengingat dalam $minutes menit';
  }

  @override
  String reminderInHours(int hours) {
    return 'Pengingat dalam ${hours}j';
  }

  @override
  String reminderInHoursMinutes(int hours, int minutes) {
    return 'Pengingat dalam ${hours}j ${minutes}m';
  }

  @override
  String waterGlassesSummary(int glasses, int minutes) {
    return '$glasses gelas/hari - pengingat setiap $minutes menit';
  }

  @override
  String ofGoalGlasses(int goal) {
    return 'dari $goal gelas';
  }

  @override
  String get medalWaterTitle => 'Asupan Air';

  @override
  String get medalMedicineTitle => 'Streak Obat';

  @override
  String get medalHabitTitle => 'Streak Kebiasaan';

  @override
  String get medalPersonalBest => 'Rekor terbaik';

  @override
  String get medalStartStreak => 'Mulai streakmu';

  @override
  String get medalNoBestYet => 'Belum ada rekor';

  @override
  String get medalWaterDesc => 'Hari berurutan memenuhi target minum harian.';

  @override
  String get medalMedicineDesc => 'Berdasarkan streak minum obat terbaik.';

  @override
  String get medalHabitDesc => 'Berdasarkan streak kebiasaan terbaik.';

  @override
  String medalCurrentCount(int count) {
    return '↑ $count hari';
  }

  @override
  String medalBestAchieved(Object date) {
    return 'Terbaik: $date';
  }
}
