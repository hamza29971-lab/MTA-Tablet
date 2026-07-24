import socket
import threading

# --- AYARLAR ---
LISTEN_PUBLIC_HOST = '0.0.0.0'  # Harici cihazdan dinlenecek IP
LISTEN_PUBLIC_PORT = 5005         # Harici cihazdan dinlenecek Port

LISTEN_EMULATOR_HOST = '0.0.0.0' # Emülatörden dinlenecek IP
LISTEN_EMULATOR_PORT = 5006        # Emülatörden dinlenecek Port

EMULATOR_IP = '10.0.2.16' # Genellikle ilk emülatörün IP'si
EMULATOR_LISTEN_PORT = 5005 # Flutter app'in dinlediği port

# --- Global Değişkenler ---
public_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
emulator_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
last_external_device_addr = None

def from_external_to_emulator():
    """Harici Cihaz -> Emülatör yönü"""
    global last_external_device_addr
    public_socket.bind((LISTEN_PUBLIC_HOST, LISTEN_PUBLIC_PORT))
    print(f"[*] Harici cihazlardan {LISTEN_PUBLIC_HOST}:{LISTEN_PUBLIC_PORT} portunda veri bekleniyor...")

    while True:
        try:
            data, addr = public_socket.recvfrom(4096)
            print(f"[<--] Harici cihazdan ({addr[0]}:{addr[1]}) {len(data)} byte alındı.")
            last_external_device_addr = addr
            
            # Veriyi doğrudan emülatörün IP'sine ve Flutter App'in dinlediği porta gönder
            emulator_socket.sendto(data, (EMULATOR_IP, EMULATOR_LISTEN_PORT))
            print(f"[-->] Veri emülatöre ({EMULATOR_IP}:{EMULATOR_LISTEN_PORT}) gönderildi.")
        except Exception as e:
            print(f"[HATA] Harici cihaz dinlemede sorun: {e}")


def from_emulator_to_external():
    """Emülatör -> Harici Cihaz yönü"""
    emulator_socket.bind((LISTEN_EMULATOR_HOST, LISTEN_EMULATOR_PORT))
    print(f"[*] Emülatörden {LISTEN_EMULATOR_HOST}:{LISTEN_EMULATOR_PORT} portunda veri bekleniyor...")

    while True:
        try:
            data, addr = emulator_socket.recvfrom(4096)
            print(f"[-->] Emülatörden {len(data)} byte alındı.")
            
            if last_external_device_addr:
                public_socket.sendto(data, last_external_device_addr)
                print(f"[<--] Veri harici cihaza ({last_external_device_addr[0]}:{last_external_device_addr[1]}) gönderildi.")
            else:
                print("[!] Henüz harici cihaz adresi bilinmiyor, cevap gönderilemedi.")
        except Exception as e:
            print(f"[HATA] Emülatör dinlemede sorun: {e}")


# Programı başlat
print("--- Çift Yönlü UDP Relay Başlatılıyor ---")
thread1 = threading.Thread(target=from_external_to_emulator)
thread2 = threading.Thread(target=from_emulator_to_external)
thread1.start()
thread2.start()