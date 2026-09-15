package com.example.vtm_tablet

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.UserManager
import android.provider.Settings
import android.util.Log

/**
 * Tum device-owner politikasi tek yerde toplanmistir.
 *
 * Uygulama uc durumdan birinde olabilir:
 *
 *   KIOSK    - normal calisma. Kilit gorevi yalnizca bu pakete izinlidir,
 *              bildirim paneli / hizli ayarlar / ana ekran / son uygulamalar
 *              kapalidir, fabrika ayarlarina donus ve uygulama kaldirma
 *              engellidir.
 *
 *   AYARLAR  - "482910" parolasi girilince acilir. Kilit gorevi listesine
 *              yalnizca Ayarlar uygulamasi eklenir; kullanici Ayarlar disina
 *              cikmaya calistiginda sistem onu tekrar bu uygulamaya birakir.
 *              Fabrika ayarlari ve uygulama kaldirma HALA engellidir.
 *
 *   SERBEST  - "905174" parolasi girilince acilir. Butun kisitlar kaldirilir
 *              ve cihaz sahipligi birakilir; uygulama silinebilir, tablet
 *              sifirlanabilir. Geri donus icin kurulum scripti gerekir.
 */
object KioskPolicy {

    const val TAG = "KioskPolicy"

    /** Ana ekran (HOME) olarak kayitli takma ad. Serbest birakilinca kapatilir. */
    private const val HOME_ALIAS = "com.example.vtm_tablet.KioskHomeAlias"

    /** Ayarlar modunda kilit gorevine eklenecek paketleri bulmak icin kullanilir. */
    private val SETTINGS_INTENTS = listOf(
        Settings.ACTION_SETTINGS,
        Settings.ACTION_WIFI_SETTINGS,
        Settings.ACTION_DISPLAY_SETTINGS,
        Settings.ACTION_SOUND_SETTINGS,
        Settings.ACTION_DATE_SETTINGS,
        Settings.ACTION_LOCALE_SETTINGS,
    )

    /** Bazi cihazlarda Ayarlar ekranlari bu yardimci paketlere dallanir. */
    private val EXTRA_SETTINGS_PACKAGES = listOf(
        "com.android.settings",
        "com.android.settings.intelligence",
        "com.samsung.android.settings",
    )

