// lib/providers/wakelock_provider.dart

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class WakelockProvider with ChangeNotifier, WidgetsBindingObserver {
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  Timer? _recheckTimer;
  
  bool? _isWakelockActive;

  bool get isWakelockActive => _isWakelockActive ?? false;

  WakelockProvider() {
    _init();
  }

  Future<void> _init() async {
    WidgetsBinding.instance.addObserver(this);
    await _forceCheckBatteryState();
    _batteryStateSubscription = _battery.onBatteryStateChanged.listen(_handleBatteryStateChange);

    // ✅ GÜVENLİK KONTROLÜ: Başlangıçtan 1 saniye sonra durumu tekrar kontrol et.
    // Bu, uygulamanın ilk açılışında durumun yanlış okunması sorununu çözer.
    Timer(const Duration(seconds: 1), _forceCheckBatteryState);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      print("Uygulama uyandı (resumed). Şarj durumu tekrar kontrol ediliyor...");
      _forceCheckBatteryState();
    }
  }

  Future<void> _forceCheckBatteryState() async {
    final currentState = await _battery.batteryState;
    await _handleBatteryStateChange(currentState);
  }

  Future<void> _handleBatteryStateChange(BatteryState state) async {
    final bool isPluggedIn = state != BatteryState.discharging;
    
    if (isPluggedIn != _isWakelockActive) {
      _isWakelockActive = isPluggedIn;

      if (isPluggedIn) {
        _recheckTimer?.cancel();
        await WakelockPlus.enable();
        print("🔌 Cihaz güç kaynağına bağlı. Wakelock Aktif Edildi.");
      } else {
        await WakelockPlus.disable();
        _recheckTimer = Timer.periodic(const Duration(seconds: 2), (_) => _forceCheckBatteryState());
        print("🔌 Cihaz güç kaynağından çekildi. Wakelock Devre Dışı Bırakıldı.");
      }
      
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _batteryStateSubscription?.cancel();
    _recheckTimer?.cancel();
    if (_isWakelockActive ?? false) {
      WakelockPlus.disable();
    }
    super.dispose();
  }
}
