// lib/ui/tabs/dtc_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/device_data.dart';
import '../../providers/data_provider.dart';

class DtcTab extends StatelessWidget {
  const DtcTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Selector ile sadece canDtcData nesnesi değiştiğinde bu widget yeniden çizilir.
    return Selector<DataProvider, CanDtcData>(
      selector: (_, provider) => provider.deviceData.canDtcData,
      builder: (context, canDtcData, _) {
        final dtcs = canDtcData.dtcs;

        // Hata kodu yoksa bilgilendirme mesajı göster.
        if (dtcs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                SizedBox(height: 16),
                Text('Aktif Hata Kodu Bulunmuyor', style: TextStyle(fontSize: 24)),
              ],
            ),
          );
        }

        // Hata kodları varsa, listeyi göster.
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üstteki lamba durum göstergeleri
              _buildLampStatusGrid(context, canDtcData),
              const SizedBox(height: 24),
              const Divider(thickness: 1.5),
              const SizedBox(height: 24),
              // Hata kartlarını esnek bir şekilde saran Wrap widget'ı
              Wrap(
                spacing: 16.0,      // Kartlar arası yatay boşluk
                runSpacing: 16.0,     // Kartlar arası dikey boşluk
                alignment: WrapAlignment.center, // Kartları ortala
                children: dtcs.map((dtc) => _DtcCard(dtc: dtc)).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // Lamba durum göstergelerini oluşturan yardımcı metot
  Widget _buildLampStatusGrid(BuildContext context, CanDtcData canDtcData) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLampStatusIndicator(
          context,
          label: 'Amber Uyarı',
          status: canDtcData.lampStatusAmberWarning,
          color: Colors.amber.shade700,
        ),
        _buildLampStatusIndicator(
          context,
          label: 'Kırmızı Stop',
          status: canDtcData.lampStatusRedStop,
          color: Colors.red.shade700,
        ),
        _buildLampStatusIndicator(
          context,
          label: 'Arıza Göstergesi',
          status: canDtcData.lampStatusMalfunctionIndicator,
          color: Colors.orange.shade700,
        ),
        _buildLampStatusIndicator(
          context,
          label: 'Koruma Lambası',
          status: canDtcData.lampStatusProtectLamp,
          color: Colors.blue.shade700,
        ),
      ],
    );
  }

  // Tek bir lamba durum göstergesi oluşturan metot
  Widget _buildLampStatusIndicator(BuildContext context, {
    required String label,
    required int status,
    required Color color,
  }) {
    // Gelen değere göre lambanın açık olup olmadığını belirle (1: açık, diğerleri: kapalı)
    final bool isOn = status == 1;

    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        CircleAvatar(
          radius: 25,
          backgroundColor: isOn ? color : Colors.grey.shade400,
          child: Icon(
            isOn ? Icons.warning_amber : Icons.power_settings_new,
            color: Colors.white,
            size: 30,
          ),
        ),
      ],
    );
  }
}

// Tek bir DTC hata kodunu gösteren özel Card widget'ı (private)
class _DtcCard extends StatelessWidget {
  final Dtc dtc;

  const _DtcCard({required this.dtc});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.orange.shade700, width: 1.5),
      ),
      color: Colors.orange.shade50,
      child: Container(
        width: 220, // Kartların genişliğini belirleyerek sığdırmayı kontrol et
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'HATA KODU',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.black54),
            ),
            const Divider(),
            _buildInfoRow('SPN:', dtc.spn.toString()),
            const SizedBox(height: 8),
            _buildInfoRow('FMI:', dtc.fmi.toString()),
            const SizedBox(height: 8),
            _buildInfoRow('Tekrar Sayısı:', dtc.occurrenceCount.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
