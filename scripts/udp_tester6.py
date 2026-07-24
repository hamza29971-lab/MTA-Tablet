# cihaz_birlesik_final.py
# İKİ YAZILIMIN BİRLEŞTİRİLMİŞ VE İSTENENLERE GÖRE DÜZENLENMİŞ HALİDİR.
#
# TEMEL İŞLEVLER:
# 1. Gelişmiş simülatör verilerini sürekli olarak ağa yayınlar (broadcast).
# 2. 5006 portundan gelen mesajları dinler ve bu mesajlara yanıt gönderir.
# 3. Heartbeat, data ACK ve API Key gibi mekanizmalar kaldırılmıştır.

import socket
import json
import time
import sys
import uuid
import threading
import random
import copy

try:
    import netifaces
except ImportError:
    print("[BİLGİ] 'netifaces' kütüphanesi kurulu değil. Varsayılan ağ arayüzü kullanılacak.")
    netifaces = None

class Config:
    """Tüm yapılandırma ayarlarını merkezi olarak yönetir."""
    TABLET_RECV_PORT: int = 5005         # Veri GÖNDERİLECEK hedef port / Yanıtların gönderileceği port
    DEVICE_RECV_PORT: int = 5006         # Bu yazılımın mesaj DİNLEYECEĞİ port
    TARGET_INTERFACE: str = "ens33"      # Yayın yapılacak ağ arayüzü (Boş bırakılırsa varsayılan)
    BROADCAST_IP: str = '255.255.255.255' # Yayın yapılacak IP adresi
    BUFFER_SIZE: int = 8192
    DATA_SEND_INTERVAL: float = 1.0      # Saniye cinsinden veri gönderme sıklığı
    SOCKET_TIMEOUT: float = 0.5          # Dinleyici soketin bekleme süresi (döngünün kilitlenmemesi için)

# 1. Yazılımdan alınan gelişmiş veri şablonu
DEVICE_DATA_TEMPLATE = {
    "box_id": 6,
    "can_data": {"CAN_Manufacturer_Code": 0, "CAN_Battery_Potential": 24.0, "CAN_Engine_Speed": 800, "CAN_Engine_Oil_Pressure": 0, "CAN_Engine_Coolant_Temperature": 0, "CAN_Engine_Oil_Temperature": 0, "CAN_Engine_Fuel_Temperature": 0, "CAN_Fuel_Level_1": 0, "CAN_Fuel_Level_2": 0, "CAN_Engine_Total_Hours_Of_Operation": 69},
    "can_dtc_data": {"flash_lamp_amber_warning": 1, "flash_lamp_malfunction_indicator": 1, "flash_lamp_protect_lamp": 1, "flash_lamp_red_stop": 1, "lamp_status_amber_warning": 1, "lamp_status_malfunction_indicator": 1, "lamp_status_protect_lamp": 1, "lamp_status_red_stop": 1, "dtc_count": 0, "dtcs": []},
    "analog_data": [0] * 16,
    "aux_data": [0] * 16,
    "sensor_data": {"is_imu_connected": True, "vehicle_heading": 0.0, "vehicle_roll": 0.0, "vehicle_pitch": 0.0, "tower_roll": 0.0, "tower_pitch": 0.0},
    "sys_info": {"ram_usage": "0M/0M", "disk_usage": "0.00G/0.00G", "log_file_count": 0, "error_code": 0, "error_file_size": "0.00K", "max_raspi_temp": 0, "max_mcu_temp": 0, "max_ambi_temp": 0}
}

