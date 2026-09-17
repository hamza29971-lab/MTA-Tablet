# MTA Sondaj Takip — Tablet Kiosk Kurulumu

Tableti device-owner kiosk moduna alır. Kurulumdan sonra kullanıcı, yetkili
parolasını girmeden uygulamadan çıkamaz; tablet kapanıp açıldığında doğrudan
uygulama gelir.

## Klasör içeriği

- `README.md` — bu dosya
- `mta.apk` — kurulacak uygulama
- `mta-tablet-kur.bat` — kurulum / güncelleme scripti
- `mta-tablet-kaldir.bat` — kiosk uygulamasını kaldırma scripti
- `platform-tools/` — adb
- `version.txt` — bu paketteki APK sürümü

## Script iki modda çalışır

Script 2. adımda tabletin durumunu kendisi belirler:

| Mod | Ne zaman | Ne yapar |
|---|---|---|
| **YENİ** | Tablet fabrika ayarlarında, cihaz sahibi atanmamış | APK kurar **ve** cihaz sahipliğini atar |
| **GÜNCELLEME** | Tablet zaten bu uygulamayla kiosk modunda | Yalnızca APK'yı yeniler; sahiplik adımını atlar |

**Güncelleme için formata, hesap silmeye veya ekran kilidi kaldırmaya gerek
yoktur** — kabloyu takıp scripti çalıştırmanız yeterli. Aşağıdaki hazırlık
adımları sadece YENİ kurulum içindir.

Cihaz sahibi başka bir uygulamaysa script durur; o durumda fabrika ayarları
zorunludur.

## Tablette (YENİ kurulumdan önce, bir kez)

Sıra önemli:

1. **Fabrika ayarlarına sıfırlayın.**
   Ayarlar > Genel yönetim > Sıfırla > Fabrika ayarlarına sıfırla
2. Kurulum sihirbazında **Google/Samsung hesabı EKLEMEYİN.** Atlayın.
   Device owner yalnızca hiç hesabı olmayan cihaza atanabilir.
3. **Ekran kilidi koymayın** (PIN / desen / parmak izi).
   Güvenli kilit varsa tablet her açılışta kilit ekranında bekler ve uygulama
   otomatik gelmez.
4. Wi-Fi'ye bağlayın (güncellemeler için).
5. Geliştirici seçeneklerini açın: Ayarlar > Tablet hakkında >
   Yazılım bilgileri > **Derleme numarası**na 7 kez dokunun.
6. Ayarlar > Geliştirici seçenekleri > **USB hata ayıklama**yı açın.
7. USB kabloyu takın, tablette çıkan **"Bu bilgisayara güven"** uyarısını
   onaylayın.

## PC'de

1. Bu klasörü diske çıkarın.
2. `mta-tablet-kur.bat` dosyasına çift tıklayın.
3. Script 8 adımı sırayla yapar ve sonunda 4 doğrulama çalıştırır.
   Güncelleme modunda 3. ve 5. adımlar atlanır.

**Dört doğrulamanın da TAMAM olması şart.** Biri bile BAŞARISIZ derse tablet
sahaya verilmemelidir.

Doğrulanan durumlar cihaz sahipliği, gerçek `LOCKED` modu, ön plandaki
dashboard ve güvenli başlangıç bileşeninin kalıcı ana ekran olmasıdır.
Android'in kullanıcı tarafından kapatılabilen `PINNED` ekran sabitleme modu
başarı sayılmaz; script bunu ayrıca hata olarak bildirir.

## Kurulumdan sonra tablette ne kapalı?

- Ana ekran (home), son uygulamalar ve bölünmüş ekran
- Yukarıdan aşağı kaydırınca açılan bildirim paneli ve **Wi-Fi / Bluetooth
  hızlı ayarlar paneli**
- Güç menüsü, güvenli mod
- Fabrika ayarlarına döndürme
- Uygulamanın kaldırılması

## Tablet açılışında uygulama

Tablet her açıldığında doğrudan bu uygulama gelir; ayrıca bir şey yapmak
gerekmez. İki ayrı mekanizma birden çalışır:

1. **Kalıcı ana ekran (birincil).** Cihaz sahibi yetkisiyle uygulama tabletin
   ANA EKRANI yapılır (`addPersistentPreferredActivity` + `KioskHomeAlias`).
   Android açılışta ana ekranı kendisi başlattığı için uygulama gelir. Kullanıcı
   bu atamayı değiştiremez. Kurulum scriptinin 4. doğrulaması (`Ana ekran
   uygulamasi`) tam olarak bunu kontrol eder.
2. **Açılış yayını (yedek).** `BOOT_COMPLETED` / `QUICKBOOT_POWERON` yayınları
   dinlenir ve kiosk yeniden başlatılır. Android 10+ arka plandan uygulama
   açmayı kısıtladığı için bu yol her cihazda garanti değildir; bu yüzden tek
   başına kullanılmaz, 1. maddeyle birlikte çalışır.

Ayrıca uygulama OTA ile sessizce güncellendiğinde (`MY_PACKAGE_REPLACED`) de
kendini hemen geri açar.

**Şarjı bitip kapanan tablet:** Şarja takılıp tablet açıldığı anda uygulama
gelir. Ancak tabletin şarja takılınca *kendiliğinden açılıp açılmayacağı*
cihazın kendi yazılımına (bootloader) bağlıdır; çoğu tablet şarj animasyonunu
gösterir ve güç tuşuna basılmasını bekler. Bu davranış uygulamadan
değiştirilemez — ama tablet bir kez açıldıktan sonra kullanıcı başka hiçbir şey
yapamaz, doğrudan uygulamaya düşer.

