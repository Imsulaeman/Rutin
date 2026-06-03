package com.rutin.app

import android.content.Context
import java.util.Locale

object NativeStrings {
    private const val PREFS = "app_settings_native"
    private const val KEY_LANGUAGE = "language"

    fun setLanguage(context: Context, language: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putString(KEY_LANGUAGE, normalize(language)).apply()
    }

    fun language(context: Context): String {
        val saved = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_LANGUAGE, null)
        return saved?.let(::normalize) ?: normalize(Locale.getDefault().language)
    }

    fun text(context: Context, id: String, en: String): String =
        if (language(context) == "id") id else en

    fun medicineFallback(context: Context) = text(context, "Obat", "Medicine")
    fun medicineChannel(context: Context) = text(context, "Pengingat Obat", "Medicine Reminder")
    fun medicineDescription(context: Context) = text(context, "Alarm minum obat", "Medicine alarm")
    fun medicineTitle(context: Context) = text(context, "Waktunya minum obat", "Time to take medicine")
    fun medicineHeading(context: Context) = text(context, "Waktunya minum", "Time to take")
    fun medicineTaken(context: Context) = text(context, "Sudah diminum", "Taken")
    fun medicineSnooze(context: Context) = text(context, "Tunda 1 menit", "Snooze 1 min")
    fun medicineRepeat(context: Context) = text(
        context, "Pengingat berulang sampai dikonfirmasi.", "Repeats until confirmed."
    )
    fun waterChannel(context: Context) = text(context, "Pengingat Air", "Water Reminder")
    fun waterTitle(context: Context) = text(context, "Waktunya minum air", "Time to drink water")
    fun waterBody(context: Context) = text(context, "Sudah minum segelas belum?", "Have you had a glass of water?")
    fun waterTaken(context: Context) = text(context, "Sudah minum", "Drank water")
    fun habitChannel(context: Context) = text(context, "Pengingat Kebiasaan", "Habit Reminder")
    fun habitBody(context: Context) = text(context, "Waktunya melakukan kebiasaanmu!", "Time for your habit!")
    fun sleepActive(context: Context) = text(context, "Mode tidur aktif", "Sleep mode active")
    fun sleepWaiting(context: Context) = text(context, "Memantau jendela tidur...", "Monitoring sleep window...")
    fun sleepChannel(context: Context) = text(context, "Mode Tidur", "Sleep Mode")
    fun sleepDescription(context: Context) = text(context, "Layanan deteksi tidur", "Sleep detection service")

    private fun normalize(language: String): String = if (language == "id") "id" else "en"
}
