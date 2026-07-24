// lib/services/udp_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:udp/udp.dart';

class UdpService {
  UDP? _receiver;
  final _messageStreamController = StreamController<String>.broadcast();

  // Provider'ların dinleyebileceği yayın akışı
  Stream<String> get messageStream => _messageStreamController.stream;

  // 5005 portunu dinlemeyi başlat
  Future<void> startListener({int port = 5005}) async {
    if (_receiver != null) return;
    try {
      _receiver = await UDP.bind(Endpoint.any(port: Port(port)));
      print("✅ Merkezi UDP Dinleyici $port portunda başlatıldı.");

      _receiver?.asStream().listen((Datagram? datagram) {
        if (datagram != null) {
          final message = utf8.decode(datagram.data);
          // Gelen ham mesajı tüm dinleyicilere yayınla
          _messageStreamController.add(message);
        }
      });
    } catch (e) {
      print("!!! Merkezi UDP Dinleyici başlatılamadı: $e");
    }
  }

  // Raporu 5006 portuna gönder
  Future<void> sendReport(String jsonReport, {int port = 5006}) async {
    UDP? sender; // ✅ DEĞİŞİKLİK: sender'ı try bloğunun dışında tanımla
    try {
      // Gönderim için geçici bir UDP soketi oluştur
      sender = await UDP.bind(Endpoint.any()); // Değişkeni ata
      final targetEndpoint = Endpoint.broadcast(port: Port(port));
      
      await sender.send(utf8.encode(jsonReport), targetEndpoint);
      print("✅ Rapor $port portuna gönderildi.");
    } catch (e) {
      print("!!! Rapor gönderilemedi: $e");
      // İsteğe bağlı: Hatayı yeniden fırlatarak üst katmanın haberdar olmasını sağlayabilirsiniz
      // throw e; 
    } finally {
      // ✅ DEĞİŞİKLİK: finally bloğu eklendi.
      // Bu blok, hata olsa da olmasa da çalışır.
      // sender null değilse, yani başarılı bir şekilde oluşturulduysa, kapat.
      if (sender != null) {
        print("🚪 Gönderici UDP soketi kapatılıyor.");
        sender.close();
      }
    }
  }

  void dispose() {
    _receiver?.close();
    _messageStreamController.close();
  }
}
