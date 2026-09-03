// // lib/ui/tabs/digital_tab.dart

// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:vtm_tablet/providers/config_provider.dart';
// import '../../providers/data_provider.dart';
// import '../widgets/gauge_card.dart';

// class DigitalTab extends StatelessWidget {
//   const DigitalTab({super.key});

//     double _getAnalogValue(List<double> data, int index) {
//     return data.length > index ? data[index].toDouble() : 0.0;
//   }

//   @override
//    Widget build(BuildContext context) {
//     // Veri ve konfigürasyonu alıyoruz.
//     // .watch yerine .read kullanmak, config veya sensor verisi değiştiğinde
//     // tüm sayfanın gereksiz yere yeniden çizilmesini engeller.
//     // Değişiklikleri Selector'lar ile yöneteceğiz.
//     final config = context.read<ConfigurationProvider>().appConfig;

//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           // --- SOL SÜTUN: SENSÖR VERİLERİ ---
//           Expanded(
//             flex: 1,
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Dikeyde ortala
//               children: [
//                 // Selector ile sadece ilgili analog değerler değiştiğinde güncellenir
//                 Selector<DataProvider, Map<String, double>>(
//                   selector: (_, provider) {
//                     final analogData = provider.deviceData.analogData;
//                     return {
//                       'roll': _getAnalogValue(analogData, config.machineRollAnalogIndex),
//                       'pitch': _getAnalogValue(analogData, config.machinePitchAnalogIndex),
//                     };
//                   },
//                   builder: (context, data, _) {
//                     return _buildRollPitchGroup(
//                       context,
//                       title: 'MAKİNA',
//                       roll: data['roll']!,
//                       pitch: data['pitch']!,
//                     );
//                   },
//                 ),
//                 Selector<DataProvider, Map<String, double>>(
//                   selector: (_, provider) {
//                     final analogData = provider.deviceData.analogData;
//                     return {
//                       'roll': _getAnalogValue(analogData, config.towerRollAnalogIndex),
//                       'pitch': _getAnalogValue(analogData, config.towerPitchAnalogIndex),
//                     };
//                   },
//                   builder: (context, data, _) {
//                     return _buildRollPitchGroup(
//                       context,
//                       title: 'KULE',
//                       roll: data['roll']!,
//                       pitch: data['pitch']!,
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 16),
//           // --- SAĞ SÜTUN: GAUGE'LAR (2x1 Grid) ---
//           Expanded(
//             flex: 4,
//             child: LayoutBuilder(
//               builder: (context, constraints) {
//                 // ... (LayoutBuilder içindeki boyut hesaplamaları aynı)
//                 final totalWidth = constraints.maxWidth;
//                 final totalHeight = constraints.maxHeight;
//                 if (totalHeight <= 0 || totalWidth <= 0) return const SizedBox.shrink();
//                 const crossAxisCount = 2;
//                 const mainAxisCount = 1;
//                 const crossAxisSpacing = 16.0;
//                 const mainAxisSpacing = 16.0;
//                 final childWidth = (totalWidth - crossAxisSpacing) / crossAxisCount;
//                 final childHeight = (totalHeight - mainAxisSpacing) / mainAxisCount;
//                 final aspectRatio = childWidth / childHeight > 0 ? childWidth / childHeight : 1.0;

//                 return GridView.builder(
//                   physics: const NeverScrollableScrollPhysics(),
//                   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: crossAxisCount,
//                     crossAxisSpacing: crossAxisSpacing,
//                     mainAxisSpacing: mainAxisSpacing,
//                     childAspectRatio: aspectRatio,
//                   ),
//                   itemCount: 2,
//                   itemBuilder: (context, index) {
//                     final String gaugeId = 'aux_$index';
//                     final gaugeConfig = config.gaugeConfigs[gaugeId]!;

//                     // ✅✅✅ PERFORMANS İYİLEŞTİRMESİ BURADA ✅✅✅
//                     // Selector ile sadece bu index'e ait aux verisini dinliyoruz.
//                     return Selector<DataProvider, double>(
//                       selector: (_, provider) =>
//                           index < provider.deviceData.auxData.length
//                               ? provider.deviceData.auxData[index].toDouble()
//                               : gaugeConfig.minValue,
//                       builder: (context, value, child) {
//                         return GaugeCard(
//                           key: ValueKey(gaugeId),
//                           label: gaugeConfig.label,
//                           unit: gaugeConfig.unit,
//                           value: value,
//                           minValue: gaugeConfig.minValue,
//                           maxValue: gaugeConfig.maxValue,
//                           warningValue: gaugeConfig.warningValue,
//                           criticalValue: gaugeConfig.criticalValue,
//                         );
//                       },
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }


