package com.example.vtm_tablet

import android.app.admin.DeviceAdminReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Cihaz sahibi (device owner) bilesenidir.
 *
 * Kurulum scripti bu sinifi su komutla atar:
 *   adb shell dpm set-device-owner com.mta.sondaj_takip/com.example.vtm_tablet.KioskDeviceAdminReceiver
 *
 * DIKKAT: Sinifin adi veya paketi degisirse kurulum scriptindeki DEVICE_ADMIN
 * degeri de ayni anda degismelidir; aksi halde sahiplik atanamaz.
 */
class KioskDeviceAdminReceiver : DeviceAdminReceiver() {

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Log.i(TAG, "Cihaz yoneticisi etkinlestirildi")
        // Sahiplik atanir atanmaz tum kiosk politikasi yazilir; kullanicinin
        // uygulamayi acmasini beklemeye gerek yoktur.
        KioskPolicy.applyKiosk(context)
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Log.w(TAG, "Cihaz yoneticisi devre disi birakildi")
    }

    /** Kilit gorevi (lock task) bu paket icin baslatildiginda bilgi amacli loglanir. */
    override fun onLockTaskModeEntering(context: Context, intent: Intent, pkg: String) {
        super.onLockTaskModeEntering(context, intent, pkg)
        Log.i(TAG, "Kilit gorevi baslatildi: $pkg")
    }

    override fun onLockTaskModeExiting(context: Context, intent: Intent) {
        super.onLockTaskModeExiting(context, intent)
        Log.w(TAG, "Kilit gorevinden cikildi")
    }

    companion object {
        const val TAG = "KioskAdmin"

        fun componentName(context: Context): ComponentName =
            ComponentName(context.applicationContext, KioskDeviceAdminReceiver::class.java)
    }
}
