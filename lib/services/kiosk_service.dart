// lib/services/kiosk_service.dart
//
// Android tarafindaki kiosk (device owner) katmaniyla konusan tek nokta.
// Butun politika islerini MainActivity.kt yapar; burada yalnizca cagri ve
// sonuc cevirisi vardir.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Parola girildiginde ne oldugunu anlatir.
enum KioskUnlockResult {
  /// "482910" - Ayarlar modu acildi. Kullanici yalnizca Ayarlar'a cikabilir.
  settings,

  /// "905174" - Cihaz sahipligi birakildi. Uygulama silinebilir, tablet
  /// sifirlanabilir. Geri donusu yoktur.
  released,

  /// Parola dogruydu ama sahiplik birakilamadi.
  releaseFailed,

  /// Parola yanlis.
  invalid,

  /// Kiosk katmani yok (Android disi platform veya eski surum).
  unavailable,
}

/// Kiosk katmaninin anlik durumu.
@immutable
class KioskStatus {
  /// Uygulama cihaz sahibi mi? Kiosk korumasinin tamami buna baglidir.
  final bool deviceOwner;

  /// Su anda gercek kilit gorevi (LOCKED) icinde miyiz?
  final bool locked;

  /// Bu oturumda "905174" ile serbest birakildi mi?
  final bool released;

  /// Kanal calisiyor mu? Android disi platformlarda false.
  final bool available;

  const KioskStatus({
    required this.deviceOwner,
    required this.locked,
    required this.released,
    required this.available,
  });

  static const KioskStatus unavailable = KioskStatus(
    deviceOwner: false,
    locked: false,
    released: false,
    available: false,
  );

  /// Kiosk korumasi tam olarak calisiyor mu?
  bool get isProtected => available && deviceOwner;
}

class KioskService {
  KioskService._();

  static const MethodChannel _channel = MethodChannel('mta.kiosk/control');

  /// Kiosk yalnizca Android tabletlerde anlamlidir; masaustu/web derlemelerinde
  /// kanal yoktur ve uygulama normal calisir.
  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Geri tusu / kenardan kaydirma gibi cikis denemelerinde Android tarafi
  /// bunu cagirir. Kaynak su an yalnizca "back" olabilir.
  static void setExitAttemptHandler(void Function(String source) handler) {
    if (!isSupported) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'exitAttempt') {
        handler(call.arguments is String ? call.arguments as String : 'unknown');
      }
      return null;
    });
  }

  static void clearExitAttemptHandler() {
    if (!isSupported) return;
    _channel.setMethodCallHandler(null);
  }

  static Future<KioskStatus> status() => _statusCall('status');

  /// Politikayi yeniden yazar ve kilit gorevini tekrar baslatir.
  static Future<KioskStatus> reassert() => _statusCall('reassert');

  static Future<KioskStatus> _statusCall(String method) async {
    if (!isSupported) return KioskStatus.unavailable;
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(method);
      if (result == null) return KioskStatus.unavailable;
      return KioskStatus(
        deviceOwner: result['deviceOwner'] == true,
        locked: result['locked'] == true,
        released: result['released'] == true,
        available: true,
      );
    } catch (e) {
      debugPrint('Kiosk durumu okunamadi: $e');
      return KioskStatus.unavailable;
    }
  }

  /// Cikis parolasini dener. Dogruysa ilgili modu Android tarafi acar.
  static Future<KioskUnlockResult> unlock(String password) async {
    if (!isSupported) return KioskUnlockResult.unavailable;
    try {
      final result =
          await _channel.invokeMethod<String>('unlock', {'password': password});
      switch (result) {
        case 'settings':
          return KioskUnlockResult.settings;
        case 'released':
          return KioskUnlockResult.released;
        case 'release_failed':
          return KioskUnlockResult.releaseFailed;
        default:
          return KioskUnlockResult.invalid;
      }
    } catch (e) {
      debugPrint('Kiosk parola dogrulamasi basarisiz: $e');
      return KioskUnlockResult.unavailable;
    }
  }

  /// Indirilen APK'yi cihaz sahibi yetkisiyle sessizce kurar.
  /// Kilit gorevi acikken sistemin kurulum ekrani one gelemedigi icin
  /// guncelleme yalnizca bu yolla yapilabilir.
  static Future<bool> installApk(String path) async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('installApk', {'path': path}) ??
          false;
    } catch (e) {
      debugPrint('Sessiz kurulum basarisiz: $e');
      return false;
    }
  }

  /// Serbest birakma sonrasi tabletin kendi ana ekranina doner.
  static Future<void> goHome() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<bool>('goHome');
    } catch (e) {
      debugPrint('Ana ekrana donulemedi: $e');
    }
  }
}
