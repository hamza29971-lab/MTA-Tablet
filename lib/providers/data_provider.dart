// // lib/providers/data_provider.dart
// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import '../models/device_data.dart';
// import '../services/udp_service.dart'; // UDP paketini değil, kendi servisimizi import ediyoruz

// enum ConnectionStatus { connected, disconnected }

// class DataProvider with ChangeNotifier {
//   // Artık UDP soketini burada tutmuyoruz
//   final UdpService _udpService;
//   StreamSubscription? _udpSubscription;

//   DeviceData _deviceData = DeviceData.initial();
//   bool _isListening = false;
//   Timer? _connectionTimer;
//   ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;

//   DeviceData get deviceData => _deviceData;
//   bool get isListening => _isListening;
//   ConnectionStatus get connectionStatus => _connectionStatus;

//   // Provider oluşturulurken UdpService'i alacak
//   DataProvider(this._udpService);

//   // Dinleyiciyi başlatma metodu değişti
//   void startListener() {
//     if (_isListening) return;

//     // Merkezi servisten gelen mesajları dinlemeye başla
//     _udpSubscription = _udpService.messageStream.listen(_handleIncomingMessage);
//     _isListening = true;
//     _resetConnectionTimer();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       // Bu kontrol, widget ağaçtan kaldırıldıysa hata vermesini engeller.
//       if (_isListening) {
//         notifyListeners();
//       }
//     });
//   }

//   // Gelen mesajları işleyen metot
//   void _handleIncomingMessage(String message) {
//     try {
//       final json = jsonDecode(message);
//       if (json.containsKey('data')) {
//         // Bağlantı durumunu güncelle ve zamanlayıcıyı sıfırla
//         if (_connectionStatus == ConnectionStatus.disconnected) {
//           _connectionStatus = ConnectionStatus.connected;
//           notifyListeners();
//         }
//         _resetConnectionTimer();

//         // Veriyi işle (Equatable optimizasyonu ile)
//         final dataObject = json['data'];
//         final newDeviceData = DeviceData.fromJson(dataObject);
//         if (newDeviceData != _deviceData) {
//           _deviceData = newDeviceData;
//           notifyListeners();
//         }
//       }
//     } catch (e) {
//       // Bu mesaj DeviceData değil, görmezden gel.
//     }
//   }

//     void _resetConnectionTimer() {
//     _connectionTimer?.cancel();
//     _connectionTimer = Timer(const Duration(seconds: 3), () {
//       // Eğer bu süre sonunda hala bağlantı aktifse, bağlantıyı kesik olarak işaretle
//       if (_connectionStatus == ConnectionStatus.connected) {
//         _connectionStatus = ConnectionStatus.disconnected;
//         notifyListeners();
//       }
//     });
//   }

//   void stopListener() {
//     _udpSubscription?.cancel();
//     _connectionTimer?.cancel();
//     _isListening = false;
//     _connectionStatus = ConnectionStatus.disconnected;
//     notifyListeners();
//   }

//   @override
//   void dispose() {
//     stopListener();
//     super.dispose();
//   }
// }
// lib/providers/data_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/device_data.dart';
import '../services/udp_service.dart';

// Bağlantı durumunu temsil eden enum
enum ConnectionStatus { connected, disconnected }

class DataProvider with ChangeNotifier {
  final UdpService _udpService;
  StreamSubscription? _udpSubscription;

  DeviceData _deviceData = DeviceData.initial();
  bool _isListening = false;
  Timer? _connectionTimer;
  // Başlangıç durumu kesin olarak disconnected
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;

  DeviceData get deviceData => _deviceData;
  bool get isListening => _isListening;
  ConnectionStatus get connectionStatus => _connectionStatus;

  // --- OPERATÖR BİLGİLERİ ---
  String? _operatorName;
  String? _registrationNo;
  String? _wellNo;
  String? _teamName;
  String? _bolgeAdi;
  double? _teslimAlinanMetraj;
  bool _isSystemLocked = false; // System is never locked

  String? get operatorName => _operatorName;
  String? get registrationNo => _registrationNo;
  String? get wellNo => _wellNo;
  String? get teamName => _teamName;
  String? get bolgeAdi => _bolgeAdi;
  double? get teslimAlinanMetraj => _teslimAlinanMetraj;
  bool get isSystemLocked => _isSystemLocked;

