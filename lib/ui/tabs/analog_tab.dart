// lib/ui/tabs/analog_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vtm_tablet/providers/config_provider.dart';
//import '../../providers/config_provider.dart';
import '../../providers/data_provider.dart';
import '../widgets/gauge_card.dart';

class AnalogTab extends StatelessWidget {
  const AnalogTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Gerekli verileri Provider'lardan al
    final deviceData = context.watch<DataProvider>().deviceData;
    final config = context.watch<ConfigurationProvider>().appConfig;

    // GridView'ı LayoutBuilder ile sarmalayarak dinamik boyutlandırma yapıyoruz
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 1. Mevcut toplam alanı ölçüyoruz.
          final totalWidth = constraints.maxWidth;
          final totalHeight = constraints.maxHeight;

          if (totalHeight <= 0 || totalWidth <= 0) {
            return const SizedBox.shrink();
          }

          // 2. Sütun ve satır arası boşlukları tanımlıyoruz.
          const crossAxisCount = 4; // 4 sütun
          const mainAxisCount = 2;  // 2 satır (ekranı dolduracak)
          const crossAxisSpacing = 12.0;
          const mainAxisSpacing = 12.0;

          // 3. Her bir kartın genişliğini ve yüksekliğini hesaplıyoruz.
          final childWidth = (totalWidth - (crossAxisSpacing * (crossAxisCount - 1))) / crossAxisCount;
          final childHeight = (totalHeight - (mainAxisSpacing * (mainAxisCount - 1))) / mainAxisCount;
          
          // 4. Dinamik en-boy oranını hesaplıyoruz.
          final aspectRatio = childWidth / childHeight;

          return GridView.builder(
            // GridView doğal olarak kaydırılabilir
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: crossAxisSpacing,
              mainAxisSpacing: mainAxisSpacing,
              childAspectRatio: aspectRatio,
            ),
            // Toplam 16 analog verinin tamamını listeliyoruz
            itemCount: deviceData.analogData.length, 
            itemBuilder: (context, index) {
              //final analogConfig = config.analogConfigs[index];
              // 1. Göstergenin benzersiz ID'sini oluşturuyoruz (örn: "analog_0", "analog_1")
              final String gaugeId = 'analog_$index';

              // 2. Bu ID'yi kullanarak Map'ten doğru konfigürasyonu alıyoruz.
              // Modelimizdeki AppConfig.initial() ve fromJson mantığı sayesinde
              // bu anahtarın her zaman var olacağını biliyoruz.
              final gaugeConfig = config.gaugeConfigs[gaugeId]!;
              // Tüm DataProvider yerine, Selector ile sadece bu index'e ait
              // analog verinin değerini (bir double) dinliyoruz.
              return Selector<DataProvider, double>(
                // 1. Dinlenecek spesifik veriyi seçen fonksiyon:
                selector: (_, provider) {
                  // Veri listesinin o anki uzunluğunu kontrol ederek hata almayı önle
                  if (index < provider.deviceData.analogData.length) {
                    return provider.deviceData.analogData[index].toDouble();
                  }
                  // Veri henüz gelmediyse veya eksikse, varsayılan bir değer döndür
                  return gaugeConfig.minValue;
                },
                
                // 2. Sadece yukarıda seçilen 'double' değeri değiştiğinde
                // yeniden çizilecek olan widget'ı oluşturan fonksiyon:
                builder: (context, analogValue, child) {
                  // İsteğe bağlı: Hangi göstergenin yeniden çizildiğini görmek için
                  // print('GaugeCard analog_$index yeniden çiziliyor. Değer: $analogValue');
                  
                  return GaugeCard(
                    key: ValueKey(gaugeId),
                    label: gaugeConfig.label,
                    unit: gaugeConfig.unit,
                    value: analogValue, // Selector'dan gelen güncel değeri kullan
                    minValue: gaugeConfig.minValue,
                    maxValue: gaugeConfig.maxValue,
                    warningValue: gaugeConfig.warningValue,
                    criticalValue: gaugeConfig.criticalValue,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
