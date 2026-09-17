package com.example.vtm_tablet

import android.app.Activity
import android.app.ActivityOptions
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log

/**
 * Tabletin kalici ANA EKRANIDIR ve uygulamanin tek disa acik giris noktasidir.
 *
 * MainActivity ASLA dogrudan baslatilmaz. Bootstrap once device-owner
 * politikasini yazar, sonra dashboard'u ActivityOptions.setLockTaskEnabled ile
 * kilitli acar. Boylece uygulama, kullanici hicbir sey yapmadan once kilit
 * gorevi (lock task) icinde baslar.
 *
 * Kurulum scripti de bu bileseni cagirir:
 *   adb shell am start -n com.mta.sondaj_takip/com.example.vtm_tablet.KioskBootstrapActivity
 */
class KioskBootstrapActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        launchDashboard()
        finish()
    }

    private fun launchDashboard() {
        // Politika her acilista yeniden yazilir: tablet kapanip acilsa, uygulama
        // guncellense veya bir ayar disaridan bozulsa bile kiosk geri gelir.
        KioskPolicy.applyKiosk(this)

        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        val options = if (
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            KioskPolicy.isDeviceOwner(this) &&
            KioskPolicy.isLockTaskPermitted(this)
        ) {
            // Kilitli acilis. Kullanici arayuzu gorunmeden once kilit devrededir;
            // "once acilsin sonra kilitleyelim" araligi boylece hic olusmaz.
            ActivityOptions.makeBasic().setLockTaskEnabled(true).toBundle()
        } else {
            Log.w(TAG, "Kilitli acilis yapilamiyor; cihaz sahipligi yok")
            null
        }

        startActivity(intent, options)
    }

    companion object {
        const val TAG = "KioskBootstrap"
    }
}
