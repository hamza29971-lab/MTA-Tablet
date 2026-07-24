// // // lib/providers/config_provider.dart

// // import 'dart:convert';
// // import 'package:flutter/foundation.dart';
// // import '../models/app_config.dart';
// // import 'package:shared_preferences/shared_preferences.dart'; 

// // class ConfigurationProvider with ChangeNotifier {
// //   static const _configKey = 'app_config_v2'; // Modeli değiştirdiğimiz için anahtarı değiştirmek en iyisidir
// //   late AppConfig _appConfig;
// //   bool _isLoading = true;

// //   AppConfig get appConfig => _appConfig;
// //   bool get isLoading => _isLoading;

// //   ConfigurationProvider() {
// //     print("<<<<<<<<<< CONFIGURATION PROVIDER CONSTRUCTOR ÇALIŞTI! >>>>>>>>>>");
// //     _appConfig = AppConfig.initial();
// //     loadConfiguration();
// //   }

// // Future<void> loadConfiguration() async {
// //     print("--- 1. loadConfiguration metodu başladı. ---");
// //   _isLoading = true;
// //   notifyListeners();
// //   final prefs = await SharedPreferences.getInstance();
// //    print("--- 2. SharedPreferences'tan veri okunacak. Anahtar: '$_configKey' ---");
// //   final String? configString = prefs.getString(_configKey);

// //   if (configString != null) {
// //     print("--- 3. BAŞARILI: Kayıtlı veri bulundu! ---");
// //       print("--- OKUNAN HAM VERİ ---");
// //       print(configString);
// //       print("----------------------");
// //     try {
// //       // ✅ Hata kontrolü eklendi
// //       _appConfig = AppConfig.fromJson(jsonDecode(configString));
// //     } catch (e) {
// //       print("Kayıtlı konfigürasyon okunamadı, varsayılana dönülüyor: $e");
// //       // Hata olursa varsayılan ayarları yükle
// //       _appConfig = AppConfig.initial();
// //     }
// //   } else {
// //     _appConfig = AppConfig.initial();
// //   }
  
// //   _isLoading = false;
// //   notifyListeners();
// // }
// //   // YENİ METOT: Belirli bir göstergenin ayarını günceller ve kaydeder
// //   Future<void> updateGaugeConfig(GaugeConfig newConfig) async {
// //     // 1. Map içindeki ilgili ayarı güncelle
// //     _appConfig.gaugeConfigs[newConfig.id] = newConfig;

// //     // 2. Değişikliğin tamamını cihaza kaydet
// //     final prefs = await SharedPreferences.getInstance();
// //     final String configString = jsonEncode(_appConfig.toJson());
// //     await prefs.setString(_configKey, configString);

// //     // 3. Arayüzü değişiklikle ilgili bilgilendir
// //     notifyListeners();
// //     print("${newConfig.id} güncellendi ve kaydedildi.");
// //   }
// // }

// // lib/providers/config_provider.dart

// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../models/app_config.dart';

// class ConfigurationProvider with ChangeNotifier {
//   static const _configKey = 'app_config_v3';
//   late AppConfig _appConfig;
//   bool _isLoading = true;

//   AppConfig get appConfig => _appConfig;
//   bool get isLoading => _isLoading;

//   ConfigurationProvider() {
//     _appConfig = AppConfig.initial();
//     loadConfiguration();
//   }

//   // YENİ: Mevcut konfigürasyonu diske kaydeden özel yardımcı metot
//   Future<void> _saveCurrentConfig() async {
//     final prefs = await SharedPreferences.getInstance();
//     final String configString = jsonEncode(_appConfig.toJson());
//     await prefs.setString(_configKey, configString);
//   }

//   Future<void> loadConfiguration() async {
//     _isLoading = true;
//     notifyListeners();
//     final prefs = await SharedPreferences.getInstance();
//     final String? configString = prefs.getString(_configKey);

//     if (configString != null) {
//       try {
//         _appConfig = AppConfig.fromJson(jsonDecode(configString));
//       } catch (e) {
//         print("Kayıtlı konfigürasyon okunamadı, varsayılana dönülüyor: $e");
//         _appConfig = AppConfig.initial();
//       }
//     } else {
//       // YENİ: Kayıtlı konfigürasyon yoksa, varsayılan ayarları yükle VE diske kaydet.
//       print("Kayıtlı konfigürasyon bulunamadı, varsayılan ayarlar oluşturulup kaydediliyor.");
//       _appConfig = AppConfig.initial();
//       await _saveCurrentConfig(); // İlk açılışta kaydet
//     }
    