//   Widget _buildCompass(BuildContext context, {required double heading}) {
//     final double angle = heading * (pi / 180);
//     final compassTextStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
//       fontWeight: FontWeight.bold,
//       color: Colors.black54,
//     );

//     return Column(
//       children: [
//         Text(
//           'MAKİNA',
//           style: Theme.of(context).textTheme.titleMedium?.copyWith(
//             fontWeight: FontWeight.bold,
//             color: Colors.amber,
//           ),
//         ),
//         Expanded(
//           child: AspectRatio(
//             aspectRatio: 1,
//             child: Stack(
//               alignment: Alignment.center,
//               children: [
//                 Container(
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: const Color(0xFFEFEFEF),
//                     border: Border.all(color: Colors.grey.shade600, width: 3),
//                   ),
//                   child: Stack(
//                     children: [
//                       Align(
//                         alignment: Alignment.topCenter,
//                         child: Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Text('N', style: compassTextStyle),
//                         ),
//                       ),
//                       Align(
//                         alignment: Alignment.centerRight,
//                         child: Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Text('E', style: compassTextStyle),
//                         ),
//                       ),
//                       Align(
//                         alignment: Alignment.bottomCenter,
//                         child: Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Text('S', style: compassTextStyle),
//                         ),
//                       ),
//                       Align(
//                         alignment: Alignment.centerLeft,
//                         child: Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Text('W', style: compassTextStyle),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Transform.rotate(
//                   angle: angle,
//                   child: const Icon(
//                     Icons.navigation,
//                     color: Colors.red,
//                     size: 60,
//                   ),
//                 ),
//                 Align(
//                   alignment: const Alignment(0, 0.5),
//                   child: Container(
//                     width: 70,
//                     height: 40,
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: Colors.grey.shade400),
//                     ),
//                     alignment: Alignment.center,
//                     child: Text(
//                       heading.toStringAsFixed(0),
//                       style: Theme.of(context).textTheme.headlineSmall
//                           ?.copyWith(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.black,
//                           ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildRollPitchGroup(
//     BuildContext context, {
//     required String title,
//     required double roll,
//     required double pitch,
//   }) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         Text(
//           title,
//           style: Theme.of(context).textTheme.titleMedium?.copyWith(
//             fontWeight: FontWeight.bold,
//             fontSize: 28,
//             color: Colors.black,
//           ),
//         ),
//         const SizedBox(height: 8),
//         _buildLabeledValue(context, label: 'ROLL', value: roll),
//         const SizedBox(height: 8),
//         _buildLabeledValue(context, label: 'PITCH', value: pitch),
//       ],
//     );
//   }

//   Widget _buildLabeledValue(
//     BuildContext context, {
//     required String label,
//     required double value,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//           fontSize: 20,
//         )),
//         const SizedBox(height: 4),
//         Container(
//           width: 180, // Sabit genişlik verelim
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(4),
//             border: Border.all(color: Colors.grey.shade400),
//           ),
//           alignment: Alignment.center,
//           child: Text(
//             value.toStringAsFixed(2),
//             style: Theme.of(context).textTheme.titleLarge?.copyWith(
//               color: Colors.black,
//               fontWeight: FontWeight.bold,
//               fontSize: 32
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vtm_tablet/models/app_config.dart';
import 'package:vtm_tablet/providers/config_provider.dart';
import '../../providers/data_provider.dart';
import '../widgets/gauge_card.dart';
import '../widgets/indicator_card.dart'; // Yeni IndicatorCard widget'ını import ediyoruz

class DigitalTab extends StatelessWidget {
  const DigitalTab({super.key});

