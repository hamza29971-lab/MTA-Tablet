// lib/ui/widgets/analog_gauge_grid.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/config_provider.dart';
import '../../providers/data_provider.dart';
import 'gauge_card.dart';

class AnalogGaugeGrid extends StatelessWidget {
  // Artık başlangıç indeksi yerine, gösterilecek indekslerin bir listesini alıyor
  final List<int> indices;

  const AnalogGaugeGrid({
    super.key,
    required this.indices,
  });

  @override
  Widget build(BuildContext context) {
    final config = context.read<ConfigurationProvider>().appConfig;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final totalHeight = constraints.maxHeight;

          if (totalHeight <= 0 || totalWidth <= 0) {
            return const SizedBox.shrink();
          }

          final crossAxisCount = indices.length > 4 ? 4 : 2; //4;
          // Satır sayısını, gösterilecek öğe sayısına göre dinamik olarak hesapla (en fazla 2)
          final mainAxisCount = 2; //(indices.length / crossAxisCount).ceil().clamp(1, 2);
          const crossAxisSpacing = 12.0;
          const mainAxisSpacing = 12.0;

          final childWidth = (totalWidth - (crossAxisSpacing * (crossAxisCount - 1))) / crossAxisCount;
          final childHeight = (totalHeight - (mainAxisSpacing * (mainAxisCount - 1))) / mainAxisCount;
          
          final aspectRatio = childWidth / childHeight > 0 ? childWidth / childHeight : 1.0;

          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: crossAxisSpacing,
              mainAxisSpacing: mainAxisSpacing,
              childAspectRatio: aspectRatio,
            ),
            // Gösterilecek öğe sayısı, kendisine verilen listenin uzunluğudur
            itemCount: indices.length,
            itemBuilder: (context, index) {
              // Gösterilecek gerçek analog indeksi listeden al
              final actualIndex = indices[index];
              final String gaugeId = 'analog_$actualIndex';
              final gaugeConfig = config.gaugeConfigs[gaugeId]!;

              return Selector<DataProvider, double>(
                selector: (_, provider) =>
                    actualIndex < provider.deviceData.analogData.length
                        ? provider.deviceData.analogData[actualIndex].toDouble()
                        : gaugeConfig.minValue,
                builder: (context, analogValue, child) {
                  return GaugeCard(
                    key: ValueKey(gaugeId),
                    label: gaugeConfig.label,
                    unit: gaugeConfig.unit,
                    value: analogValue,
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
