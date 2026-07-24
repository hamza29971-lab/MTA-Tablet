// lib/models/app_config.dart

// Uygulamadaki HER BİR gösterge için genel yapılandırma modeli
class GaugeConfig {
  final String id; // Benzersiz kimlik (örn: "analog_0", "aux_0")
  String label;
  String unit;
  double minValue;
  double maxValue;
  double warningValue; // YENİ: Sarı alanın başlangıcı
  double criticalValue;
  final bool isLabelEditable; // Etiket değiştirilebilir mi? (örn: RPM için false)

  GaugeConfig({
    required this.id,
    required this.label,
    required this.unit,
    required this.minValue,
    required this.maxValue,
    required this.warningValue, // YENİ
    required this.criticalValue,
    this.isLabelEditable = true, // Varsayılan olarak etiketler değiştirilebilir
  });

  factory GaugeConfig.fromJson(Map<String, dynamic> json) {
    return GaugeConfig(
      id: json['id'],
      label: json['label'],
      unit: json['unit'],
      minValue: (json['minValue'] as num).toDouble(),
      maxValue: (json['maxValue'] as num).toDouble(),
      warningValue: (json['warningValue'] as num? ?? 0.0).toDouble(), // YENİ
      criticalValue: (json['criticalValue'] as num).toDouble(),
      isLabelEditable: json['isLabelEditable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'unit': unit,
      'minValue': minValue,
      'maxValue': maxValue,
      'warningValue': warningValue, // YENİ
      'criticalValue': criticalValue,
      'isLabelEditable': isLabelEditable,
    };
  }
}

// Tüm uygulama yapılandırmasını tutan ana sınıf
class AppConfig {
  // Benzersiz ID'lere göre tüm gösterge ayarlarını tutan Map
  final Map<String, GaugeConfig> gaugeConfigs;
  final int machineRollAnalogIndex;
  final int machinePitchAnalogIndex;
  final int towerRollAnalogIndex;
  final int towerPitchAnalogIndex;

  // YENİ: Anasayfadaki 6 göstergenin ID'lerini tutan liste
  final List<String> homePageGaugeIds;

  AppConfig({
    required this.gaugeConfigs,
    required this.machineRollAnalogIndex,
    required this.machinePitchAnalogIndex,
    required this.towerRollAnalogIndex,
    required this.towerPitchAnalogIndex,
    required this.homePageGaugeIds,
  });

