// // import 'package:flutter/material.dart';
// // import 'package:vtm_tablet/models/app_config.dart';
// // import 'package:vtm_tablet/models/device_data.dart';
// // import 'package:vtm_tablet/providers/data_provider.dart';

// // // Pop-up'ta gösterilecek veriyi tutan basit bir sınıf
// // class PopUpData {
// //   final String title;
// //   final String message;
// //   final PopUpAlertLevel level;
// //   PopUpData({required this.title, required this.message, required this.level});
// // }

// // // Bu enum'ı projenizde tek bir yerden yönetmek en iyisidir.
// // enum PopUpAlertLevel { normal, warning, critical }

// // class AlertProvider with ChangeNotifier {
// //   final DataProvider _dataProvider;
// //   final AppConfig _appConfig;
  
// //   // Hangi göstergelerin pop-up çıkaracağını ve mesajlarını burada merkezi olarak yönetiyoruz.
// //   // Anahtar: gaugeId, Değer: {Seviye: Mesaj}
// //   static const Map<String, Map<PopUpAlertLevel, String>> _popupTriggers = {
// //     // GAUGE'LAR
// //     'can_coolant_temp': { // Motor Hararet
// //       PopUpAlertLevel.warning: 'Motor soğutma suyu sıcaklığı artıyor. Motoru rölantide çalıştırarak soğutun.',
// //       PopUpAlertLevel.critical: 'KRİTİK: Motor hararet yaptı! Kalıcı hasarı önlemek için motoru hemen durdurun.',
// //     },
// //     // İNDİKATÖRLER (Dijital Tab'daki)
// //     'aux_2': { // Hidrolik Sıcaklık
// //       PopUpAlertLevel.critical: 'KRİTİK: Hidrolik yağ aşırı ısındı! Ciddi hasar riski. Sistemi soğuması için durdurun.',
// //     },
// //     'aux_5': { // Hidrolik Seviye
// //       PopUpAlertLevel.critical: 'KRİTİK: Hidrolik yağ seviyesi tehlikeli derecede düşük! Pompa hasarı riski. Derhal takviye yapın.',
// //     },
// //     // Diğer indikatörleri de buraya ekleyebilirsiniz.
// //     // 'aux_3': { PopUpAlertLevel.critical: 'Filtre 1 Tıkalı!' },
// //     // 'aux_4': { PopUpAlertLevel.critical: 'Filtre 2 Tıkalı!' },
// //   };

// //   // Her bir alarmın bir önceki durumunu hafızada tutuyoruz.
// //   final Map<String, PopUpAlertLevel> _lastAlertLevels = {};
  
// //   // UI'a bir pop-up göstermesi gerektiğini bildiren değişken.
// //   PopUpData? _newPopupToShow;
// //   PopUpData? get newPopupToShow => _newPopupToShow;

// //   AlertProvider(this._dataProvider, this._appConfig) {
// //     // DataProvider'dan yeni veri geldiğinde dinlemeye başla.
// //     _dataProvider.addListener(_checkForNewPopups);
// //     // Başlangıç durumlarını ayarla
// //     _initializeAlertLevels();
// //   }
  
// //   // Provider yok olduğunda listener'ı temizle.
// //   @override
// //   void dispose() {
// //     _dataProvider.removeListener(_checkForNewPopups);
// //     super.dispose();
// //   }

// //   // Başlangıçta tüm alarmları 'normal' olarak ayarlar.
// //   void _initializeAlertLevels() {
// //     for (var gaugeId in _popupTriggers.keys) {
// //       _lastAlertLevels[gaugeId] = PopUpAlertLevel.normal;
// //     }
// //   }
  
// //   // Ana kontrol mantığı: Yeni veri geldiğinde çalışır.
// //   void _checkForNewPopups() {
// //     // Ekranda zaten bir pop-up gösteriliyorsa yenisini tetikleme.
// //     if (_newPopupToShow != null) return;

// //     for (var entry in _popupTriggers.entries) {
// //       final gaugeId = entry.key;
// //       final messages = entry.value;
      
// //       final gaugeConfig = _appConfig.gaugeConfigs[gaugeId];
// //       if (gaugeConfig == null) continue;

// //       // getValueForId metodunu buraya taşıdık ve basitleştirdik.
// //       final currentValue = _getValueForId(_dataProvider.deviceData, gaugeId);
      