Ekran kilidi (PIN/desen) tanımlıysa tablet açılışta kilit ekranında bekler ve
uygulama otomatik gelmez. Bu yüzden kurulum öncesi ekran kilidi konulmamalıdır.

## Uygulamadan çıkış — iki parola

Çıkış ekranı üç yoldan açılır (hepsi aynı ekranı açar):

- Ekranın **herhangi bir kenarından** içeri doğru kaydırmak
- **Geri** tuşu / geri jesti
- Ekranın **sol üst köşesine** 3 saniye içinde **5 kez** dokunmak

| Parola | Ne olur |
|---|---|
| `482910` | **Ayarlar modu.** Yalnızca Ayarlar uygulaması açılır. Kullanıcı Ayarlar dışına çıkamaz — çıkmaya çalışınca sistem onu tekrar uygulamaya bırakır. Uygulama **silinemez**, tablet **sıfırlanamaz**. Ayarlar kapatılınca uygulama kendini yeniden kilitler. |
| `905174` | **Kiosk korumasını tamamen kaldırır.** Cihaz sahipliği bırakılır; uygulama silinebilir, tablet fabrika ayarlarına döndürülebilir, Ayarlar dışına çıkılabilir. **Geri dönüşü yoktur**; tableti yeniden kiosk moduna almak için `mta-tablet-kur.bat` baştan çalıştırılmalıdır. |

Yanlış parola 5 kez girilirse ekran 30 saniye kilitlenir.

Parolalar uygulamanın içinde açık metin olarak durmaz; yalnızca SHA-256
özetleri gömülüdür (`MainActivity.kt`).

## Kiosk'tan tamamen çıkma ve uygulamayı silme

1. Tablette çıkış ekranını açın ve **905174** girin.
2. "KİOSK KORUMASI KALDIRILDI" yazısını görün.
3. PC'de `mta-tablet-kaldir.bat` çalıştırın.

Bu sıra zorunludur: cihaz sahipliği bırakılmadan Android paketin ADB ile
silinmesine izin vermez.

## Güncelleme

Kiosk modunda sistemin kurulum ekranı öne gelemez; bu yüzden uygulama içi
güncellemeler cihaz sahibi yetkisiyle **sessizce** kurulur (kullanıcıya hiçbir
şey sorulmaz). Tabletler Wi-Fi'ye bağlandığında güncellemeyi kendileri alır;
bu script yalnızca ilk kurulumda ve elle güncellemede gereklidir.

## Sorun giderme

| Belirti | Sebep / çözüm |
|---|---|
| `[3/8]` hesap hatası | Tablette hesap var. Fabrika ayarı + hesap atlama. |
| `[5/8]` Device Owner atanamadı | Hesap var veya başka yönetici atanmış. Fabrika ayarı. |
| `[2/8]` "Cihaz sahibi BASKA bir uygulama" | Tablette önceden farklı bir kiosk uygulaması var. Fabrika ayarı zorunlu. |
| `[4/8]` APK kurulamadı | İmza uyuşmazlığı. Farklı anahtarla imzalı eski sürüm varsa önce kaldırılmalı. |
| Doğrulamada "PINNED guvenli kiosk degildir" | Lock-task izin listesi hazır değil. Tablet sahaya verilmemeli; logcat kontrol edilmeli. |
| Doğrulamada "uygulama LOCKED modunda degil" | Güvenli başlangıç tamamlanamamış. Tablet sahaya verilmemeli. |
| Doğrulamada "Ana ekran BASARISIZ" | Kalıcı ana ekran uygulanmamış. Uygulamayı açıp kapatın, tekrar doğrulayın. |
| Uygulamada kırmızı "KİOSK KORUMASI YOK" ekranı | Device owner atanmamış. Kurulumu baştan yapın. |
| Ekranın üstünde kırmızı "KİOSK KİLİDİ DÜŞTÜ" şeridi | Cihaz sahipliği var ama lock task düşmüş. Uygulama 15 saniyede bir kendini yeniden kilitler; şerit kaybolmuyorsa tableti yeniden başlatın, geçmezse kurulumu tekrarlayın. |
| Ekranın üst ortasında "..." tutamağı çıkıyor, oradan bölünmüş ekrana geçilebiliyor | Lock task düşmüş demektir (yukarıdaki satır). Uygulama `resizeableActivity="false"` bildirir ve kurulum scripti `force_resizable_activities` / `enable_freeform_support` ayarlarını kapatır; yine de çıkıyorsa tablet gerçek `LOCKED` modunda değildir, sahaya verilmemelidir. |
| Tablet açılışta kilit ekranında bekliyor | Ekran kilidi tanımlı. 482910 ile Ayarlar'a çıkıp kaldırın. |

Teşhis komutu:

```
platform-tools\adb.exe logcat -s KioskBootstrap KioskMode KioskPolicy KioskAdmin KioskInstall KioskBoot
```

## Uygulamanın kiosk tarafındaki kaynak dosyaları

| Dosya | İş |
|---|---|
| `android/.../KioskPolicy.kt` | Tüm device-owner politikası (lock task, kısıtlar, kalıcı ana ekran) |
| `android/.../KioskBootstrapActivity.kt` | Kalıcı ana ekran; dashboard'u kilitli açar |
| `android/.../MainActivity.kt` | Kilit görevi, parola doğrulama, Ayarlar modu, serbest bırakma |
| `android/.../KioskDeviceAdminReceiver.kt` | `dpm set-device-owner` ile atanan bileşen |
| `android/.../KioskInstaller.kt` | Sessiz güncelleme kurulumu |
| `lib/ui/widgets/kiosk_guard.dart` | Kenar kaydırma yakalama ve parola ekranı |
| `lib/services/kiosk_service.dart` | Flutter–Android köprüsü |