class DeviceSimulator:
    """1. Yazılımdan alınan gelişmiş simülatör. Verileri zamanla mantıksal olarak değiştirir."""
    def __init__(self, initial_data_template: dict):
        self._data = copy.deepcopy(initial_data_template)
        self._engine_hours = self._data['can_data'].get('CAN_Engine_Total_Hours_Of_Operation', 69)
        self._heading = self._data['sensor_data'].get('vehicle_heading', 0.0)
        self._last_update_time = time.time()

    def update(self):
        """Simülasyonun durumunu bir sonraki zaman adımı için günceller."""
        now = time.time()
        time_delta = now - self._last_update_time
        if time_delta < 1.0: return # Saniyede en fazla bir kez güncelle

        self._engine_hours += time_delta / 3600.0
        self._heading = (self._heading + random.uniform(-0.5, 1.0) * time_delta) % 360
        can = self._data['can_data']
        can['CAN_Battery_Potential'] = round(24.5 + random.uniform(-0.3, 0.3), 2)
        can['CAN_Engine_Speed'] = random.randint(750, 850)
        can['CAN_Engine_Coolant_Temperature'] = 90 + random.randint(-2, 2)
        self._data['analog_data'] = [random.randint(0, 300) for _ in range(16)]
        self._data['aux_data'] = [random.randint(0, 1500) for _ in range(16)]
        self._data['sensor_data']['vehicle_heading'] = round(self._heading, 2)
        self._data['sensor_data']['vehicle_roll'] = round(random.uniform(-2.5, 2.5), 2)
        self._data['sensor_data']['vehicle_pitch'] = round(random.uniform(-1.5, 1.5), 2)
        self._last_update_time = now

    def get_data_payload(self) -> dict:
        """Simülatörün güncel verisini döndürür."""
        self._data['can_data']['CAN_Engine_Total_Hours_Of_Operation'] = round(self._engine_hours, 4)
        return self._data

def get_interface_ip(interface_name: str) -> str:
    """Belirtilen ağ arayüzünün IP adresini bulur."""
    if not netifaces or not interface_name: return ""
    try: return netifaces.ifaddresses(interface_name)[netifaces.AF_INET][0]['addr']
    except (Exception): return ""

def summarize_data_packet(data: dict) -> str:
    """Veri paketini özetleyen kısa bir metin oluşturur."""
    try:
        box_id = data.get('box_id', 'N/A')
        engine_speed = data.get('can_data', {}).get('CAN_Engine_Speed', 'N/A')
        heading = data.get('sensor_data', {}).get('vehicle_heading', 'N/A')
        return f"Özet: {{BoxID: {box_id}, MotorHızı: {engine_speed}, Yön: {heading:.1f}°}}"
    except Exception: return "Özet oluşturulamadı."

def create_packet(packet_type: str, data_payload: dict = None) -> bytes:
    """Gönderilecek paketi oluşturur (API Key olmadan)."""
    packet = {"type": packet_type, "packet_id": str(uuid.uuid4())}
    if data_payload: packet['data'] = data_payload
    return json.dumps(packet).encode('utf-8')

# --- YENİ THREAD FONKSİYONLARI ---

def veri_gonderici_thread(stop_event: threading.Event, sock: socket.socket, simulator: DeviceSimulator):
    """
    Sürekli olarak simülatör verilerini ağa yayınlayan thread.
    1. Yazılımın 'run_simple_mode' fonksiyonundan uyarlanmıştır.
    """
    print("✅ Veri Gönderici thread'i başlatıldı.")
    last_sent_time = 0
    while not stop_event.is_set():
        simulator.update()
        now = time.time()
        if now - last_sent_time > Config.DATA_SEND_INTERVAL:
            dynamic_data = simulator.get_data_payload()
            packet = create_packet("data", data_payload=dynamic_data)
            
            # Veriyi broadcast olarak gönder
            try:
                sock.sendto(packet, (Config.BROADCAST_IP, Config.TABLET_RECV_PORT))
                print(f"\r[GİDEN VERİ ➡️] Broadcast -> {Config.BROADCAST_IP}:{Config.TABLET_RECV_PORT} | {summarize_data_packet(dynamic_data)}", end="")
            except Exception as e:
                print(f"\n[HATA] Veri gönderilemedi: {e}")
                
            last_sent_time = now
        time.sleep(0.1) # CPU kullanımını düşürmek için kısa bir bekleme
    print("\n⏹️ Veri Gönderici thread'i durduruldu.")