// //       final currentLevel = _getAlertLevel(currentValue, gaugeConfig);
// //       final previousLevel = _lastAlertLevels[gaugeId] ?? PopUpAlertLevel.normal;

// //       // Eğer alarm seviyesi YÜKSELDİYSE
// //       if (currentLevel.index > previousLevel.index) {
// //         final message = messages[currentLevel] ?? 'Bilinmeyen bir uyarı oluştu.';
        
// //         _newPopupToShow = PopUpData(
// //           title: gaugeConfig.label,
// //           message: '$message\n\nMevcut Değer: ${currentValue.toStringAsFixed(1)} ${gaugeConfig.unit}',
// //           level: currentLevel,
// //         );
// //         _lastAlertLevels[gaugeId] = currentLevel;
        
// //         // UI'a haber ver ve döngüden çık (aynı anda sadece bir pop-up).
// //         notifyListeners();
// //         return; 
// //       }
// //       // Alarm seviyesi düştüyse durumu güncelle
// //       else if (currentLevel.index < previousLevel.index) {
// //          _lastAlertLevels[gaugeId] = currentLevel;
// //       }
// //     }
// //   }

// //   // UI pop-up'ı gösterdikten sonra bu metodu çağırır.
// //   void clearPopup() {
// //     _newPopupToShow = null;
// //     notifyListeners();
// //   }

// //   PopUpAlertLevel _getAlertLevel(double value, GaugeConfig config) {
// //     // Not: İndikatörler (0/1) için warningValue'yu maxValue'dan yüksek ayarladık.
// //     // Bu yüzden onlar sadece critical alarm verir.
// //     if (value >= config.criticalValue) return PopUpAlertLevel.critical;
// //     if (value >= config.warningValue) return PopUpAlertLevel.warning;
// //     return PopUpAlertLevel.normal;
// //   }
  
// //   // HomeTab'dan alınan basitleştirilmiş değer okuma metodu.
// //   double _getValueForId(DeviceData data, String gaugeId) {
// //     if (gaugeId.startsWith('analog_')) {
// //       final index = int.tryParse(gaugeId.split('_')[1]) ?? 0;
// //       return data.analogData.length > index ? data.analogData[index].toDouble() : 0.0;
// //     }
// //     if (gaugeId.startsWith('aux_')) {
// //       final index = int.tryParse(gaugeId.split('_')[1]) ?? 0;
// //       return data.auxData.length > index ? data.auxData[index].toDouble() : 0.0;
// //     }
// //     if (gaugeId.startsWith('can_')) {
// //       switch (gaugeId) {
// //         case 'can_coolant_temp': return data.canData.engineCoolantTemperature.toDouble();
// //         // Gerekirse diğer can değerleri de eklenebilir.
// //         default: return 0.0;
// //       }
// //     }
// //     return 0.0;
// //   }
// // }

// import 'package:flutter/material.dart';
// import 'package:vtm_tablet/models/app_config.dart'; // Kendi projenizdeki doğru yolu belirtin
// import 'package:vtm_tablet/models/device_data.dart'; // Kendi projenizdeki doğru yolu belirtin
// import 'package:vtm_tablet/providers/data_provider.dart';

// // Pop-up'ta gösterilecek veriyi tutan basit bir sınıf
// class PopUpData {
//   final String title;
//   final String message;
//   final PopUpAlertLevel level;
//   PopUpData({required this.title, required this.message, required this.level});
// }

// // Bu enum, projenizde tek bir yerden yönetmek en iyisidir.
// enum PopUpAlertLevel { normal, warning, critical }

// class AlertProvider with ChangeNotifier {
//   final DataProvider _dataProvider;
//   final AppConfig _appConfig;
  
//   // Haritayı, küçük harfli "label" (etiket) değerleri ile anahtarlıyoruz.
//   static const Map<String, Map<PopUpAlertLevel, String>> _popupTriggersByLabel = {
//     // --- GAUGE'LAR ---
    
