// lib/ui/tabs/home_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_config.dart';
import '../../models/device_data.dart';
import '../../providers/config_provider.dart';
import '../../providers/data_provider.dart';
import '../widgets/gauge_card.dart';
import '../widgets/alert_card.dart';

// Uyarı durumlarını temsil eden enum
// enum AlertLevel { normal, warning, critical }

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SOL SÜTUN: Göstergeler ve Motor Saati
          Expanded(
            flex: 4,
            child: _buildGaugesSection(),
          ),
          const SizedBox(width: 16),
          // SAĞ SÜTUN: Uyarı Paneli
          Expanded(
            flex: 1,
            child: _buildAlertsPanel(),
          ),
        ],
      ),
    );
  }

  // Sol Sütun: Göstergeler ve Motor Saati
  Widget _buildGaugesSection() {
    return Column(
      children: [
        // Motor Toplam Saat göstergesi
        Selector<DataProvider, double>(
          selector: (_, provider) => provider.deviceData.canData.engineTotalHoursOfOperation,
          builder: (context, hours, _) {
            return Card(
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.timer_outlined, size: 40),
                title: const Text('SONDAJ MAKİNESİ TOPLAM ÇALIŞMA SAATİ', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text('${hours.toStringAsFixed(2)} sa', style: Theme.of(context).textTheme.headlineSmall),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        // 6 adet Gauge göstergesi
        Expanded(
          child: _buildHomePageGauges(),
        ),
      ],
    );
  }

  // Anasayfadaki 6 göstergeyi oluşturan Grid
  Widget _buildHomePageGauges() {
    return Consumer<ConfigurationProvider>(
      builder: (context, configProvider, child) {
        final config = configProvider.appConfig;
        final homePageIds = config.homePageGaugeIds;
        final itemCount = homePageIds.length > 6 ? 6 : homePageIds.length;

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxHeight <= 0 || constraints.maxWidth <= 0) {
              return const SizedBox.shrink();
            }

            const crossAxisCount = 3;
            // Satır sayısını, gösterilecek öğe sayısına göre dinamik olarak hesapla
            final mainAxisCount = (itemCount / crossAxisCount).ceil();
            const crossAxisSpacing = 16.0;
            const mainAxisSpacing = 16.0;

            // Her bir kartın genişliğini ve yüksekliğini hesapla
            final childWidth = (constraints.maxWidth - (crossAxisSpacing * (crossAxisCount - 1))) / crossAxisCount;
            final childHeight = (constraints.maxHeight - (mainAxisSpacing * (mainAxisCount - 1))) / mainAxisCount;

            // Bu bilgilere göre doğru en-boy oranını hesapla
            final aspectRatio = childWidth / childHeight > 0 ? childWidth / childHeight : 1.0;

            return GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: crossAxisSpacing,
                mainAxisSpacing: mainAxisSpacing,
                childAspectRatio: aspectRatio,
              ),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                final gaugeId = homePageIds[index];
                final gaugeConfig = config.gaugeConfigs[gaugeId];

                if (gaugeConfig == null) return const Card(child: Center(child: Text('Ayar Yok')));

                return Selector<DataProvider, double>(
                  selector: (_, dataProvider) => _getValueForId(dataProvider.deviceData, gaugeId),
                  builder: (context, value, _) {
                    return GaugeCard(
                      key: ValueKey(gaugeId),
                      label: gaugeConfig.label,
                      unit: gaugeConfig.unit,
                      value: value,
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
        );
      },
    );
  }

  Widget _buildAlertsPanel() {
  const int analogPage1Index = 2;
  const int digitalPageIndex = 4;
  const int canBusPageIndex = 5;
  const int dtcPageIndex = 9;

  return Column(
    children: [
      Expanded(
        child: _buildAlertSection( // Generic tip ve selector kaldırıldı
          title: 'Makine Verileri',
          // builder artık iki provider alıyor
          builder: (context, provider, config) {
            final analogResult = _getAlerts(provider.deviceData.analogData, config, 'analog');
            final auxResult = _getAlerts(provider.deviceData.auxData, config, 'aux');
            final combinedAlerts = [...analogResult.value, ...auxResult.value];
            
            AlertLevel highestLevel;
            if (analogResult.key == AlertLevel.critical || auxResult.key == AlertLevel.critical) {
              highestLevel = AlertLevel.critical;
            } else if (analogResult.key == AlertLevel.warning || auxResult.key == AlertLevel.warning) {
              highestLevel = AlertLevel.warning;
            } else {
              highestLevel = AlertLevel.normal;
            }
            return MapEntry(highestLevel, combinedAlerts);
          },
          onTap: (context) { /* ... onTap mantığınız ... */ },
        ),
      ),
      const SizedBox(height: 16),
      Expanded(
        child: _buildAlertSection( // Generic tip ve selector kaldırıldı
          title: 'Motor Verileri',
          builder: (context, provider, config) {
            final data = provider.deviceData.canData; // DataProvider'dan veriyi al
            final List<double> canValues = [
              data.engineSpeed.toDouble(), data.engineOilPressure.toDouble(), data.engineCoolantTemperature.toDouble(),
              data.engineOilTemperature.toDouble(), data.engineFuelTemperature.toDouble(), data.fuelLevel1.toDouble(), data.fuelLevel2.toDouble()
            ];
            final List<String> canIds = [
              'can_engine_speed', 'can_oil_pressure', 'can_coolant_temp', 'can_oil_temp',
              'can_fuel_temp', 'can_fuel_level_1', 'can_fuel_level_2'
            ];
            return _getAlertsFromMappedData(canValues, canIds, config);
          },
          onTap: (context) => context.read<PageController>().jumpToPage(canBusPageIndex),
        ),
      ),
      const SizedBox(height: 16),
      Expanded(
        child: _buildAlertSection( // Generic tip ve selector kaldırıldı
          title: 'Arızalar',
          builder: (context, provider, config) {
            final data = provider.deviceData.canDtcData; // DataProvider'dan veriyi al
            final dtcCount = data.dtcs.length;
            final alertLevel = dtcCount > 0 ? AlertLevel.critical : AlertLevel.normal;
            final alerts = dtcCount > 0 ? ['DTC Sayısı: $dtcCount'] : <String>[];
            return MapEntry(alertLevel, alerts);
          },
          onTap: (context) => context.read<PageController>().jumpToPage(dtcPageIndex),
        ),
      ),
    ],
  );
}

// Widget _buildAlertsPanel() {
//   return Column(
//     children: [
//       // YENİ: "Analog" ve "Aux" birleştirilerek "Makine Verileri" kartı oluşturuldu.
//       _buildAlertSection<DataProvider>( // Tipi DataProvider olarak değiştirildi
//         title: 'Makine Verileri',
//         // Selector artık tüm provider'ı seçiyor, çünkü iki farklı veriye ihtiyacımız var.
//         selector: (p) => p,
//         builder: (context, provider, config) {
//           // 1. Her iki veri seti için de uyarıları ayrı ayrı al.
//           final analogResult = _getAlerts(provider.deviceData.analogData, config, 'analog');
//           final auxResult = _getAlerts(provider.deviceData.auxData, config, 'aux');

//           // 2. İki uyarı listesini birleştir.
//           final combinedAlerts = [...analogResult.value, ...auxResult.value];

//           // 3. En yüksek alarm seviyesini belirle.
//           AlertLevel highestLevel;
//           if (analogResult.key == AlertLevel.critical || auxResult.key == AlertLevel.critical) {
//             highestLevel = AlertLevel.critical;
//           } else if (analogResult.key == AlertLevel.warning || auxResult.key == AlertLevel.warning) {
//             highestLevel = AlertLevel.warning;
//           } else {
//             highestLevel = AlertLevel.normal;
//           }

//           // 4. Birleştirilmiş sonucu döndür.
//           return MapEntry(highestLevel, combinedAlerts);
//         },
//       ),
//       const SizedBox(height: 16),
//       // "CAN Bus" kartı değişmeden kalıyor.
//       _buildAlertSection<CanData>(
//         title: 'Motor Verileri',
//         selector: (p) => p.deviceData.canData,
//         builder: (context, data, config) {
//           final List<double> canValues = [
//             data.engineSpeed.toDouble(), data.engineOilPressure.toDouble(), data.engineCoolantTemperature.toDouble(),
//             data.engineOilTemperature.toDouble(), data.engineFuelTemperature.toDouble(), data.fuelLevel1.toDouble(), data.fuelLevel2.toDouble()
//           ];
//           final List<String> canIds = [
//             'can_engine_speed', 'can_oil_pressure', 'can_coolant_temp', 'can_oil_temp',
//             'can_fuel_temp', 'can_fuel_level_1', 'can_fuel_level_2'
//           ];
//           return _getAlertsFromMappedData(canValues, canIds, config);
//         },
//       ),
//       const SizedBox(height: 16),
//       // "DTC" kartı değişmeden kalıyor.
//       _buildAlertSection<CanDtcData>(
//         title: 'DTC',
//         selector: (p) => p.deviceData.canDtcData,
//         builder: (context, data, config) {
//           final dtcCount = data.dtcs.length;
//           final alertLevel = dtcCount > 0 ? AlertLevel.critical : AlertLevel.normal;
//           final alerts = dtcCount > 0 ? ['DTC Sayısı: $dtcCount'] : <String>[];
//           return MapEntry(alertLevel, alerts);
//         },
//       ),
//     ],
//   );
// }

  // Uyarı paneli için yeniden kullanılabilir bölüm (GÜNCELLENMİŞ HALİ)
// Widget _buildAlertSection<T>({
//   required String title,
//   required T Function(DataProvider) selector,
//   required MapEntry<AlertLevel, List<String>> Function(BuildContext, T, AppConfig) builder,
// }) {
//   return Selector<DataProvider, T>(
//     selector: (_, provider) => selector(provider),
//     builder: (context, data, _) {
//       final config = context.watch<ConfigurationProvider>().appConfig;
//       // Veriyi işleyip alert seviyesini al
//       final result = builder(context, data, config);
//       final alertLevel = result.key;

//       // Tüm görselleştirme ve animasyon işini AlertCard'a devret
//       return AlertCard(
//         title: title,
//         alertLevel: alertLevel,
//       );
//     },
//   );
// }


// Uyarı paneli için yeniden kullanılabilir bölüm (KESİN ÇÖZÜM)
Widget _buildAlertSection({
  required String title,
  // builder artık doğrudan provider'ları alacak
  required MapEntry<AlertLevel, List<String>> Function(BuildContext, DataProvider, AppConfig) builder,
  void Function(BuildContext context)? onTap,
}) {
  // Selector yerine Consumer2 kullanıyoruz
  return Consumer2<DataProvider, ConfigurationProvider>(
    builder: (context, dataProvider, configProvider, _) {
      // Yükleme devam ediyorsa bekleme kartı göster (opsiyonel ama önerilir)
      if (configProvider.isLoading) {
        return const Card(margin: EdgeInsets.zero, child: Center(child: CircularProgressIndicator()));
      }

      // builder fonksiyonuna her iki provider'ı da gönderiyoruz
      final result = builder(context, dataProvider, configProvider.appConfig);
      final alertLevel = result.key;

      return AlertCard(
        title: title,
        alertLevel: alertLevel,
      );
    },
  );
}

  // Belirtilen ID'ye göre DataProvider'dan doğru veriyi çeken yardımcı metot
  double _getValueForId(DeviceData data, String gaugeId) {
    if (gaugeId.startsWith('analog_')) {
      final index = int.tryParse(gaugeId.split('_')[1]) ?? 0;
      return data.analogData.length > index ? data.analogData[index].toDouble() : 0.0;
    }
    if (gaugeId.startsWith('aux_')) {
      final index = int.tryParse(gaugeId.split('_')[1]) ?? 0;
      return data.auxData.length > index ? data.auxData[index].toDouble() : 0.0;
    }
    if (gaugeId.startsWith('can_')) {
      switch (gaugeId) {
        case 'can_engine_speed': return data.canData.engineSpeed.toDouble();
        case 'can_oil_pressure': return data.canData.engineOilPressure.toDouble();
        case 'can_coolant_temp': return data.canData.engineCoolantTemperature.toDouble();
        case 'can_oil_temp': return data.canData.engineOilTemperature.toDouble();
        case 'can_fuel_temp': return data.canData.engineFuelTemperature.toDouble();
        case 'can_fuel_level_1': return data.canData.fuelLevel1.toDouble();
        case 'can_fuel_level_2': return data.canData.fuelLevel2.toDouble();
        default: return 0.0;
      }
    }
    return 0.0;
  }

  // Uyarıları bulan yardımcı metot
  MapEntry<AlertLevel, List<String>> _getAlerts(List<num> data, AppConfig config, String prefix) {
    final alerts = <String>[];
    var highestLevel = AlertLevel.normal;

    for (int i = 0; i < data.length; i++) {
      final gaugeId = '${prefix}_$i';
      final gaugeConfig = config.gaugeConfigs[gaugeId];
      if (gaugeConfig != null) {
        final value = data[i].toDouble();
        if (value >= gaugeConfig.criticalValue) {
          alerts.add('${gaugeConfig.label}: ${value.toStringAsFixed(1)}');
          if (highestLevel != AlertLevel.critical) highestLevel = AlertLevel.critical;
        } else if (value >= gaugeConfig.warningValue) {
          alerts.add('${gaugeConfig.label}: ${value.toStringAsFixed(1)}');
          if (highestLevel == AlertLevel.normal) highestLevel = AlertLevel.warning;
        }
      }
    }
    return MapEntry(highestLevel, alerts);
  }
  
  // CAN verileri gibi eşlenmiş veriler için uyarıları bulan metot
  MapEntry<AlertLevel, List<String>> _getAlertsFromMappedData(List<double> values, List<String> ids, AppConfig config) {
    final alerts = <String>[];
    var highestLevel = AlertLevel.normal;

    for (int i = 0; i < values.length; i++) {
      final gaugeConfig = config.gaugeConfigs[ids[i]];
      if (gaugeConfig != null) {
        final value = values[i];
        if (value >= gaugeConfig.criticalValue) {
          alerts.add('${gaugeConfig.label}: ${value.toStringAsFixed(1)}');
          if (highestLevel != AlertLevel.critical) highestLevel = AlertLevel.critical;
        } else if (value >= gaugeConfig.warningValue) {
          alerts.add('${gaugeConfig.label}: ${value.toStringAsFixed(1)}');
          if (highestLevel == AlertLevel.normal) highestLevel = AlertLevel.warning;
        }
      }
    }
    return MapEntry(highestLevel, alerts);
  }
}