  // Uygulamanın ilk açılışındaki varsayılan ayarlar
  factory AppConfig.initial() {
    Map<String, GaugeConfig> configs = {
      // --- ANALOG GİRİŞLER (16 Adet) ---
      'analog_0': GaugeConfig(id: 'analog_0', label: 'ANA POMPA BASINCI', unit: 'Bar', minValue: 0, maxValue: 340, warningValue: 250, criticalValue: 300),
      'analog_1': GaugeConfig(id: 'analog_1', label: 'SERVİS & ÇAMUR POMPA BASINCI', unit: 'Bar', minValue: 0, maxValue: 250, warningValue: 170, criticalValue: 200),
      'analog_2': GaugeConfig(id: 'analog_2', label: 'SERVİS POMPA BASINCI', unit: 'Bar', minValue: 0, maxValue: 250, warningValue: 185, criticalValue: 200),
      'analog_3': GaugeConfig(id: 'analog_3', label: 'BASKI BASINCI', unit: 'Bar', minValue: 0, maxValue: 270, warningValue: 200, criticalValue: 245),
      'analog_4': GaugeConfig(id: 'analog_4', label: 'ASKI BASINCI', unit: 'Bar', minValue: 0, maxValue: 270, warningValue: 200, criticalValue: 240),
      'analog_5': GaugeConfig(id: 'analog_5', label: 'MORSET YAĞLAMA', unit: 'Bar', minValue: 0, maxValue: 50, warningValue: 15, criticalValue: 25),
      'analog_6': GaugeConfig(id: 'analog_6', label: 'ANA VİNÇ ÇEKME KUVVETİ', unit: 'Bar', minValue: 0, maxValue: 320, warningValue: 200, criticalValue: 250),
      'analog_7': GaugeConfig(id: 'analog_7', label: 'ROTASYON TORK', unit: 'Bar', minValue: 0, maxValue: 320, warningValue: 250, criticalValue: 270),
      'analog_8': GaugeConfig(id: 'analog_8', label: 'WİRELİNE VİNÇ', unit: 'Bar', minValue: 0, maxValue: 320, warningValue: 180, criticalValue: 190),
      'analog_9': GaugeConfig(id: 'analog_9', label: 'ÇAMUR SU BASINCI', unit: 'Bar', minValue: 0, maxValue: 320, warningValue: 170, criticalValue: 200),
      'analog_10': GaugeConfig(id: 'analog_10', label: 'ROTASYON İLERLEME', unit: '', minValue: 0, maxValue: 350, warningValue: 330, criticalValue: 340),
      'analog_11': GaugeConfig(id: 'analog_11', label: 'SU LİTRE', unit: '', minValue: 0, maxValue: 15000, warningValue: 10000, criticalValue: 12000),
      // Son 4 değer eğim (inklinometre) sensörü - değerler -90 ile +90 arasında
      'analog_12': GaugeConfig(id: 'analog_12', label: 'MAKİNE ROLL', unit: '°', minValue: -90, maxValue: 90, warningValue: 30, criticalValue: 45),
      'analog_13': GaugeConfig(id: 'analog_13', label: 'MAKİNE PİTCH', unit: '°', minValue: -90, maxValue: 90, warningValue: 30, criticalValue: 45),
      'analog_14': GaugeConfig(id: 'analog_14', label: 'KULE ROLL', unit: '°', minValue: -90, maxValue: 90, warningValue: 30, criticalValue: 45),
      'analog_15': GaugeConfig(id: 'analog_15', label: 'KULE PİTCH', unit: '°', minValue: -90, maxValue: 90, warningValue: 30, criticalValue: 45),

      // --- YARDIMCI GÖSTERGELER (Sanal, diğer ID'lerden hesaplanır) ---
      'aux_0': GaugeConfig(id: 'aux_0', label: 'ROTASYON DEVİR', unit: 'RPM', minValue: 0, maxValue: 1300, warningValue: 1250, criticalValue: 1250, isLabelEditable: false),
      'aux_1': GaugeConfig(id: 'aux_1', label: 'SPT VURUŞ', unit: '', minValue: 0, maxValue: 50, warningValue: 50, criticalValue: 50, isLabelEditable: false),
      // Binary göstergeler (0=Kapatık, 1=Açık/Aktif): criticalValue=1 → aktif olunca kırmızı gösterir
      'aux_2': GaugeConfig(id: 'aux_2', label: 'HİDROLİK SICAKLIK', unit: '', minValue: 0, maxValue: 1, warningValue: 1, criticalValue: 1),
      'aux_3': GaugeConfig(id: 'aux_3', label: 'FİLTRE 1', unit: '', minValue: 0, maxValue: 1, warningValue: 1, criticalValue: 1),
      'aux_4': GaugeConfig(id: 'aux_4', label: 'FİLTRE 2', unit: '', minValue: 0, maxValue: 1, warningValue: 1, criticalValue: 1),
      'aux_5': GaugeConfig(id: 'aux_5', label: 'HİDROLİK SEVİYE', unit: '', minValue: 0, maxValue: 1, warningValue: 1, criticalValue: 1),
      'aux_6': GaugeConfig(id: 'aux_6', label: 'ACİL İSTOP', unit: '', minValue: 0, maxValue: 1, warningValue: 1, criticalValue: 1),
      'aux_7': GaugeConfig(id: 'aux_7', label: 'MORSED MUHAFAZA', unit: '', minValue: 0, maxValue: 1, warningValue: 1, criticalValue: 1),

      // --- CAN BUS GÖSTERGELERİ (7 Adet) ---
      'can_engine_speed': GaugeConfig(id: 'can_engine_speed', label: 'MOTOR DEVRİ', unit: 'RPM', minValue: 0, maxValue: 2600, warningValue: 2250, criticalValue: 2400, isLabelEditable: false),
      'can_oil_pressure': GaugeConfig(id: 'can_oil_pressure', label: 'MOTOR YAĞ BASINCI', unit: 'Bar', minValue: 0, maxValue: 100, warningValue: 60, criticalValue: 80, isLabelEditable: false),
      'can_coolant_temp': GaugeConfig(id: 'can_coolant_temp', label: 'MOTOR HARARET', unit: '°C', minValue: 0, maxValue: 150, warningValue: 105, criticalValue: 120, isLabelEditable: false),
      'can_oil_temp': GaugeConfig(id: 'can_oil_temp', label: 'MOTOR YAĞ SICAKLIĞI', unit: '°C', minValue: 0, maxValue: 100, warningValue: 60, criticalValue: 80, isLabelEditable: false),
      'can_fuel_temp': GaugeConfig(id: 'can_fuel_temp', label: 'MAZOT SICAKLIĞI', unit: '°C', minValue: 0, maxValue: 220, warningValue: 220, criticalValue: 220, isLabelEditable: false),
      // Yakıt seviyesi göstergesi için warningValue = 40 (yeşil altı), criticalValue = 20 (kırmızı üstü)
      // Renkleri tersine çevirmek için gauge_card.dart içinde ek bir mantık yazacağız. 
      // Değerleri normal olarak: warningValue: 40, criticalValue: 20 verelim. Veya tam tersini verip renkleri elle çizdirelim.
      'can_fuel_level_1': GaugeConfig(id: 'can_fuel_level_1', label: 'YAKIT SEVİYESİ 1', unit: '%', minValue: 0, maxValue: 100, warningValue: 60, criticalValue: 80, isLabelEditable: false),
      'can_fuel_level_2': GaugeConfig(id: 'can_fuel_level_2', label: 'YAKIT SEVİYESİ 2', unit: '%', minValue: 0, maxValue: 100, warningValue: 60, criticalValue: 80, isLabelEditable: false),
    };
    
        return AppConfig(
      gaugeConfigs: configs,
      // Varsayılan olarak ilk 4 analog girişi atıyoruz
        machineRollAnalogIndex: 12,  // analog_12 = Makine Roll
      machinePitchAnalogIndex: 13,  // analog_13 = Makine Pitch
      towerRollAnalogIndex: 14,     // analog_14 = Kule Roll
      towerPitchAnalogIndex: 15,    // analog_15 = Kule Pitch
      homePageGaugeIds: [
        'analog_7', // Rotasyon Tork
        'aux_0', // Rotasyon Devir
        'analog_10', // Rotasyon İlerleme
        'analog_4', // Askı Basıncı
        'analog_9', // Çamur Su Basıncı
        'analog_11', // Su Litre
      ],
    );
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    // 1. Önce tüm varsayılan ayarları içeren bir başlangıç konfigürasyonu oluşturuyoruz.
    final defaultConfig = AppConfig.initial();

    // 2. Kaydedilmiş konfigürasyon JSON'ını alıyoruz.
    Map<String, dynamic> savedConfigsJson = json['gaugeConfigs'] ?? {};
    
    // 3. Kaydedilmiş her bir ayarı döngüye alıp, varsayılanın üzerine yazıyoruz.
    savedConfigsJson.forEach((key, savedValueJson) {
      if (defaultConfig.gaugeConfigs.containsKey(key)) {
        final savedGauge = GaugeConfig.fromJson(savedValueJson);
        final defaultGauge = defaultConfig.gaugeConfigs[key]!;
        
        // ZORUNLU GÜNCELLEME: İsimleri ve üniteleri kayıtlıdan al, ancak
        // Sınır değerlerini HER ZAMAN koddan (varsayılan) al!
        savedGauge.minValue = defaultGauge.minValue;
        savedGauge.maxValue = defaultGauge.maxValue;
        savedGauge.warningValue = defaultGauge.warningValue;
        savedGauge.criticalValue = defaultGauge.criticalValue;

        if (key == 'analog_7' && savedGauge.label.toLowerCase().contains('pilot')) {
          savedGauge.label = 'Rotasyon Tork';
        }

        defaultConfig.gaugeConfigs[key] = savedGauge;
      }
    });

    List<String> loadedHomePageIds = List<String>.from(json['homePageGaugeIds'] ?? defaultConfig.homePageGaugeIds);


    return AppConfig(
      gaugeConfigs: defaultConfig.gaugeConfigs,
      machineRollAnalogIndex: json['machineRollAnalogIndex'] ?? 0,
      machinePitchAnalogIndex: json['machinePitchAnalogIndex'] ?? 1,
      towerRollAnalogIndex: json['towerRollAnalogIndex'] ?? 2,
      towerPitchAnalogIndex: json['towerPitchAnalogIndex'] ?? 3,
      homePageGaugeIds: loadedHomePageIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gaugeConfigs': gaugeConfigs.map((key, value) => MapEntry(key, value.toJson())),
      'machineRollAnalogIndex': machineRollAnalogIndex,
      'machinePitchAnalogIndex': machinePitchAnalogIndex,
      'towerRollAnalogIndex': towerRollAnalogIndex,
      'towerPitchAnalogIndex': towerPitchAnalogIndex,
      'homePageGaugeIds': homePageGaugeIds
    };
  }
}