//     'motor hararet': {
//       PopUpAlertLevel.warning: 'Motor soğutma suyu sıcaklığı artıyor. Motoru rölantide çalıştırarak soğutun.',
//       PopUpAlertLevel.critical: 'KRİTİK: Motor hararet yaptı! Kalıcı hasarı önlemek için motoru hemen durdurun.',
//     },
//     // --- İNDİKATÖRLER ---
//     'hidrolik sıcaklık': {
//       // Bu bir 0/1 indikatörü olduğu için sadece critical durumunu tanımlıyoruz.
//       PopUpAlertLevel.critical: 'KRİTİK: Hidrolik yağ aşırı ısındı! Ciddi hasar riski. Sistemi soğuması için durdurun.',
//     },
//     'hidrolik seviye': {
//       PopUpAlertLevel.critical: 'KRİTİK: Hidrolik yağ seviyesi tehlikeli derecede düşük! Pompa hasarı riski. Derhal takviye yapın.',
//     },
//     'filtre 1': {
//       PopUpAlertLevel.critical: 'KRİTİK: Filtre 1 tıkalı! Sistemin sağlığı için en kısa sürede değiştirin.',
//     },
//      'filtre 2': {
//       PopUpAlertLevel.critical: 'KRİTİK: Filtre 2 tıkalı! Sistemin sağlığı için en kısa sürede değiştirin.',
//     },
//     'acil i̇stop': { // Türkçe karakterlere dikkat
//       PopUpAlertLevel.critical: 'ACİL İSTOP DEVREDE! Sistem durduruldu. Devam etmeden önce durumu kontrol edin.',
//     },
//     'morsed muhafaza': {
//       PopUpAlertLevel.critical: 'GÜVENLİK UYARISI: Morset muhafazası açık! Rotasyon başlamadan önce muhafazayı kapatın.',
//     },
//     // Not: 'Spt Vuruş' genellikle bir alarm değil, bir durum bildirimi olduğu için eklenmedi.
//     // İsterseniz kolayca ekleyebilirsiniz.
//   };

//   // Bir önceki alarm seviyelerini, değişmez olan gaugeId ile saklıyoruz.
//   final Map<String, PopUpAlertLevel> _lastAlertLevels = {};
  
//   PopUpData? _newPopupToShow;
//   PopUpData? get newPopupToShow => _newPopupToShow;

//   AlertProvider(this._dataProvider, this._appConfig) {
//     _dataProvider.addListener(_checkForNewPopups);
//     _initializeAlertLevels();
//   }
  
//   @override
//   void dispose() {
//     _dataProvider.removeListener(_checkForNewPopups);
//     super.dispose();
//   }

//   // Başlangıçta tüm bilinen gaugeId'ler için seviyeyi 'normal' olarak ayarlar.
//   void _initializeAlertLevels() {
//     for (var gaugeId in _appConfig.gaugeConfigs.keys) {
//       _lastAlertLevels[gaugeId] = PopUpAlertLevel.normal;
//     }
//   }
  
//   // Ana kontrol mantığı: Yeni veri geldiğinde çalışır.
//   void _checkForNewPopups() {
//     if (_newPopupToShow != "null") return;

//     // DEĞİŞİKLİK: Haritayı değil, AppConfig'deki TÜM göstergeleri dolaşıyoruz.
//     for (var gaugeConfig in _appConfig.gaugeConfigs.values) {
//       final lowerCaseLabel = gaugeConfig.label.toLowerCase();
      
//       // Eğer bu göstergenin etiketi, pop-up tetikleyicileri haritamızda varsa...
//       if (_popupTriggersByLabel.containsKey(lowerCaseLabel)) {
//         final gaugeId = gaugeConfig.id; // İşte o anki doğru gaugeId!
//         final messages = _popupTriggersByLabel[lowerCaseLabel]!;
        
//         final currentValue = _getValueForId(_dataProvider.deviceData, gaugeId);
//         final currentLevel = _getAlertLevel(currentValue, gaugeConfig);
//         final previousLevel = _lastAlertLevels[gaugeId] ?? PopUpAlertLevel.normal;

//         if (currentLevel.index > previousLevel.index) {
//           _newPopupToShow = PopUpData(
//             title: gaugeConfig.label, // Pop-up başlığında kullanıcının gördüğü etiket kullanılır
//             message: '${messages[currentLevel] ?? messages.values.first}\n\nMevcut Değer: ${currentValue.toStringAsFixed(1)} ${gaugeConfig.unit}',
//             level: currentLevel,
//           );
//           _lastAlertLevels[gaugeId] = currentLevel;
          
