# tablet_threaded_final.py
# Nihai Sürüm: Thread'li yapı, çift yönlü veri alışverişi ve maksimum detaylı açıklamalar.

import socket
import json
import time
import threading

class Config:
    """Yapılandırma ayarları."""
    RECV_PORT = 5005
    DEVICE_REPLY_PORT = 5006
    LISTEN_IP = ""
    BUFFER_SIZE = 8192
    SECRET_KEY = "HoytekDrillingProject_SecretKey_2025"
    OFFLINE_TIMEOUT = 15

# Tabletin, keşif sırasında cihaza göndereceği kendi tanıtım verisi
TABLET_DATA = {
    "operator_name": "Ömer ALMACI",
    "operator_no": 1574578,
    "takim_ismi": "Takim_X",
    "cihaz_durumu": "Test modunda, veriye hazır.",
    "notes": f"Bağlantı zamanı: {time.ctime()}"
}

# --- Helper Fonksiyonlar ---

def create_response_packet(packet_type, data=None):
    """Cihaza gönderilecek standart yanıt paketleri oluşturur."""
    packet = { "type": packet_type, "api_key": Config.SECRET_KEY }
    if data:
        packet.update(data)
    return json.dumps(packet).encode('utf-8')

def print_pretty_json(header, data):
    """Bir Python sözlüğünü okunaklı JSON formatında konsola basar."""
    print(f"\n{header}")
    print("==================================================")
    print(json.dumps(data, indent=4, ensure_ascii=False))
    print("==================================================")

# --- Ana İşlevsellik (Thread İçinde Çalışacak) ---

def tablet_logic_thread(stop_event):
    """
    Bu fonksiyon, tabletin tüm ağ mantığını içerir ve ayrı bir thread'de çalışır.
    'stop_event' parametresi, ana programdan gelen durdurma sinyalini dinler.
    """
    # Soketlerin kurulumu
    recv_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    recv_sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    recv_sock.bind((Config.LISTEN_IP, Config.RECV_PORT))
    recv_sock.settimeout(1.0) # 1 saniyelik timeout, stop_event'i kontrol etme imkanı verir
    
    send_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    
    connected_devices = {} # {'ip_adresi': son_görülme_zamanı}
    
    while not stop_event.is_set():
        try:
            # 1. Cihazlardan Gelen Paketleri Dinle
            try:
                data, addr = recv_sock.recvfrom(Config.BUFFER_SIZE)
                sender_ip = addr[0]
                now = time.time()

                if sender_ip not in connected_devices:
                    print(f"\n[BAĞLANTI ✓] Yeni cihaz bağlandı: {sender_ip}")
                
                connected_devices[sender_ip] = now
                packet = json.loads(data.decode('utf-8'))
                
                if packet.get("api_key") != Config.SECRET_KEY: continue
                
                packet_type = packet.get("type", "unknown")
                
                # A. Keşif Paketi Geldiyse:
                if packet_type == "discovery":
                    print(f"\n[KEŞİF <--- {sender_ip}] Cihaz kendini tanıttı. Yanıt gönderiliyor.")
                    # İçinde kendi verimizi de barındıran bir onay paketi gönder
                    response = create_response_packet("discovery_ack", data=TABLET_DATA)
                    send_sock.sendto(response, (sender_ip, Config.DEVICE_REPLY_PORT))
                
                # B. Veri Paketi Geldiyse:
                elif packet_type == "data":
                    packet_id = packet.get("packet_id")
                    device_data = packet.get("data")
                    if packet_id and device_data:
                        # Gelen cihaz verisini detaylıca yazdır
                        print_pretty_json(f"--- GELEN VERİ <--- {sender_ip} (Paket #{packet_id[:8]}) ---", device_data)
                        
                        # Bu veriyi aldığımıza dair onay paketi gönder
                        response = create_response_packet("data_ack", {"acked_id": packet_id})
                        send_sock.sendto(response, (sender_ip, Config.DEVICE_REPLY_PORT))

            except socket.timeout:
                # Timeout olması normal, bu döngünün devam etmesini ve offline kontrolü yapmasını sağlar.
                pass
            except (json.JSONDecodeError, KeyError):
                print("\n[UYARI] Bozuk veya geçersiz bir paket alındı. Yoksayılıyor.")
                continue
            
            # 2. Offline Durum Kontrolü
            now = time.time()
            offline_devices = [ip for ip, last_seen in connected_devices.items() if now - last_seen > Config.OFFLINE_TIMEOUT]
            for ip in offline_devices:
                print(f"\n[BAĞLANTI X] {ip} cihazının bağlantısı koptu! ({Config.OFFLINE_TIMEOUT}s)")
                del connected_devices[ip]
        
        except Exception as e:
            print(f"Tablet thread'inde beklenmedik bir hata: {e}")
            time.sleep(2)

    print("\nDurdurma sinyali alındı, tablet thread'i sonlandırılıyor.")
    recv_sock.close()
    send_sock.close()


# --- Ana Program Başlangıcı ---

if __name__ == "__main__":
    print("--- Tablet Test Yazılımı (Thread'li Final v3) ---")

    stop_event = threading.Event()
    
    # Ana mantığı içeren thread'i oluştur ve başlat
    tablet_thread = threading.Thread(target=tablet_logic_thread, args=(stop_event,), name="TabletLogicThread")
    tablet_thread.start()
    
    print("Tablet ağ dinleme thread'i arka planda çalışmaya başladı.")
    print("Programı durdurmak için Ctrl+C'ye basın.")
    
    try:
        # Ana thread, ağ thread'i çalışırken burada bekler.
        tablet_thread.join()
    except KeyboardInterrupt:
        print("\nCtrl+C algılandı. Program güvenli bir şekilde kapatılıyor...")
        stop_event.set() # Thread'e durma sinyali gönder
        tablet_thread.join() # Thread'in işini bitirip kapanmasını bekle
        
    print("Program başarıyla sonlandırıldı.")