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
  final String? kampAdi;
  final double? teslimAlinanMetraj;
  
  // Ana giriş ekranından alınan yeni alanlar
  final double? tijAdedi;
  final double? morsetUstu;

  ReportData({
    required this.operatorName,
    required this.kuyuName,
    required this.operatorNumber,
    required this.teamName,
    required this.faultText,
    required this.faultMeter,
    this.bolgeAdi,
    this.kampAdi,
    this.teslimAlinanMetraj,
    this.tijAdedi,
    this.morsetUstu,
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
    if (kampAdi != null) {
      map['camp_name'] = kampAdi;
    }
    map['fault_meter'] = faultMeter;
    // "Teslim Alınan Metraj" → fault_meter'ın hemen yanına (altına)
    if (teslimAlinanMetraj != null) {
      map['deliv_m'] = teslimAlinanMetraj;
    }
    
    // Yeni eklenen alanların MQTT mappingi (Vardiya verileriyle karışmaması için deliv_ öneki)
    if (tijAdedi != null) {
      map['deliv_rod_cnt'] = tijAdedi;
    }
    if (morsetUstu != null) {
      map['deliv_mors_wat'] = morsetUstu;
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

