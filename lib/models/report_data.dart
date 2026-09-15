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
  // Sadece Arıza Raporu (report_tab) için opsiyonel ekstra alanlar
  final String? bolgeAdi;
  final double? teslimAlinanMetraj;

  ReportData({
    required this.operatorName,
    required this.kuyuName,
    required this.operatorNumber,
    required this.teamName,
    required this.faultText,
    required this.faultMeter,
    this.bolgeAdi,
    this.teslimAlinanMetraj,
  });

  // Nesneyi Map'e çevirir (MQTT için kullanılır)
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'operator_name': operatorName,
      'kuyu_name': kuyuName,
      'operator_number': operatorNumber,
      'team_name': teamName,
      'fault_text': faultText,
    };
    // "Bölge Adı" → fault_text'in hemen yanına (altına)
    if (bolgeAdi != null) {
      map['region'] = bolgeAdi;
    }
    map['fault_meter'] = faultMeter;
    // "Teslim Alınan Metraj" → fault_meter'ın hemen yanına (altına)
    if (teslimAlinanMetraj != null) {
      map['deliv_m'] = teslimAlinanMetraj;
    }
    return map;
  }

  // Nesneyi JSON string'ine çevirir (UDP için kullanılır)
  String toJson() {
    return jsonEncode(toMap());
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

