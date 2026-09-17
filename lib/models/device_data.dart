import 'dart:convert';

import 'package:equatable/equatable.dart';

// ------------------- Ana Veri Modeli -------------------
class DeviceData extends Equatable {
  final int boxId;
  final CanData canData;
  // DEĞİŞİKLİK: canDtcData alanı artık nullable değil.
  final CanDtcData canDtcData;
  final List<double> analogData;
  final List<int> auxData;
  final SensorData sensorData;
  final SysInfo sysInfo;

  const DeviceData({
    required this.boxId,
    required this.canData,
    required this.canDtcData, // DEĞİŞİKLİK: Artık required.
    required this.analogData,
    required this.auxData,
    required this.sensorData,
    required this.sysInfo,
  });

  // Veri gelmeden önce arayüzde gösterilecek başlangıç/boş veri
  factory DeviceData.initial() {
    return DeviceData(
      boxId: 0,
      canData: CanData.initial(),
      canDtcData: CanDtcData.initial(),
      analogData: List.filled(16, 0),
      auxData: List.filled(16, 0),
      sensorData: SensorData.initial(),
      sysInfo: SysInfo.initial(),
    );
  }

  // Gelen JSON'dan ana nesneyi oluşturan fabrika metodu
  factory DeviceData.fromJson(Map<String, dynamic> json) {
    try {
      return DeviceData(
        boxId: json['box_id'] ?? 0,
        canData: CanData.fromJson(json['can_data'] ?? {}),
        // DEĞİŞİKLİK: Null kontrolü kaldırıldı, nesne her zaman parse edilecek.
        canDtcData: CanDtcData.fromJson(json['can_dtc_data'] ?? {}),
        analogData: List<double>.from(json['analog_data'] ?? []),
        auxData: () {
          var list = List<int>.from(json['aux_data'] ?? []);
          if (list.isNotEmpty) {
            list[0] = list[0] ~/ 2;
          }
          return list;
        }(),
        sensorData: SensorData.fromJson(json['sensor_data'] ?? {}),
        sysInfo: SysInfo.fromJson(json['sys_info'] ?? {}),
      );
    } catch (ex) {
      print(ex);
      return DeviceData(
        boxId: json['box_id'] ?? 0,
        canData: CanData.fromJson(json['can_data'] ?? {}),
        // DEĞİŞİKLİK: Null kontrolü kaldırıldı, nesne her zaman parse edilecek.
        canDtcData: CanDtcData.fromJson(json['can_dtc_data'] ?? {}),
        analogData: List<double>.from(json['analog_data'] ?? []),
        auxData: () {
          var list = List<int>.from(json['aux_data'] ?? []);
          if (list.isNotEmpty) {
            list[0] = list[0] ~/ 2;
          }
          return list;
        }(),
        sensorData: SensorData.fromJson(json['sensor_data'] ?? {}),
        sysInfo: SysInfo.fromJson(json['sys_info'] ?? {}),
      );
    }
  }

  @override
  List<Object?> get props => [
    boxId,
    canData,
    canDtcData,
    analogData,
    auxData,
    sensorData,
    sysInfo,
  ];
}

// ------------------- Alt Modeller (Değişiklik yok) -------------------

// 'can_data' nesnesi için model
class CanData extends Equatable {
  final int manufacturerCode;
  final double batteryPotential;
  final double engineSpeed;
  final double engineOilPressure;
  final double engineCoolantTemperature;
  final double engineOilTemperature;
  final double engineFuelTemperature;
  final double fuelLevel1;
  final double fuelLevel2;
  final double engineTotalHoursOfOperation;

  const CanData({
    required this.manufacturerCode,
    required this.batteryPotential,
    required this.engineSpeed,
    required this.engineOilPressure,
    required this.engineCoolantTemperature,
    required this.engineOilTemperature,
    required this.engineFuelTemperature,
    required this.fuelLevel1,
    required this.fuelLevel2,
    required this.engineTotalHoursOfOperation,
  });

  factory CanData.initial() => CanData(
    manufacturerCode: 0,
    batteryPotential: 0,
    engineSpeed: 0,
    engineOilPressure: 0,
    engineCoolantTemperature: 0,
    engineOilTemperature: 0,
    engineFuelTemperature: 0,
    fuelLevel1: 0,
    fuelLevel2: 0,
    engineTotalHoursOfOperation: 0,
  );

