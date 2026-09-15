package com.example.vtm_tablet

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInstaller
import android.os.Build
import android.util.Log
import java.io.File

/**
 * Kiosk icinde uygulama guncellemesi.
 *
 * Kilit gorevi acikken sistemin kurulum ekrani (package installer) ONE
 * GELEMEZ; eski "APK'yi ac, kullanici Kur desin" yontemi kiosk modunda
 * calismaz. Cihaz sahibi oldugumuz icin PackageInstaller ile SESSIZ kurulum
 * yapabiliyoruz: kullaniciya hicbir sey sorulmaz, uygulama yerinde guncellenir.
 */
object KioskInstaller {

    const val TAG = "KioskInstall"
    const val ACTION_INSTALL_STATUS = "com.example.vtm_tablet.KIOSK_INSTALL_STATUS"

    fun install(context: Context, apkPath: String): Boolean {
        val file = File(apkPath)
        if (!file.exists()) {
            Log.e(TAG, "APK bulunamadi: " + apkPath)
            return false
        }

        return try {
            val installer = context.packageManager.packageInstaller
            val params = PackageInstaller.SessionParams(
                PackageInstaller.SessionParams.MODE_FULL_INSTALL
            )
            val sessionId = installer.createSession(params)

            installer.openSession(sessionId).use { session ->
                session.openWrite("kiosk_update", 0, file.length()).use { out ->
                    file.inputStream().use { input -> input.copyTo(out) }
                    session.fsync(out)
                }

                var flags = PendingIntent.FLAG_UPDATE_CURRENT
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    flags = flags or PendingIntent.FLAG_MUTABLE
                }
                val intent = Intent(ACTION_INSTALL_STATUS).setPackage(context.packageName)
                val pending = PendingIntent.getBroadcast(context, sessionId, intent, flags)
                session.commit(pending.intentSender)
            }
            Log.i(TAG, "Sessiz kurulum baslatildi, oturum " + sessionId)
            true
        } catch (e: Exception) {
            Log.e(TAG, "Sessiz kurulum basarisiz", e)
            false
        }
    }
}

/** Sessiz kurulumun sonucunu loglar; cihaz sahibiyken onay ekrani beklenmez. */
class KioskInstallReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != KioskInstaller.ACTION_INSTALL_STATUS) return

        when (val status = intent.getIntExtra(PackageInstaller.EXTRA_STATUS, -1)) {
            PackageInstaller.STATUS_SUCCESS ->
                Log.i(KioskInstaller.TAG, "Guncelleme kuruldu")

            PackageInstaller.STATUS_PENDING_USER_ACTION -> {
                // Cihaz sahipligi yoksa sistem onay ister. Kiosk disinda bu ekran
                // acilabilir; kiosk icinde zaten sessiz kurulum calisir.
                Log.w(KioskInstaller.TAG, "Kurulum kullanici onayi bekliyor")
                @Suppress("DEPRECATION")
                val confirm = intent.getParcelableExtra<Intent>(Intent.EXTRA_INTENT)
                confirm?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                confirm?.let { runCatching { context.startActivity(it) } }
            }

            else -> Log.e(
                KioskInstaller.TAG,
                "Kurulum basarisiz (" + status + "): " +
                    intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE)
            )
        }
    }
}