//     _isLoading = false;
//     notifyListeners();
//   }
  
//   Future<void> updateGaugeConfig(GaugeConfig newConfig) async {
//     _appConfig.gaugeConfigs[newConfig.id] = newConfig;
//     await _saveCurrentConfig(); // Kaydetme işlemini yardımcı metotla yap
//     notifyListeners();
//     print("${newConfig.id} güncellendi ve kaydedildi.");
//   }

//   // YENİ: Tüm ayarları varsayılana sıfırlayan metot
//   Future<void> restoreToDefaults() async {
//     print("Tüm ayarlar varsayılana sıfırlanıyor...");
//     // 1. Bellekteki ayarları varsayılanlarla değiştir
//     _appConfig = AppConfig.initial();
//     // 2. Diskteki kayıtlı ayarların üzerine varsayılanları yaz
//     await _saveCurrentConfig();
//     // 3. Arayüzü güncelle
//     notifyListeners();
//     print("Ayarlar varsayılana sıfırlandı ve kaydedildi.");
//   }
// }

// lib/providers/config_provider.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

class ConfigurationProvider with ChangeNotifier {
  static const String _configKey = 'app_config_v10'; // Eski ayarları sıfırlayıp yeni kodları geçerli kılmak için v10 yaptık
  late AppConfig _appConfig;
  bool _isLoading = true;

  AppConfig get appConfig => _appConfig;
  bool get isLoading => _isLoading;

  // ConfigurationProvider() {
  //   _appConfig = AppConfig.initial();
  //   loadConfiguration();
  // }

    ConfigurationProvider() {
    _appConfig = AppConfig.initial();
    _isLoading = true; // Başlangıçta yükleniyor durumunda
  }

    Future<void> init() async {
    await loadConfiguration();
  }

  Future<void> _saveCurrentConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final String configString = jsonEncode(_appConfig.toJson());
    await prefs.setString(_configKey, configString);
  }

  // Future<void> loadConfiguration() async {
  //   _isLoading = true;
  //   notifyListeners();
  //   final prefs = await SharedPreferences.getInstance();
  //   final String? configString = prefs.getString(_configKey);

  //   if (configString != null) {
  //     try {
  //       _appConfig = AppConfig.fromJson(jsonDecode(configString));
  //     } catch (e) {
  //       print("Kayıtlı konfigürasyon okunamadı, varsayılana dönülüyor: $e");
  //       _appConfig = AppConfig.initial();
  //     }
  //   } else {
  //     print("Kayıtlı konfigürasyon bulunamadı, varsayılan ayarlar oluşturulup kaydediliyor.");
  //     _appConfig = AppConfig.initial();
  //     await _saveCurrentConfig();
  //   }
    
  //   _isLoading = false;
  //   notifyListeners();
  // }

    Future<void> loadConfiguration() async {
    _isLoading = true;
    // notifyListeners(); // init içinde çağrıldığı için burada gereksiz

    final prefs = await SharedPreferences.getInstance();
    final String? configString = prefs.getString(_configKey);

    if (configString != null) {
      try {
        _appConfig = AppConfig.fromJson(jsonDecode(configString));
      } catch (e) {
        print("Kayıtlı konfigürasyon okunamadı, varsayılana dönülüyor: $e");
        _appConfig = AppConfig.initial();
      }
    } else {
      print("Kayıtlı konfigürasyon bulunamadı, varsayılan ayarlar oluşturulup kaydediliyor.");
      _appConfig = AppConfig.initial();
      await _saveCurrentConfig();
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Tek bir gösterge ayarını günceller
  Future<void> updateGaugeConfig(GaugeConfig newConfig) async {
    _appConfig.gaugeConfigs[newConfig.id] = newConfig;
    await _saveCurrentConfig();
    notifyListeners();
    print("${newConfig.id} güncellendi ve kaydedildi.");
  }

  // ✅ YENİ EKLENEN METOT ✅
  // Tüm AppConfig nesnesini günceller (eğim kaynakları gibi genel ayarlar için)
  Future<void> updateAppConfig(AppConfig newConfig) async {
    _appConfig = newConfig;
    await _saveCurrentConfig();
    notifyListeners();
    print("Genel uygulama ayarları güncellendi ve kaydedildi.");
  }

  // Tüm ayarları varsayılana sıfırlar
  Future<void> restoreToDefaults() async {
    print("Tüm ayarlar varsayılana sıfırlanıyor...");
    _appConfig = AppConfig.initial();
    await _saveCurrentConfig();
    notifyListeners();
    print("Ayarlar varsayılana sıfırlandı ve kaydedildi.");
  }
}