  void setOperatorInfo(
    String name,
    String regNo,
    String well, {
    String teamName = '',
    String bolgeAdi = '',
    double teslimAlinanMetraj = 0.0,
  }) {
    _operatorName = name;
    _registrationNo = regNo;
    _wellNo = well;
    _teamName = teamName;
    _bolgeAdi = bolgeAdi;
    _teslimAlinanMetraj = teslimAlinanMetraj;
    _isSystemLocked = false;
    notifyListeners();
  }

  void clearOperatorInfo() {
    _operatorName = null;
    _registrationNo = null;
    _wellNo = null;
    _teamName = null;
    _bolgeAdi = null;
    _teslimAlinanMetraj = null;
    _isSystemLocked = false;
    notifyListeners();
  }

  // --- MERKEZİ TEST KİLİDİ ---
  String? _activeTestName;
  String? get activeTestName => _activeTestName;

  void startTest(String testName) {
    _activeTestName = testName;
    notifyListeners();
  }

  void stopTest() {
    _activeTestName = null;
    notifyListeners();
  }

  // Uygulama arka planda mı? (arka plandaysa testleri durdurma)
  bool _isAppInBackground = false;
  bool get isAppInBackground => _isAppInBackground;
  void setAppBackground(bool value) {
    _isAppInBackground = value;
  }

  bool isAnyOtherTestRunning(String myTestName) {
    return _activeTestName != null && _activeTestName != myTestName;
  }
  // ---------------------------

  DataProvider(this._udpService);

  void startListener() {
    if (_isListening) return;

    _udpSubscription = _udpService.messageStream.listen(_handleIncomingMessage);
    _isListening = true;

    // ZAMANLAYICIYI BURADA BAŞLATMIYORUZ. Sadece ilk mesaj geldiğinde başlayacak.

    print("✅ DataProvider, merkezi dinleyiciye abone oldu.");

    // Başlangıç durumunun kesin olarak 'disconnected' olduğunu arayüze bildir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isListening) {
        // Bu, ilk build'de durumun kırmızı olmasını garantiler.
        _connectionStatus = ConnectionStatus.disconnected;
        notifyListeners();
      }
    });
  }

  void _handleIncomingMessage(String message) {
    try {
      final json = jsonDecode(message);
      if (json.containsKey('data')) {
        // 1. Mesaj geldi, zamanlayıcıyı başlat/sıfırla
        _resetConnectionTimer();

        // 2. Bağlantı durumunu 'connected' yap (eğer zaten değilse)
        if (_connectionStatus == ConnectionStatus.disconnected) {
          _connectionStatus = ConnectionStatus.connected;
        }

        // 3. Veriyi işle - her zaman güncelle (Equatable karşılaştırması kaldırıldı)
        final dataObject = json['data'];
        final newDeviceData = DeviceData.fromJson(dataObject);
        _deviceData = newDeviceData;
        notifyListeners();
      }
    } catch (e) {
      print("❌ DataProvider parse hatası: $e");
    }
  }

  void _resetConnectionTimer() {
    _connectionTimer?.cancel();
    _connectionTimer = Timer(const Duration(seconds: 5), () {
      // Eğer bu süre sonunda hala bağlantı aktifse, bağlantıyı kesik olarak işaretle
      print("!!! Bağlantı kesildi: 5 saniyedir veri alınamadı. !!!");

      _deviceData = DeviceData.initial();
      _connectionStatus = ConnectionStatus.disconnected;
      notifyListeners();
    });
  }

  void stopListener() {
    _udpSubscription?.cancel();
    _connectionTimer?.cancel();
    _isListening = false;

    _deviceData = DeviceData.initial();
    _connectionStatus = ConnectionStatus.disconnected;
    print("DataProvider abonelikten ayrıldı.");
    notifyListeners();
  }

  void sendUdpReport(Map<String, dynamic> payloadMap) {
    try {
      final jsonStr = jsonEncode(payloadMap);
      _udpService.sendReport(jsonStr); // varsayılan olarak port 5006
    } catch (e) {
      print("❌ sendUdpReport hatası: $e");
    }
  }

  @override
  void dispose() {
    stopListener();
    super.dispose();
  }
}
