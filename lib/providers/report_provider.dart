// lib/providers/report_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/report_data.dart';
import '../services/udp_service.dart';
import '../services/mqtt_service.dart';

enum ReportStatus { initial, sending, success, error, timeout }

class ReportProvider with ChangeNotifier {
  final UdpService _udpService;
  final MqttService _mqttService;
  StreamSubscription? _udpSubscription;

  ReportStatus _status = ReportStatus.initial;
  String _ackMessage = '';
  Timer? _ackTimer;

  ReportStatus get status => _status;
  String get ackMessage => _ackMessage;

  ReportProvider(this._udpService, this._mqttService) {
    // Merkezi UDP servisinden gelen mesajları dinle
    _udpSubscription = _udpService.messageStream.listen(_handleIncomingMessage);
  }

  // Gelen mesajları işleyen metot
  void _handleIncomingMessage(String message) {
    try {
      // Gelen mesajı AckData olarak parse etmeyi dene
      final json = jsonDecode(message);
      if (json.containsKey('ack_status')) {
        // Sadece rapor gönderim aşamasındayken (Sending) gelen onayları kabul et!
        if (_status == ReportStatus.sending) {
          final ack = AckData.fromJson(json);
          print("✅ Onay mesajı alındı: ${ack.ackStatus}");
          _ackTimer?.cancel(); // Zaman aşımı sayacını iptal et
          _status = ReportStatus.success;
          _ackMessage = ack.ackStatus;
          notifyListeners();
        }
      }
      // Eğer 'ack_status' yoksa veya status sending değilse, görmezden gel.
    } catch (e) {
      // Bu mesaj AckData değil, görmezden gel.
    }
  }

  // Rapor gönderme işlemini başlatan metot (ReportData modeli ile)
  Future<void> sendReport(ReportData report) async {
    await _sendRawJson(report.toJson());
  }

  // Genel JSON verisi gönderme ve ACK bekleme metodu (Karot, Vardiya vs. için)
  Future<void> _sendRawJson(String jsonPayload) async {
    _status = ReportStatus.sending;
    _ackMessage = '';
    notifyListeners();

    // UDP ile kutuya (VTM-16) gönder ve onay bekle
    await _udpService.sendReport(jsonPayload);

    // 10 saniye içinde onay gelmezse zaman aşımına uğrat
    _ackTimer = Timer(const Duration(seconds: 10), () {
      if (_status == ReportStatus.sending) {
        _status = ReportStatus.timeout;
        _ackMessage = 'Kutudan cevap alınamadı (Zaman aşımı).';
        notifyListeners();
      }
    });
  }

  // Formu sıfırlamak için
  void resetStatus() {
    _status = ReportStatus.initial;
    _ackMessage = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _udpSubscription?.cancel();
    _ackTimer?.cancel();
    super.dispose();
  }
}
