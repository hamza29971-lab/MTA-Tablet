package com.example.vtm_tablet

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Tablet acilinca (ve uygulama guncellenince) kiosk'u geri getirir.
 *
 * Bu IKINCI guvenlik hattidir. Birincisi, uygulamanin kalici ANA EKRAN
 * olmasidir (KioskPolicy.setAsPersistentHome + KioskHomeAlias): Android her
 * acilista ANA EKRANI kendisi baslattigi icin tablet acilir acilmaz
 * KioskBootstrapActivity gelir. Android 10 ve sonrasinda arka plandan activity
 * baslatmak kisitlidir; asagidaki startActivity cagrisi sessizce engellenebilir
 * ama ana ekran yolu her zaman calisir. Ikisi birden bulundurulmasinin sebebi
 * budur.
 *
 * Dinlenen yayinlar:
 *   BOOT_COMPLETED           - normal acilis
 *   QUICKBOOT_POWERON        - bazi ureticilerin hizli acilisinda
 *                              BOOT_COMPLETED yerine bu gonderilir
 *   MY_PACKAGE_REPLACED      - OTA ile sessiz guncelleme sonrasi surec
 *                              oldurulur; uygulama hemen geri gelsin
 *
 * MainActivity DEGIL, bootstrap baslatilir: kilitli acilisi yapan odur.
 */
class BootCompletedReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action !in HANDLED_ACTIONS) return

        Log.i(TAG, "Kiosk yeniden baslatiliyor, sebep: " + action)

        // Politika once yazilir: acilista lock task izin listesi, ana ekran
        // atamasi ve kisitlar yerinde olsun.
        KioskPolicy.applyKiosk(context)

        val bootstrap = Intent(context, KioskBootstrapActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        runCatching { context.startActivity(bootstrap) }
            .onFailure { Log.w(TAG, "Arka plandan baslatilamadi; ana ekran yolu devrede", it) }
    }

    companion object {
        const val TAG = "KioskBoot"

        private val HANDLED_ACTIONS = setOf(
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON",
        )
    }
}
