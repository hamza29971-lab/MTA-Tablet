package com.example.vtm_tablet

import android.app.ActivityManager
import android.app.ActivityOptions
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import android.view.View
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

/**
 * Kiosk dashboard'u. Arayuz Flutter tarafinda, kilit mantigi burada.
 *
 * Cikis yollari yalnizca iki parola ile acilir (parolalar acik metin olarak
 * saklanmaz, SHA-256 ozetleriyle karsilastirilir):
 *
 *   482910 -> AYARLAR MODU. Ayarlar uygulamasi kilit gorevine eklenir.
 *             Kullanici Ayarlar disina cikamaz, fabrika ayarlarina donemez,
 *             uygulamayi silemez. Ayarlar kapatilinca tekrar buraya duser.
 *
 *   905174 -> SERBEST BIRAKMA. Cihaz sahipligi ve tum kisitlar kalkar;
 *             uygulama silinebilir, tablet sifirlanabilir. Geri donusu yoktur.
 */
class MainActivity : FlutterActivity() {

    private var channel: MethodChannel? = null

    /** Ayarlar moduna gecildiginde true olur; buraya donunce politika sertlestirilir. */
    private var settingsModeActive = false

    /** Serbest birakma sonrasi kiosk politikasini tekrar yazmamak icin. */
    private var released = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result -> handleCall(call.method, call.arguments, result) }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Ekran kilidi uzerinde de acil, cihaz uyanik kalsin.
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        )
    }

    override fun onResume() {
        super.onResume()
        hideSystemUi()
        if (released) return

        if (settingsModeActive) {
            // Ayarlar kapatildi, kullanici geri dondu: izin listesi tekrar
            // yalnizca bu uygulama olacak sekilde daraltilir.
            settingsModeActive = false
            Log.i(TAG, "Ayarlar modundan donuldu, kiosk sertlestiriliyor")
        }
        KioskPolicy.applyKiosk(this)
        enterLockTask()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            hideSystemUi()
            if (!released && !settingsModeActive) enterLockTask()
        }
    }

    /**
     * Geri tusu ve kenardan kaydirma jesti buraya duser.
     *
     * Flutter tarafina haber verilir: acik bir diyalog varsa o kapanir, yoksa
     * parola ekrani acilir. super.onBackPressed() BILEREK cagrilmaz - yoksa
     * kilit gorevi disinda (device owner yokken) uygulama kapanabilirdi.
     */
    @Suppress("DEPRECATION", "MissingSuperCall")
    override fun onBackPressed() {
        val notified = channel?.let {
            it.invokeMethod("exitAttempt", "back")
            true
        } ?: false
        if (!notified) Log.w(TAG, "Geri tusu geldi ama Flutter kanali hazir degil")
    }

    private fun handleCall(method: String, arguments: Any?, result: MethodChannel.Result) {
        when (method) {
            "status" -> result.success(statusMap())

            "unlock" -> {
                val password = (arguments as? Map<*, *>)?.get("password") as? String
                if (password.isNullOrEmpty()) {
                    result.success("invalid")
                } else {
                    result.success(unlock(password))
                }
            }

            "reassert" -> {
                if (!released) {
                    KioskPolicy.applyKiosk(this)
                    enterLockTask()
                }
                hideSystemUi()
                result.success(statusMap())
            }

            "installApk" -> {
                val path = (arguments as? Map<*, *>)?.get("path") as? String
                if (path.isNullOrEmpty()) {
                    result.success(false)
                } else {
                    // APK kopyalamasi on plandaki is parcaciginda yapilirsa
                    // 50 MB'lik dosyada arayuz donar (ANR). Ayri bir thread'de
                    // yapilir, sonuc ana thread'e geri verilir.
                    Thread {
                        val ok = KioskInstaller.install(this, path)
                        runOnUiThread { result.success(ok) }
                    }.start()
                }
            }

            "goHome" -> {
                startActivity(
                    Intent(Intent.ACTION_MAIN)
                        .addCategory(Intent.CATEGORY_HOME)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                )
                result.success(true)
            }

            else -> result.notImplemented()
        }
    }

    private fun statusMap(): Map<String, Any> = mapOf(
        "deviceOwner" to KioskPolicy.isDeviceOwner(this),
        "locked" to (lockTaskState() == ActivityManager.LOCK_TASK_MODE_LOCKED),
        "lockTaskState" to lockTaskState(),
        "released" to released,
        "packageName" to packageName
    )

    private fun unlock(password: String): String = when (sha256(password)) {
        SETTINGS_PASSWORD_HASH -> {
            openSettingsMode()
            "settings"
        }
        RELEASE_PASSWORD_HASH -> {
            if (releaseKiosk()) "released" else "release_failed"
        }
        else -> "invalid"
    }

    /**
     * Ayarlar modu. Ayarlar uygulamasi kilit gorevi listesine eklenir ve kilitli
     * baslatilir; boylece kullanici Ayarlar icinde gezebilir ama ana ekrana,
     * son uygulamalara veya baska bir uygulamaya GECEMEZ. Geri tusuyla Ayarlar
     * kapandiginda sistem onu bu uygulamaya birakir.
     */
    private fun openSettingsMode() {
        val intent = Intent(Settings.ACTION_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

        if (!KioskPolicy.isDeviceOwner(this)) {
            // Cihaz sahipligi yoksa kilitlenecek bir sey de yok; Ayarlar duz acilir.
            runCatching { startActivity(intent) }
            return
        }

        if (!KioskPolicy.allowSettings(this)) {
            Log.e(TAG, "Ayarlar kilit gorevi listesine eklenemedi")
            return
        }
        settingsModeActive = true

        val options = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            ActivityOptions.makeBasic().setLockTaskEnabled(true).toBundle()
        } else {
            null
        }

        runCatching { startActivity(intent, options) }.onFailure {
            Log.e(TAG, "Ayarlar acilamadi", it)
            settingsModeActive = false
            KioskPolicy.applyKiosk(this)
        }
    }

    /** Kilit gorevini durdurur ve cihaz sahipligini birakir. Geri donusu yoktur. */
    private fun releaseKiosk(): Boolean {
        runCatching { stopLockTask() }.onFailure { Log.w(TAG, "stopLockTask basarisiz", it) }
        val ok = KioskPolicy.release(this)
        if (ok) {
            released = true
            settingsModeActive = false
            showSystemUi()
        }
        return ok
    }

    private fun enterLockTask() {
        if (!KioskPolicy.isDeviceOwner(this)) return
        if (!KioskPolicy.isLockTaskPermitted(this)) {
            Log.e(TAG, "Paket kilit gorevine izinli degil; kilit baslatilamiyor")
            return
        }
        when (lockTaskState()) {
            ActivityManager.LOCK_TASK_MODE_LOCKED -> return
            ActivityManager.LOCK_TASK_MODE_PINNED -> {
                // Kullanicinin kendi baslattigi "ekran sabitleme" guvenli degildir;
                // birakilip gercek kilit gorevi baslatilir.
                runCatching { stopLockTask() }
            }
        }
        runCatching { startLockTask() }.onFailure { Log.e(TAG, "startLockTask basarisiz", it) }
    }

    private fun lockTaskState(): Int {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            am.lockTaskModeState
        } else {
            @Suppress("DEPRECATION")
            if (am.isInLockTaskMode) ActivityManager.LOCK_TASK_MODE_LOCKED
            else ActivityManager.LOCK_TASK_MODE_NONE
        }
    }

    /** Durum cubugu ve gezinme cubugu tamamen gizlenir (yukaridan asagi kaydirma dahil). */
    @Suppress("DEPRECATION")
    private fun hideSystemUi() {
        window.decorView.systemUiVisibility = (
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
                View.SYSTEM_UI_FLAG_FULLSCREEN or
                View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
            )
    }

    @Suppress("DEPRECATION")
    private fun showSystemUi() {
        window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_VISIBLE
    }

    private fun sha256(value: String): String {
        val digest = MessageDigest.getInstance("SHA-256").digest(value.toByteArray(Charsets.UTF_8))
        return digest.joinToString("") { "%02x".format(it) }
    }

    companion object {
        const val TAG = "KioskMode"
        private const val CHANNEL = "mta.kiosk/control"

        /** SHA-256("482910") - ayarlara cikis parolasi. */
        private const val SETTINGS_PASSWORD_HASH =
            "41d59ff0ac9815d60d3565149806eb6415348b7aa45a04ac6b2ba7eb8cb879ae"

        /** SHA-256("905174") - kiosk korumasini tamamen kaldiran parola. */
        private const val RELEASE_PASSWORD_HASH =
            "3f2133e7dfc51ff2130ddad21310129a6e3ff571cba5c0fb97c1a3f2e5e18305"
    }
}