  double _getAnalogValue(List<double> data, int index) {
    return data.length > index ? data[index].toDouble() : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final config = context.read<ConfigurationProvider>().appConfig;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- SOL SÜTUN: SENSÖR VERİLERİ ---
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Selector<DataProvider, Map<String, double>>(
                  selector: (_, provider) {
                    final analogData = provider.deviceData.analogData;
                    return {
                      'roll': _getAnalogValue(analogData, config.machineRollAnalogIndex),
                      'pitch': _getAnalogValue(analogData, config.machinePitchAnalogIndex),
                    };
                  },
                  builder: (context, data, _) {
                    return _buildRollPitchGroup(
                      context,
                      title: 'MAKİNA',
                      roll: data['roll']!,
                      pitch: data['pitch']!,
                    );
                  },
                ),
                Selector<DataProvider, Map<String, double>>(
                  selector: (_, provider) {
                    final analogData = provider.deviceData.analogData;
                    return {
                      'roll': _getAnalogValue(analogData, config.towerRollAnalogIndex),
                      'pitch': _getAnalogValue(analogData, config.towerPitchAnalogIndex),
                    };
                  },
                  builder: (context, data, _) {
                    return _buildRollPitchGroup(
                      context,
                      title: 'KULE',
                      roll: data['roll']!,
                      pitch: data['pitch']!,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // --- SAĞ SÜTUN: GAUGE'LAR ve İNDİKATÖRLER ---
          Expanded(
            flex: 4,
            child: Column(
              children: [
                // ÜST YARI: Gauge'lar
                Expanded(
                  child: _buildGaugesGrid(config),
                ),
                const SizedBox(height: 16),
                // ALT YARI: İndikatörler
                Expanded(
                  child: _buildIndicatorsSection(config),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2 adet Gauge'ı oluşturan yardımcı metot
  Widget _buildGaugesGrid(AppConfig config) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final totalHeight = constraints.maxHeight;
        if (totalHeight <= 0 || totalWidth <= 0) return const SizedBox.shrink();
        
        const crossAxisCount = 2;
        const mainAxisCount = 1;
        const crossAxisSpacing = 16.0;
        const mainAxisSpacing = 16.0;
        final childWidth = (totalWidth - crossAxisSpacing * (crossAxisCount -1)) / crossAxisCount;
        final childHeight = totalHeight;
        final aspectRatio = childWidth / childHeight > 0 ? childWidth / childHeight : 1.0;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            childAspectRatio: aspectRatio,
          ),
          itemCount: 1,
          itemBuilder: (context, index) {
            final String gaugeId = 'aux_$index';
            final gaugeConfig = config.gaugeConfigs[gaugeId];

            if (gaugeConfig == null) return const Card(child: Center(child: Text('Ayar Yok')));

            return Selector<DataProvider, double>(
              selector: (_, provider) =>
                  index < provider.deviceData.auxData.length
                      ? provider.deviceData.auxData[index].toDouble()
                      : gaugeConfig.minValue,
              builder: (context, value, child) {
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
  }
  
  // 5 adet indikatörü oluşturan yardımcı metot
  Widget _buildIndicatorsSection(AppConfig config) {
    const int startIndex = 2;
    const int indicatorCount = 6;

    return Row(
      children: List.generate(indicatorCount, (index) {
        final int auxIndex = startIndex + index; // 2, 3, 4, 5, 6
        final String gaugeId = 'aux_$auxIndex';
        final gaugeConfig = config.gaugeConfigs[gaugeId];

        if (gaugeConfig == null) return const Expanded(child: Card(child: Center(child: Text('Ayar Yok'))));

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < indicatorCount - 1 ? 16.0 : 0.0),
            child: Selector<DataProvider, int>(
              selector: (_, provider) =>
                  auxIndex < provider.deviceData.auxData.length
                      ? provider.deviceData.auxData[auxIndex]
                      : 0,
              builder: (context, value, _) {
                return IndicatorCard(
                  key: ValueKey(gaugeId),
                  label: gaugeConfig.label,
                  isActive: value == 1,
                );
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRollPitchGroup(
    BuildContext context, {
    required String title,
    required double roll,
    required double pitch,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        _buildLabeledValue(context, label: 'ROLL', value: roll),
        const SizedBox(height: 8),
        _buildLabeledValue(context, label: 'PITCH', value: pitch),
      ],
    );
  }

  Widget _buildLabeledValue(
    BuildContext context, {
    required String label,
    required double value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 20,
        )),
        const SizedBox(height: 4),
        Container(
          width: 180,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade400),
          ),
          alignment: Alignment.center,
          child: Text(
            value.toStringAsFixed(2),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 32
            ),
          ),
        ),
      ],
    );
  }
}
