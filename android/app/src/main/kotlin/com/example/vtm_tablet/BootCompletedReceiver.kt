package com.example.vtm_tablet; // <-- KENDİ PAKET ADINIZI KONTROL EDİN

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootCompletedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // Sadece "BOOT_COMPLETED" sinyali geldiğinde çalış
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            // MainActivity'i (yani Flutter uygulamasını) başlatmak için bir Intent oluştur
            val activityIntent = Intent(context, MainActivity::class.java)
            // Uygulama bir arayüzden başlatılmadığı için bu bayrak zorunludur
            activityIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            // Uygulamayı başlat
            context.startActivity(activityIntent)
        }
    }
}