//           notifyListeners();
//           return; // Aynı anda sadece bir pop-up göster
//         }
//         else if (currentLevel.index < previousLevel.index) {
//          _lastAlertLevels[gaugeId] = currentLevel;
//         }
//       }
//     }
//   }

//   void clearPopup() {
//     _newPopupToShow = null;
//     notifyListeners();
//   }

//   PopUpAlertLevel _getAlertLevel(double value, GaugeConfig config) {
//     if (value >= config.criticalValue) return PopUpAlertLevel.critical;
//     if (value >= config.warningValue) return PopUpAlertLevel.warning;
//     return PopUpAlertLevel.normal;
//   }
  
//   double _getValueForId(DeviceData data, String gaugeId) {
//     if (gaugeId.startsWith('analog_')) {
//       final index = int.tryParse(gaugeId.split('_')[1]) ?? 0;
//       return data.analogData.length > index ? data.analogData[index].toDouble() : 0.0;
//     }
//     if (gaugeId.startsWith('aux_')) {
//       final index = int.tryParse(gaugeId.split('_')[1]) ?? 0;
//       return data.auxData.length > index ? data.auxData[index].toDouble() : 0.0;
//     }
//     if (gaugeId.startsWith('can_')) {
//       switch (gaugeId) {
//         case 'can_coolant_temp': return data.canData.engineCoolantTemperature.toDouble();
//         default: return 0.0;
//       }
//     }
//     return 0.0;
//   }
// }

import 'package:flutter/material.dart';
import 'package:vtm_tablet/models/app_config.dart'; // Kendi projenizdeki doğru yolu belirtin
import 'package:vtm_tablet/models/device_data.dart'; // Kendi projenizdeki doğru yolu belirtin
import 'package:vtm_tablet/providers/data_provider.dart';

// Pop-up'ta gösterilecek veriyi tutan basit bir sınıf
class PopUpData {
  final String title;
  final String message;
  final PopUpAlertLevel level;
  PopUpData({required this.title, required this.message, required this.level});
}

// Bu enum, projenizde tek bir yerden yönetmek en iyisidir.
enum PopUpAlertLevel { normal, warning, critical }

class AlertProvider with ChangeNotifier {
   DataProvider _dataProvider;
   AppConfig _appConfig;
  
  // DEĞİŞİKLİK: Haritayı, sağlam ve değişmez olan 'gaugeId' ile anahtarlıyoruz.
  static const Map<String, Map<PopUpAlertLevel, String>> _popupTriggersById = {
    // --- GAUGE'LAR ---
    'can_coolant_temp': { // Motor Hararet
      PopUpAlertLevel.warning: 'Motor soğutma suyu sıcaklığı artıyor. Motoru rölantide çalıştırarak soğutun.',
      PopUpAlertLevel.critical: 'KRİTİK: Motor hararet yaptı! Kalıcı hasarı önlemek için motoru hemen durdurun.',
    },

    // --- İNDİKATÖRLER (aux_2 -> aux_7) ---
    'aux_2': { // Hidrolik Sıcaklık
      PopUpAlertLevel.critical: 'KRİTİK: Hidrolik yağ aşırı ısındı! Ciddi hasar riski. Sistemi soğuması için durdurun.',
    },
    'aux_3': { // Filtre 1
      PopUpAlertLevel.critical: 'KRİTİK: Filtre 1 tıkalı! Sistemin sağlığı için en kısa sürede değiştirin.',
    },
     'aux_4': { // Filtre 2
      PopUpAlertLevel.critical: 'KRİTİK: Filtre 2 tıkalı! Sistemin sağlığı için en kısa sürede değiştirin.',
    },
    'aux_5': { // Hidrolik Seviye
      PopUpAlertLevel.critical: 'KRİTİK: Hidrolik yağ seviyesi tehlikeli derecede düşük! Pompa hasarı riski. Derhal takviye yapın.',
    },
    'aux_6': { // Acil İstop
      PopUpAlertLevel.critical: 'ACİL İSTOP DEVREDE! Sistem durduruldu. Devam etmeden önce durumu kontrol edin.',
    },
    'aux_7': { // Morsed Muhafaza
      PopUpAlertLevel.critical: 'GÜVENLİK UYARISI: Morset muhafazası açık! Rotasyon başlamadan önce muhafazayı kapatın.',
    },
  };