    /**
     * Kiosk modunda uygulanan kullanici kisitlari.
     *
     * DISALLOW_DEBUGGING_FEATURES BILEREK yok: adb kapatilirsa tableti
     * guncellemek ve kurtarmak icin tek yol kalmaz.
     */
    private val RESTRICTIONS: List<String> = mutableListOf(
        UserManager.DISALLOW_FACTORY_RESET,
        UserManager.DISALLOW_ADD_USER,
        UserManager.DISALLOW_SAFE_BOOT,
        UserManager.DISALLOW_UNINSTALL_APPS,
        UserManager.DISALLOW_ADD_MANAGED_PROFILE,
        UserManager.DISALLOW_OUTGOING_BEAM,
    ).apply {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            add(UserManager.DISALLOW_USER_SWITCH)
        }
    }.toList()

    fun dpm(context: Context): DevicePolicyManager =
        context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager

    fun admin(context: Context): ComponentName =
        KioskDeviceAdminReceiver.componentName(context)

    fun isDeviceOwner(context: Context): Boolean = try {
        dpm(context).isDeviceOwnerApp(context.packageName)
    } catch (e: Exception) {
        Log.e(TAG, "Cihaz sahipligi okunamadi", e)
        false
    }

    fun isLockTaskPermitted(context: Context): Boolean = try {
        dpm(context).isLockTaskPermitted(context.packageName)
    } catch (e: Exception) {
        false
    }

    /** Tam kiosk politikasi. Tekrar tekrar uygulanmasi guvenlidir. */
    fun applyKiosk(context: Context) {
        val ctx = context.applicationContext
        if (!isDeviceOwner(ctx)) {
            Log.w(TAG, "Cihaz sahibi degiliz; kiosk politikasi uygulanmadi")
            return
        }
        val dpm = dpm(ctx)
        val admin = admin(ctx)

        enableHomeAlias(ctx, true)
        setAsPersistentHome(ctx, dpm, admin)

        // Kilit gorevi izin listesi. "adb shell dpm set-lock-task-packages" diye
        // bir komut YOKTUR; bu is yalnizca burada, uygulamanin kendi icinde yapilir.
        runCatching { dpm.setLockTaskPackages(admin, arrayOf(ctx.packageName)) }
            .onFailure { Log.e(TAG, "setLockTaskPackages basarisiz", it) }

        // Bildirim paneli, hizli ayarlar, ana ekran, son uygulamalar: hepsi kapali.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            runCatching {
                dpm.setLockTaskFeatures(admin, DevicePolicyManager.LOCK_TASK_FEATURE_NONE)
            }.onFailure { Log.e(TAG, "setLockTaskFeatures basarisiz", it) }
        }

        setRestrictions(dpm, admin, true)
        runCatching { dpm.setUninstallBlocked(admin, ctx.packageName, true) }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // Bildirim panelinin ve hizli ayarlarin ikinci kilidi: kilit gorevi
            // bir sekilde dusse bile durum cubugu yine acilmaz.
            runCatching { dpm.setStatusBarDisabled(admin, true) }
            runCatching { dpm.setKeyguardDisabled(admin, true) }
        }
        Log.i(TAG, "Kiosk politikasi uygulandi")
    }

    /**
     * "482910" parolasi icin: kilit gorevi listesine Ayarlar eklenir.
     *
     * Kisitlar KALDIRILMAZ. Kullanici Ayarlar icindedir ama fabrika ayarlarina
     * donemez, uygulamayi silemez; Ayarlar disina cikmak istediginde sistem onu
     * tekrar bu uygulamaya dusurur.
     */
    fun allowSettings(context: Context): Boolean {
        val ctx = context.applicationContext
        if (!isDeviceOwner(ctx)) return false
        val dpm = dpm(ctx)
        val admin = admin(ctx)

        val packages = (listOf(ctx.packageName) + settingsPackages(ctx)).distinct().toTypedArray()
        return runCatching {
            dpm.setLockTaskPackages(admin, packages)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                // Ayarlar icinde saat/pil/wifi simgeleri gorunsun diye yalnizca
                // SYSTEM_INFO acilir. Bildirim panelini acan izin (NOTIFICATIONS)
                // BILEREK verilmez; panel yine acilmaz.
                dpm.setLockTaskFeatures(admin, DevicePolicyManager.LOCK_TASK_FEATURE_SYSTEM_INFO)
            }
            Log.i(TAG, "Ayarlar modu acildi: " + packages.joinToString())
            true
        }.onFailure { Log.e(TAG, "Ayarlar modu acilamadi", it) }.getOrDefault(false)
    }

    /**
     * "905174" parolasi icin: butun kisitlari ve cihaz sahipligini birakir.
     * Bu islemin geri donusu yoktur; tablet ancak kurulum scriptiyle tekrar
     * kiosk moduna alinabilir.
     */
    fun release(context: Context): Boolean {
        val ctx = context.applicationContext
        if (!isDeviceOwner(ctx)) return true
        val dpm = dpm(ctx)
        val admin = admin(ctx)

        // Sira onemli: sahiplik birakildiktan sonra asagidaki cagrilarin hicbiri
        // calismaz, bu yuzden once temizlik yapilir.
        setRestrictions(dpm, admin, false)
        runCatching { dpm.setUninstallBlocked(admin, ctx.packageName, false) }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            runCatching { dpm.setStatusBarDisabled(admin, false) }
            runCatching { dpm.setKeyguardDisabled(admin, false) }
        }
        runCatching { dpm.setLockTaskPackages(admin, emptyArray()) }
        runCatching { dpm.clearPackagePersistentPreferredActivities(admin, ctx.packageName) }
        enableHomeAlias(ctx, false)

        return runCatching {
            @Suppress("DEPRECATION")
            dpm.clearDeviceOwnerApp(ctx.packageName)
            Log.w(TAG, "Cihaz sahipligi birakildi")
            true
        }.onFailure { Log.e(TAG, "Cihaz sahipligi birakilamadi", it) }.getOrDefault(false)
    }

    /** Uygulamayi kalici ana ekran yapar: tablet acilinca dogrudan buraya duser. */
    private fun setAsPersistentHome(ctx: Context, dpm: DevicePolicyManager, admin: ComponentName) {
        val filter = IntentFilter(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            addCategory(Intent.CATEGORY_DEFAULT)
        }
        runCatching {
            dpm.clearPackagePersistentPreferredActivities(admin, ctx.packageName)
            dpm.addPersistentPreferredActivity(
                admin, filter, ComponentName(ctx.packageName, HOME_ALIAS)
            )
        }.onFailure { Log.e(TAG, "Kalici ana ekran ayarlanamadi", it) }
    }

    /**
     * HOME takma adi normalde KAPALIDIR: cihaz sahipligi atanmadan uygulama
     * ana ekran seceneklerinde gorunmemelidir. Sahiplik varken acilir,
     * birakilinca tekrar kapatilir; boylece tabletin kendi launcher'i geri gelir.
     */
    private fun enableHomeAlias(ctx: Context, enabled: Boolean) {
        val state = if (enabled) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED
        } else {
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED
        }
        runCatching {
            ctx.packageManager.setComponentEnabledSetting(
                ComponentName(ctx.packageName, HOME_ALIAS), state, PackageManager.DONT_KILL_APP
            )
        }.onFailure { Log.e(TAG, "HOME takma adi degistirilemedi", it) }
    }

    private fun setRestrictions(dpm: DevicePolicyManager, admin: ComponentName, enabled: Boolean) {
        for (restriction in RESTRICTIONS) {
            runCatching {
                if (enabled) {
                    dpm.addUserRestriction(admin, restriction)
                } else {
                    dpm.clearUserRestriction(admin, restriction)
                }
            }.onFailure { Log.w(TAG, "Kisit uygulanamadi: " + restriction, it) }
        }
    }

    /** Cihazdaki gercek Ayarlar paketlerini bulur (ureticiye gore degisir). */
    private fun settingsPackages(ctx: Context): List<String> {
        val pm = ctx.packageManager
        val found = mutableSetOf<String>()
        for (action in SETTINGS_INTENTS) {
            runCatching {
                @Suppress("DEPRECATION")
                val info = pm.resolveActivity(Intent(action), PackageManager.MATCH_DEFAULT_ONLY)
                info?.activityInfo?.packageName?.let { found.add(it) }
            }
        }
        for (pkg in EXTRA_SETTINGS_PACKAGES) {
            runCatching {
                @Suppress("DEPRECATION")
                pm.getPackageInfo(pkg, 0)
                found.add(pkg)
            }
        }
        if (found.isEmpty()) found.add("com.android.settings")
        return found.toList()
    }
}