  factory CanData.fromJson(Map<String, dynamic> json) {
    return CanData(
      manufacturerCode: json['CAN_Manufacturer_Code'] ?? 0,
      batteryPotential: (json['CAN_Battery_Potential']  ?? 0).toDouble(),
      engineSpeed: (json['CAN_Engine_Speed'] ?? 0).toDouble(),
      engineOilPressure: (json['CAN_Engine_Oil_Pressure'] ?? 0).toDouble(),
      engineCoolantTemperature: (json['CAN_Engine_Coolant_Temperature'] ?? 0).toDouble(),
      engineOilTemperature: (json['CAN_Engine_Oil_Temperature'] ?? 0).toDouble(),
      engineFuelTemperature: (json['CAN_Engine_Fuel_Temperature'] ?? 0).toDouble(),
      fuelLevel1: (json['CAN_Fuel_Level_1'] ?? 0).toDouble(),
      fuelLevel2: (json['CAN_Fuel_Level_2'] ?? 0).toDouble(),
      engineTotalHoursOfOperation:
          (json['CAN_Engine_Total_Hours_Of_Operation'] ?? 0).toDouble(),
    );
  }
  @override
  List<Object?> get props => [
    manufacturerCode,
    batteryPotential,
    engineSpeed,
    engineOilPressure,
    engineCoolantTemperature,
    engineOilTemperature,
    engineFuelTemperature,
    fuelLevel1,
    fuelLevel2,
    engineTotalHoursOfOperation,
  ];
}

// 'can_dtc_data' nesnesi için model
class CanDtcData extends Equatable {
  final int flashLampAmberWarning;
  final int flashLampMalfunctionIndicator;
  final int flashLampProtectLamp;
  final int flashLampRedStop;
  final int lampStatusAmberWarning;
  final int lampStatusMalfunctionIndicator;
  final int lampStatusProtectLamp;
  final int lampStatusRedStop;
  final int dtcCount;
  final List<Dtc> dtcs;

  const CanDtcData({
    required this.flashLampAmberWarning,
    required this.flashLampMalfunctionIndicator,
    required this.flashLampProtectLamp,
    required this.flashLampRedStop,
    required this.lampStatusAmberWarning,
    required this.lampStatusMalfunctionIndicator,
    required this.lampStatusProtectLamp,
    required this.lampStatusRedStop,
    required this.dtcCount,
    required this.dtcs,
  });

  factory CanDtcData.initial() => CanDtcData(
    flashLampAmberWarning: 0,
    flashLampMalfunctionIndicator: 0,
    flashLampProtectLamp: 0,
    flashLampRedStop: 0,
    lampStatusAmberWarning: 0,
    lampStatusMalfunctionIndicator: 0,
    lampStatusProtectLamp: 0,
    lampStatusRedStop: 0,
    dtcCount: 0,
    dtcs: [],
  );

  factory CanDtcData.fromJson(Map<String, dynamic> json) {
    // Bu kısım dtcs listesinin boş/null gelme durumunu doğru şekilde yönetmeye devam ediyor.
    var dtcList =
        (json['dtcs'] as List<dynamic>?)
            ?.map((e) => Dtc.fromJson(e))
            .toList() ??
        [];

    return CanDtcData(
      flashLampAmberWarning: json['flash_lamp_amber_warning'] ?? 0,
      flashLampMalfunctionIndicator:
          json['flash_lamp_malfunction_indicator'] ?? 0,
      flashLampProtectLamp: json['flash_lamp_protect_lamp'] ?? 0,
      flashLampRedStop: json['flash_lamp_red_stop'] ?? 0,
      lampStatusAmberWarning: json['lamp_status_amber_warning'] ?? 0,
      lampStatusMalfunctionIndicator:
          json['lamp_status_malfunction_indicator'] ?? 0,
      lampStatusProtectLamp: json['lamp_status_protect_lamp'] ?? 0,
      lampStatusRedStop: json['lamp_status_red_stop'] ?? 0,
      dtcCount: json['dtc_count'] ?? 0,
      dtcs: dtcList,
    );
  }
  @override
  List<Object?> get props => [
    flashLampAmberWarning,
    flashLampMalfunctionIndicator,
    flashLampProtectLamp,
    flashLampRedStop,
    lampStatusAmberWarning,
    lampStatusMalfunctionIndicator,
    lampStatusProtectLamp,
    lampStatusRedStop,
    dtcs,
  ];
}

