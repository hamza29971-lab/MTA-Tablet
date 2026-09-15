# vtm_tablet — MTA Sondaj Takip

Sondaj makinesi tabletleri için Flutter uygulaması.

## Kiosk (device-owner) modu

Uygulama sahada **yalnızca device-owner kiosk modunda** çalışır. Cihaz sahipliği
atanmamışsa uygulama kırmızı "KİOSK KORUMASI YOK" ekranını gösterir ve
kullanılamaz.

Kurulum, çıkış parolaları ve sorun giderme: [`mta-kurulum/README.md`](mta-kurulum/README.md)

Kısaca:

| Konu | Özet |
|---|---|
| Kurulum | `mta-kurulum/mta-tablet-kur.bat` (tablet fabrika ayarlarında, hesapsız) |
| Çıkış ekranı | Ekran kenarından içeri kaydırma, geri tuşu veya sol üst köşeye 5 dokunuş |
| `482910` | Yalnızca Ayarlar'a çıkar; silme/sıfırlama kapalı, Ayarlar dışına çıkılamaz |
| `905174` | Cihaz sahipliğini bırakır; uygulama silinebilir, tablet sıfırlanabilir (geri dönüşü yok) |
| Kaldırma | Önce tablette `905174`, sonra `mta-kurulum/mta-tablet-kaldir.bat` |

Kiosk tarafındaki dosyalar:

- `android/app/src/main/kotlin/com/example/vtm_tablet/KioskPolicy.kt` — tüm
  device-owner politikası (lock task, kullanıcı kısıtları, kalıcı ana ekran)
- `.../KioskBootstrapActivity.kt` — kalıcı ana ekran, dashboard'u kilitli açar
- `.../MainActivity.kt` — kilit görevi, parola doğrulama, Ayarlar modu, serbest bırakma
- `.../KioskDeviceAdminReceiver.kt` — `dpm set-device-owner` ile atanan bileşen
- `.../KioskInstaller.kt` — kiosk içinde sessiz güncelleme kurulumu
- `lib/ui/widgets/kiosk_guard.dart` — kenar kaydırmalarını yakalayan kabuk ve parola ekranı
- `lib/services/kiosk_service.dart` — Flutter ↔ Android köprüsü

## Derleme

```
flutter build apk --release
```

Not: Bu projenin Gradle sürümü (`android/gradle/wrapper/gradle-wrapper.properties`)
kurulu Flutter sürümünün istediğinden eskiyse derleme
`--android-skip-build-dependency-validation` bayrağı ile yapılabilir ya da
Gradle sürümü yükseltilir.

Yeni APK'yı sahaya vermek için `mta-kurulum/mta.apk` dosyasını da yenileyin ve
`mta-kurulum/version.txt` içindeki numarayı `assets/version.txt` ile eşitleyin.