def mesaj_dinleyici_thread(stop_event: threading.Event, sock: socket.socket):
    """
    5006 portunu dinler ve gelen mesajlara yanıt veren thread.
    2. Yazılımın 'dinleyici_thread' fonksiyonundan uyarlanmıştır.
    """
    print(f"✅ Mesaj Dinleyici thread'i başlatıldı. Port {Config.DEVICE_RECV_PORT} dinleniyor...")
    while not stop_event.is_set():
        try:
            data, addr = sock.recvfrom(Config.BUFFER_SIZE)
            sender_ip = addr[0]
            
            print(f"\n[GELEN MESAJ ⬅️] {sender_ip}:{addr[1]} adresinden bir mesaj alındı.")
            
            # Gelen mesajın içeriğini yazdırma (isteğe bağlı)
            try:
                gelen_mesaj = json.loads(data.decode('utf-8'))
                # print("Gelen Mesaj İçeriği:", json.dumps(gelen_mesaj, indent=2))
            except json.JSONDecodeError:
                print("[UYARI] Gelen mesaj JSON formatında değil, yine de yanıt veriliyor.")

            # 2. Yazılımdaki gibi rastgele başarılı/başarısız yanıt oluştur
            is_success = random.choice([True, False])
            if is_success:
                yanit_mesaji = {"ack_status": "Rapor başarıyla sunucuya gönderildi."}
            else:
                yanit_mesaji = {"ack_status": "Sunucuya ulaşılamadı. Rapor yerel olarak kaydedildi."}
            
            yanit_paketi = json.dumps(yanit_mesaji).encode('utf-8')
            
            # Yanıtı, mesajı gönderen IP'nin TABLET_RECV_PORT'una (5005) gönder
            sock.sendto(yanit_paketi, (sender_ip, Config.TABLET_RECV_PORT))
            print(f"[GİDEN YANIT ➡️] {sender_ip}:{Config.TABLET_RECV_PORT} adresine yanıt gönderildi: '{yanit_mesaji['ack_status']}'")

        except socket.timeout:
            # Timeout olması normaldir, bu sayede while döngüsü stop_event'i kontrol edebilir.
            continue
        except Exception as e:
            print(f"\n[HATA] Dinleyici thread'inde beklenmedik hata: {e}")
    print("⏹️ Mesaj Dinleyici thread'i durduruldu.")

if __name__ == "__main__":
    print("-" * 60)
    print("--- Birleşik Cihaz Simülatörü ---")
    print("MOD: Sürekli Veri Yayını & Gelen Mesajlara Yanıt Verme")
    print(f"Veri Yayın Portu\t: {Config.TABLET_RECV_PORT}")
    print(f"Mesaj Dinleme Portu\t: {Config.DEVICE_RECV_PORT}")
    print("-" * 60)

    stop_event = threading.Event()
    simulator = DeviceSimulator(DEVICE_DATA_TEMPLATE)
    
    # Soketleri kur
    send_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    recv_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

    try:
        # Gönderici soketi broadcast için ayarla
        send_sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        bind_ip = get_interface_ip(Config.TARGET_INTERFACE)
        if bind_ip:
            send_sock.bind((bind_ip, 0)) # Belirli bir arayüzden göndermek için
            print(f"[SOKET ✓] Gönderici soket {bind_ip} arayüzüne bağlandı.")
        
        # Alıcı soketi dinleme portuna bağla
        recv_sock.bind(("", Config.DEVICE_RECV_PORT))
        recv_sock.settimeout(Config.SOCKET_TIMEOUT)
        print(f"[SOKET ✓] Dinleyici soket {Config.DEVICE_RECV_PORT} portuna bağlandı.")

        # Thread'leri oluştur
        sender_thread = threading.Thread(target=veri_gonderici_thread, args=(stop_event, send_sock, simulator), name="Gonderici")
        listener_thread = threading.Thread(target=mesaj_dinleyici_thread, args=(stop_event, recv_sock), name="Dinleyici")

        # Thread'leri başlat
        sender_thread.start()
        listener_thread.start()

        print("[BİLGİ] Simülasyon başlatıldı. Durdurmak için Ctrl+C'ye basın.")
        # Ana thread'in kapanmaması için bekleme
        while True:
            time.sleep(1)
            
    except PermissionError:
        print("\n[HATA] Soket bağlanma hatası: Port başka bir program tarafından kullanılıyor olabilir veya yetki eksik olabilir.")
    except OSError as e:
        print(f"\n[HATA] İşletim sistemi hatası: {e}. Ağ arayüzü ('{Config.TARGET_INTERFACE}') geçerli olmayabilir.")
    except KeyboardInterrupt:
        print("\n\n[KAPANIŞ ⏹️] Ctrl+C algılandı. Program güvenli bir şekilde kapatılıyor...")
    finally:
        # Thread'lere durma sinyali gönder
        stop_event.set()
        
        # Thread'lerin işlerini bitirmesini bekle
        if 'sender_thread' in locals() and sender_thread.is_alive():
            sender_thread.join()
        if 'listener_thread' in locals() and listener_thread.is_alive():
            listener_thread.join()
            
        # Soketleri kapat
        send_sock.close()
        recv_sock.close()
        print("[BİLGİ] Tüm kaynaklar serbest bırakıldı. Program başarıyla sonlandırıldı.")
