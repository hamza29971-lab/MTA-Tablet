// lib/ui/tabs/analog_pages.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_config.dart'; // AppConfig'i import ediyoruz
import '../../providers/config_provider.dart';
import '../widgets/analog_gauge_grid.dart';

// İlk analog sayfa
class AnalogTabPage1 extends StatelessWidget {
  const AnalogTabPage1({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ DEĞİŞİKLİK: 'watch' kullanarak provider'daki değişiklikleri dinliyoruz.
    final config = context.watch<ConfigurationProvider>().appConfig;
    
    // Filtrelenmiş indeks listesini al
    final displayableIndices = _getDisplayableIndices(config);

    // Listeyi ikiye böl ve ilk yarısını al
    final int itemsPerPage = (displayableIndices.length / 2).ceil();
    final int firstPageItemCount = 8;
    // final List<int> pageIndices = displayableIndices.take(itemsPerPage).toList();
    final List<int> pageIndices = displayableIndices.take(firstPageItemCount).toList();

    return AnalogGaugeGrid(indices: pageIndices);
  }
}

// İkinci analog sayfa
class AnalogTabPage2 extends StatelessWidget {
  const AnalogTabPage2({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ DEĞİŞİKLİK: 'watch' kullanarak provider'daki değişiklikleri dinliyoruz.
    final config = context.watch<ConfigurationProvider>().appConfig;
    
    // Filtrelenmiş indeks listesini al
    final displayableIndices = _getDisplayableIndices(config);

    // Listeyi ikiye böl ve ikinci yarısını al
    final int itemsPerPage = (displayableIndices.length / 2).ceil();
    final int firstPageItemCount = 8;
    // final List<int> pageIndices = displayableIndices.skip(itemsPerPage).toList();
    final List<int> pageIndices = displayableIndices.skip(firstPageItemCount).toList();

    return AnalogGaugeGrid(indices: pageIndices);
  }
}

// Tekrarlanan kodu önlemek için ortak filtreleme fonksiyonu
// ✅ DEĞİŞİKLİK: Fonksiyon artık BuildContext yerine doğrudan AppConfig alıyor.
List<int> _getDisplayableIndices(AppConfig config) {
  // Eğim sensörü olarak kullanılan indeksleri bir set'e koy
  final excludedIndices = {
    config.machineRollAnalogIndex,
    config.machinePitchAnalogIndex,
    config.towerRollAnalogIndex,
    config.towerPitchAnalogIndex,
  };

  // Tüm 16 indeksi oluştur ve hariç tutulanları çıkar
  final allIndices = List.generate(16, (i) => i);
  final displayableIndices = allIndices.where((i) => !excludedIndices.contains(i)).toList();

  return displayableIndices;
}
