// lib/services/udp_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:udp/udp.dart';

class UdpService {
  UDP? _receiver;
  final _messageStreamController = StreamController<String>.broadcast();
  InternetAddress? _vtmIpAddress; // VTM-16'nın IP adresini tutacak değişken

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
          // 1. IP adresini yakala ve kaydet (Eğer değiştiyse veya ilk kez geliyorsa logla)
          if (_vtmIpAddress?.address != datagram.address.address) {
            _vtmIpAddress = datagram.address;
            print("📡 VTM-16 IP Adresi Yakalandı: ${_vtmIpAddress?.address}");
          }

          // 2. Mesajı çöz ve yayınla
          final message = utf8.decode(datagram.data);
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
      sender = await UDP.bind(Endpoint.any());
      
      Endpoint targetEndpoint;
      if (_vtmIpAddress != null) {
        // Eğer VTM-16'nın IP adresini biliyorsak, doğrudan ona (Unicast) gönder
        targetEndpoint = Endpoint.unicast(_vtmIpAddress!, port: Port(port));
        print("🎯 Nokta Atışı (Unicast): Rapor doğrudan ${_vtmIpAddress!.address}:$port hedefine gönderiliyor...");
      } else {
        // Eğer henüz IP yakalanamadıysa, mecburen ağdaki herkese (Broadcast) gönder
        targetEndpoint = Endpoint.broadcast(port: Port(port));
        print("📢 Broadcast: VTM-16 IP'si henüz bilinmiyor, ağdaki herkese gönderiliyor...");
      }
      
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
