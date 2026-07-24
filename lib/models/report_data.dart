// lib/models/report_data.dart
import 'dart:convert';

// Gönderilecek Rapor Modeli
class ReportData {
  final String operatorName;
  final String kuyuName;
  final String operatorNumber;
  final String teamName;
  final String faultText;
  final double faultMeter; 

  ReportData({
    required this.operatorName,
    required this.kuyuName,
    required this.operatorNumber,
    required this.teamName,
    required this.faultText,
    required this.faultMeter,
  });

  // Nesneyi JSON string'ine çevirir
  String toJson() {
    return jsonEncode({
      'operator_name': operatorName,
      'kuyu_name': kuyuName,
      'operator_number': operatorNumber,
      'team_name': teamName,
      'fault_text': faultText,
      'fault_meter':faultMeter
    });
  }
}

// Alınacak Onay (Acknowledgement) Modeli
class AckData {
  final String ackStatus;

  AckData({required this.ackStatus});

  // Gelen JSON'dan nesne oluşturur
  factory AckData.fromJson(Map<String, dynamic> json) {
    return AckData(
      ackStatus: json['ack_status'] ?? 'Bilinmeyen durum',
    );
  }
}