// 'dtcs' listesindeki her bir hata kodu nesnesi için model
class Dtc extends Equatable {
  final int spn;
  final int fmi;
  final int occurrenceCount;

  const Dtc({
    required this.spn,
    required this.fmi,
    required this.occurrenceCount,
  });

  factory Dtc.fromJson(Map<String, dynamic> json) {
    return Dtc(
      spn: json['spn'] ?? 0,
      fmi: json['fmi'] ?? 0,
      occurrenceCount: json['occurence_count'] ?? 0,
    );
  }
  @override
  List<Object?> get props => [spn, fmi, occurrenceCount];
}

// 'sensor_data' nesnesi için model
class SensorData extends Equatable {
  final bool isImuConnected;
  final double vehicleHeading;
  final double vehicleRoll;
  final double vehiclePitch;
  final double towerRoll;
  final double towerPitch;
  final double latitude;
  final double longitude;

  const SensorData({
    required this.isImuConnected,
    required this.vehicleHeading,
    required this.vehicleRoll,
    required this.vehiclePitch,
    required this.towerRoll,
    required this.towerPitch,
    required this.latitude,
    required this.longitude,
  });

  factory SensorData.initial() => SensorData(
    isImuConnected: false,
    vehicleHeading: 0.0,
    vehicleRoll: 0.0,
    vehiclePitch: 0.0,
    towerRoll: 0.0,
    towerPitch: 0.0,
    latitude: 0.0,
    longitude: 0.0,
  );

  factory SensorData.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val) => val is num ? val.toDouble() : 0.0;

    return SensorData(
      isImuConnected: json['is_imu_connected'] ?? false,
      vehicleHeading: toDouble(json['vehicle_heading']),
      vehicleRoll: toDouble(json['vehicle_roll']),
      vehiclePitch: toDouble(json['vehicle_pitch']),
      towerRoll: toDouble(json['tower_roll']),
      towerPitch: toDouble(json['tower_pitch']),
      latitude: toDouble(json['Vehicle_Location_Lat'] ?? json['latitude']),
      longitude: toDouble(json['Vehicle_Location_Lon'] ?? json['longitude']),
    );
  }
  @override
  List<Object?> get props => [
    isImuConnected,
    vehicleHeading,
    vehicleRoll,
    vehiclePitch,
    towerRoll,
    towerPitch,
    latitude,
    longitude,
  ];
}

// 'sys_info' nesnesi için model
class SysInfo extends Equatable {
  final String ramUsage;
  final String diskUsage;
  final int logFileCount;
  final int errorCode;
  final String errorFileSize;
  final int maxRaspiTemp;
  final int maxMcuTemp;
  final int maxAmbiTemp;

  const SysInfo({
    required this.ramUsage,
    required this.diskUsage,
    required this.logFileCount,
    required this.errorCode,
    required this.errorFileSize,
    required this.maxRaspiTemp,
    required this.maxMcuTemp,
    required this.maxAmbiTemp,
  });

  factory SysInfo.initial() => SysInfo(
    ramUsage: "N/A",
    diskUsage: "N/A",
    logFileCount: 0,
    errorCode: 0,
    errorFileSize: "N/A",
    maxRaspiTemp: 0,
    maxMcuTemp: 0,
    maxAmbiTemp: 0,
  );

  factory SysInfo.fromJson(Map<String, dynamic> json) {
    return SysInfo(
      ramUsage: json['ram_usage'] ?? 'N/A',
      diskUsage: json['disk_usage'] ?? 'N/A',
      logFileCount: json['log_file_count'] ?? 0,
      errorCode: json['error_code'] ?? 0,
      errorFileSize: json['error_file_size'] ?? 'N/A',
      maxRaspiTemp: json['max_raspi_temp'] ?? 0,
      maxMcuTemp: json['max_mcu_temp'] ?? 0,
      maxAmbiTemp: json['max_ambi_temp'] ?? 0,
    );
  }
  @override
  List<Object?> get props => [
    ramUsage,
    diskUsage,
    logFileCount,
    errorCode,
    errorFileSize,
    maxRaspiTemp,
    maxMcuTemp,
    maxAmbiTemp,
  ];
}
