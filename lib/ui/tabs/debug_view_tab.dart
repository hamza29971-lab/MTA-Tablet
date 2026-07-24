// lib/ui/tabs/debug_view_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/data_provider.dart';

class DebugViewTab extends StatelessWidget {
  const DebugViewTab({super.key});

  // Başlıklar için yardımcı bir widget metodu
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 8.0, right: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  // Key-Value çiftleri için yardımcı bir widget metodu
  Widget _buildInfoTile(String label, String value) {
    return ListTile(
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      dense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Provider'dan en güncel veriyi al ve değişiklikleri dinle
    final deviceData = context.watch<DataProvider>().deviceData;

    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        Card(
          child: _buildInfoTile('Box ID', deviceData.boxId.toString()),
        ),

        // --- CAN Verileri Bölümü ---
        _buildSectionHeader(context, 'CAN Verileri'),
        Card(
          child: Column(
            children: [
              _buildInfoTile('Üretici Kodu', deviceData.canData.manufacturerCode.toString()),
              _buildInfoTile('Akü Potansiyeli', deviceData.canData.batteryPotential.toString()),
              _buildInfoTile('Motor Hızı (RPM)', deviceData.canData.engineSpeed.toString()),
              _buildInfoTile('Motor Yağ Basıncı', deviceData.canData.engineOilPressure.toString()),
              _buildInfoTile('Motor Soğutma Sıvısı Sıcaklığı', deviceData.canData.engineCoolantTemperature.toString()),
              _buildInfoTile('Motor Yağ Sıcaklığı', deviceData.canData.engineOilTemperature.toString()),
              _buildInfoTile('Motor Yakıt Sıcaklığı', deviceData.canData.engineFuelTemperature.toString()),
              _buildInfoTile('Yakıt Seviyesi 1', deviceData.canData.fuelLevel1.toString()),
              _buildInfoTile('Yakıt Seviyesi 2', deviceData.canData.fuelLevel2.toString()),
              _buildInfoTile('Toplam Motor Çalışma Saati', deviceData.canData.engineTotalHoursOfOperation.toString()),
            ],
          ),
        ),

        // --- Sensör Verileri Bölümü ---
        _buildSectionHeader(context, 'Sensör Verileri'),
        Card(
          child: Column(
            children: [
              _buildInfoTile('IMU Bağlantısı', deviceData.sensorData.isImuConnected ? 'Bağlı' : 'Bağlı Değil'),
              _buildInfoTile('Araç Yönü (Heading)', deviceData.sensorData.vehicleHeading.toStringAsFixed(2)),
              _buildInfoTile('Araç Eğimi (Roll)', deviceData.sensorData.vehicleRoll.toStringAsFixed(2)),
              _buildInfoTile('Araç Yükselişi (Pitch)', deviceData.sensorData.vehiclePitch.toStringAsFixed(2)),
              _buildInfoTile('Kule Eğimi (Roll)', deviceData.sensorData.towerRoll.toStringAsFixed(2)),
              _buildInfoTile('Kule Yükselişi (Pitch)', deviceData.sensorData.towerPitch.toStringAsFixed(2)),
            ],
          ),
        ),

        // --- DTC Hata Kodları Bölümü ---
        if (deviceData.canDtcData != null) ...[
          _buildSectionHeader(context, 'DTC Hata Kodları'),
          Card(
            child: Column(
              children: [
                _buildInfoTile('DTC Sayısı', deviceData.canDtcData!.dtcCount.toString()),
                const Divider(),
                if (deviceData.canDtcData!.dtcs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Aktif DTC kodu bulunmuyor.'),
                  )
                else
                  // DTC listesini göster
                  ...deviceData.canDtcData!.dtcs.map((dtc) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('SPN: ${dtc.spn}'),
                          Text('FMI: ${dtc.fmi}'),
                          Text('Tekrar: ${dtc.occurrenceCount}'),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          )
        ],
        
        // --- Sistem Bilgileri Bölümü ---
        _buildSectionHeader(context, 'Sistem Bilgileri'),
        Card(
          child: Column(
            children: [
              _buildInfoTile('RAM Kullanımı', deviceData.sysInfo.ramUsage),
              _buildInfoTile('Disk Kullanımı', deviceData.sysInfo.diskUsage),
              _buildInfoTile('Log Dosya Sayısı', deviceData.sysInfo.logFileCount.toString()),
              _buildInfoTile('Hata Kodu', deviceData.sysInfo.errorCode.toString()),
              _buildInfoTile('Hata Dosya Boyutu', deviceData.sysInfo.errorFileSize),
              _buildInfoTile('Maks. Raspberry Pi Sıcaklığı', deviceData.sysInfo.maxRaspiTemp.toString()),
              _buildInfoTile('Maks. MCU Sıcaklığı', deviceData.sysInfo.maxMcuTemp.toString()),
              _buildInfoTile('Maks. Ortam Sıcaklığı', deviceData.sysInfo.maxAmbiTemp.toString()),
            ],
          ),
        ),

        // --- Analog ve Aux Veri Listeleri ---
        _buildSectionHeader(context, 'Analog Veri Listesi'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(deviceData.analogData.join(', '), textAlign: TextAlign.center),
          ),
        ),
        
        _buildSectionHeader(context, 'Aux Veri Listesi'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(deviceData.auxData.join(', '), textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }
}