  final Map<String, PopUpAlertLevel> _lastAlertLevels = {};
  PopUpData? _newPopupToShow;
  PopUpData? get newPopupToShow => _newPopupToShow;

  AlertProvider(this._dataProvider, this._appConfig) {
    // Listener'ı burada eklemeye devam ediyoruz.
    _dataProvider.addListener(_checkForNewPopups);
    _initializeAlertLevels();
  }
  @override
   void dispose() {
    _dataProvider.removeListener(_checkForNewPopups);
    super.dispose();
  }

  // YENİ: Provider'ı yeniden yaratmak yerine güncellemek için bu metodu kullanacağız.
  void updateDependencies(DataProvider newDataProvider, AppConfig newAppConfig) {
    // DataProvider örneği nadiren değişir ama kontrol etmek iyi bir pratiktir.
    if (_dataProvider != newDataProvider) {
      _dataProvider.removeListener(_checkForNewPopups);
      _dataProvider = newDataProvider;
      _dataProvider.addListener(_checkForNewPopups);
    }
    
    // AppConfig değişebilir, bu yüzden güncelliyoruz.
    _appConfig = newAppConfig;

    // Ayarlar değişmiş olabileceğinden, mevcut durum için alarmları tekrar kontrol et.
    _checkForNewPopups();
  }

  void _initializeAlertLevels() {
    // Sadece takip ettiğimiz alarmların başlangıç seviyesini ayarlıyoruz.
    for (var gaugeId in _popupTriggersById.keys) {
      _lastAlertLevels[gaugeId] = PopUpAlertLevel.normal;
    }
  }
  
  // Ana kontrol mantığı (daha basit ve performanslı hali)
  void _checkForNewPopups() {
    if (_newPopupToShow != null) return;

    // DEĞİŞİKLİK: Sadece takip listemizdeki alarmları kontrol ediyoruz.
    for (var entry in _popupTriggersById.entries) {
      final gaugeId = entry.key;
      final messages = entry.value;
      
      final gaugeConfig = _appConfig.gaugeConfigs[gaugeId];
      if (gaugeConfig == null) continue;

      final currentValue = _getValueForId(_dataProvider.deviceData, gaugeId);
      final currentLevel = _getAlertLevel(currentValue, gaugeConfig);
      final previousLevel = _lastAlertLevels[gaugeId] ?? PopUpAlertLevel.normal;

      if (currentLevel.index > previousLevel.index) {
        _newPopupToShow = PopUpData(
          title: gaugeConfig.label,
          message: '${messages[currentLevel] ?? messages.values.first}\n\nMevcut Değer: ${currentValue.toStringAsFixed(1)} ${gaugeConfig.unit}',
          level: currentLevel,
        );
        _lastAlertLevels[gaugeId] = currentLevel;
        
        notifyListeners();
        return; 
      }
      else if (currentLevel.index < previousLevel.index) {
         _lastAlertLevels[gaugeId] = currentLevel;
      }
    }
  }

  void clearPopup() {
    _newPopupToShow = null;
    notifyListeners();
  }

  PopUpAlertLevel _getAlertLevel(double value, GaugeConfig config) {
    if (value >= config.criticalValue) return PopUpAlertLevel.critical;
    if (value >= config.warningValue) return PopUpAlertLevel.warning;
    return PopUpAlertLevel.normal;
  }
  
  double _getValueForId(DeviceData data, String gaugeId) {
    if (gaugeId.startsWith('analog_')) {
      final index = int.tryParse(gaugeId.split('_')[1]) ?? 0;
      return data.analogData.length > index ? data.analogData[index].toDouble() : 0.0;
    }
    if (gaugeId.startsWith('aux_')) {
      final index = int.tryParse(gaugeId.split('_')[1]) ?? 0;
      return data.auxData.length > index ? data.auxData[index].toDouble() : 0.0;
    }
    if (gaugeId.startsWith('can_')) {
      switch (gaugeId) {
        case 'can_coolant_temp': return data.canData.engineCoolantTemperature.toDouble();
        default: return 0.0;
      }
    }
    return 0.0;
  }
}
