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
import 'package:shared_preferences/shared_preferences.dart';

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
  String? _kampAdi;
  double? _teslimAlinanMetraj;
  double? _tijAdedi;
  double? _morsetUstu;
  bool _isSystemLocked = true; // Added for start screen locking

  String? get operatorName => _operatorName;
  String? get registrationNo => _registrationNo;
  String? get wellNo => _wellNo;
  String? get teamName => _teamName;
  String? get bolgeAdi => _bolgeAdi;
  String? get kampAdi => _kampAdi;
  double? get teslimAlinanMetraj => _teslimAlinanMetraj;
  double? get tijAdedi => _tijAdedi;
  double? get morsetUstu => _morsetUstu;
  bool get isSystemLocked => _isSystemLocked;

  // Provider oluşturulurken UdpService'i alacak
  DataProvider(this._udpService) {
    _loadOperatorInfo();
  }

  Future<void> _loadOperatorInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _operatorName = prefs.getString('operatorName');
    _registrationNo = prefs.getString('registrationNo');
    _wellNo = prefs.getString('wellNo');
    _teamName = prefs.getString('teamName');
    _bolgeAdi = prefs.getString('bolgeAdi');
    _kampAdi = prefs.getString('kampAdi');
    _teslimAlinanMetraj = prefs.getDouble('teslimAlinanMetraj');
    _tijAdedi = prefs.getDouble('tijAdedi');
    _morsetUstu = prefs.getDouble('morsetUstu');
    if (_operatorName != null && _operatorName!.isNotEmpty) {
      _isSystemLocked = false;
    }
    notifyListeners();
  }

  void setOperatorInfo(
    String name,
    String regNo,
    String well, {
    String teamName = '',
    String bolgeAdi = '',
    String kampAdi = '',
    double teslimAlinanMetraj = 0.0,
    double tijAdedi = 0.0,
    double morsetUstu = 0.0,
  }) async {
    _operatorName = name;
    _registrationNo = regNo;
    _wellNo = well;
    _teamName = teamName;
    _bolgeAdi = bolgeAdi;
    _kampAdi = kampAdi;
    _teslimAlinanMetraj = teslimAlinanMetraj;
    _tijAdedi = tijAdedi;
    _morsetUstu = morsetUstu;
    _isSystemLocked = false;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('operatorName', name);
    await prefs.setString('registrationNo', regNo);
    await prefs.setString('wellNo', well);
    await prefs.setString('teamName', teamName);
    await prefs.setString('bolgeAdi', bolgeAdi);
    await prefs.setString('kampAdi', kampAdi);
    await prefs.setDouble('teslimAlinanMetraj', teslimAlinanMetraj);
    await prefs.setDouble('tijAdedi', tijAdedi);
    await prefs.setDouble('morsetUstu', morsetUstu);
  }

  void clearOperatorInfo() async {
    _operatorName = null;
    _registrationNo = null;
    _wellNo = null;
    _teamName = null;
    _bolgeAdi = null;
    _kampAdi = null;
    _teslimAlinanMetraj = null;
    _tijAdedi = null;
    _morsetUstu = null;
    _isSystemLocked = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('operatorName');
    await prefs.remove('registrationNo');
    await prefs.remove('wellNo');
    await prefs.remove('teamName');
    await prefs.remove('bolgeAdi');
    await prefs.remove('kampAdi');
    await prefs.remove('teslimAlinanMetraj');
    await prefs.remove('tijAdedi');
    await prefs.remove('morsetUstu');
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
