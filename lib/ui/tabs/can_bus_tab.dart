// lib/ui/tabs/can_bus_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/device_data.dart';
import '../../providers/config_provider.dart';
import '../../providers/data_provider.dart';
import '../widgets/gauge_card.dart';

class CanBusTab extends StatelessWidget {
  const CanBusTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Konfigürasyonu bir kez alıyoruz, çünkü bu sekmedeki ayarlar değişmeyecek.
    final config = context.read<ConfigurationProvider>().appConfig;

    // Gösterilecek 7 gauge'ın ID'lerini ve veri seçicilerini bir listede tutalım.
    // Bu, GridView'ı daha temiz hale getirir.
    final List<Map<String, dynamic>> gaugeDataMap = [
      {'id': 'can_engine_speed', 'selector': (CanData cd) => cd.engineSpeed.toDouble()},
      {'id': 'can_oil_pressure', 'selector': (CanData cd) => cd.engineOilPressure.toDouble()},
      {'id': 'can_coolant_temp', 'selector': (CanData cd) => cd.engineCoolantTemperature.toDouble()},
      {'id': 'can_oil_temp', 'selector': (CanData cd) => cd.engineOilTemperature.toDouble()},
      {'id': 'can_fuel_level_1', 'selector': (CanData cd) => cd.fuelLevel1.toDouble()},
      {'id': 'can_fuel_level_2', 'selector': (CanData cd) => cd.fuelLevel2.toDouble()},
      {'id': 'can_fuel_temp', 'selector': (CanData cd) => cd.engineFuelTemperature.toDouble()},
    ];

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- ÜST BÖLÜM: BİLGİ KUTULARI ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoBox(
                context, // BuildContext eklendi
                label: 'VOLTAJ',
                unit: 'V',
                selector: (CanData cd) => cd.batteryPotential.toDouble(),
              ),
              _buildInfoBox(
                context, // BuildContext eklendi
                label: 'ÜRETİCİ KODU',
                selector: (CanData cd) => cd.manufacturerCode.toDouble(),
              ),
              _buildInfoBox(
                context, // BuildContext eklendi
                label: 'SONDAJ MAKİNESİ ÇALIŞMA SAATİ',
                unit: 'sa',
                selector: (CanData cd) => cd.engineTotalHoursOfOperation.toDouble(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // --- ALT BÖLÜM: GAUGE'LAR ---
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final totalHeight = constraints.maxHeight;
                if (totalHeight <= 0 || totalWidth <= 0) return const SizedBox.shrink();

                const crossAxisCount = 4;
                const mainAxisCount = 2; // We have 7 items -> 2 rows
                const crossAxisSpacing = 16.0;
                const mainAxisSpacing = 16.0;

                final childWidth = (totalWidth - (crossAxisSpacing * (crossAxisCount - 1))) / crossAxisCount;
                final childHeight = (totalHeight - (mainAxisSpacing * (mainAxisCount - 1))) / mainAxisCount;
                final aspectRatio = (childHeight > 0) ? (childWidth / childHeight) : 1.0;

                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: crossAxisSpacing,
                    mainAxisSpacing: mainAxisSpacing,
                    childAspectRatio: aspectRatio,
                  ),
                  itemCount: gaugeDataMap.length,
                  itemBuilder: (context, index) {
                    final item = gaugeDataMap[index];
                    final gaugeId = item['id'];
                    final gaugeConfig = config.gaugeConfigs[gaugeId]!;

                    return Selector<DataProvider, double>(
                      selector: (_, provider) => (item['selector'] as double Function(CanData))(provider.deviceData.canData),
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
            ),
          ),
        ],
      ),
    );
  }

  // Üstteki bilgi kutularını oluşturan yardımcı metot
  Widget _buildInfoBox(
    BuildContext context, { // BuildContext eklendi
    required String label,
    String unit = '',
    // HATA 1 DÜZELTİLDİ: Parametre tipi 'Selector' yerine doğru fonksiyon tipi olarak değiştirildi.
    required double Function(CanData) selector,
  }) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: 180,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade400),
          ),
          alignment: Alignment.center,
          child: Selector<DataProvider, double>(
            selector: (_, provider) => selector(provider.deviceData.canData),
            builder: (context, value, _) {
              // Değeri formatlayalım (ondalıklı veya tam sayı)
              final formattedValue = unit == 'sa' ? value.toStringAsFixed(2) : value.toStringAsFixed(0);
              return Text(
                '$formattedValue ${unit}'.trim(),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
