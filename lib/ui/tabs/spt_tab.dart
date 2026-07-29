import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../utils/app_dialogs.dart';

class SptRecord {
  final int deneyNo;
  final int vurusSayisi;
  final double toplamDerinlik;
  final double deneyDerinligiCm;

  SptRecord({
    required this.deneyNo,
    required this.vurusSayisi,
    required this.toplamDerinlik,
    required this.deneyDerinligiCm,
  });
}

class SptTab extends StatefulWidget {
  const SptTab({super.key});

  @override
  State<SptTab> createState() => _SptTabState();
}

class _SptTabState extends State<SptTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _toplamDerinlikCtrl = TextEditingController();
  String _yasMi = 'Hayır';
  String _sptOrnekleyici = 'İç Tüplü';
  final TextEditingController _yassCtrl = TextEditingController();
  
  bool _isRunning = false;
  int _currentDeney = 0; // 0: Başlamadı, 1: Deney 1, 2: Deney 2, 3: Deney 3, 4: Bitti
  int _currentVurus = 0;

  final List<SptRecord> _records = [];

  late DataProvider _dataProvider;
  int _previousVurusSignal = 0; // aux_1'in önceki durumu (0 veya 1)
  double _currentDerinlik = 0.0; // Otomatik derinlik verisi
  double _baslangicDerinlik = 0.0; // Deneyin başladığı anki referans derinlik

  // GPS Doğrulama için
  bool _isKuyuKonumDogru = false;
  
  // Örnek Kuyu Veritabanı
  final Map<String, Map<String, double>> _kuyuVeritabani = {
    'sk1': {'lat': 36.92139018, 'lon': 30.68032193}, // Test koordinatı
  };

  @override
  void initState() {
    super.initState();
    _dataProvider = context.read<DataProvider>();
    _dataProvider.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _dataProvider.removeListener(_onDataChanged);
    _toplamDerinlikCtrl.dispose();
    _yassCtrl.dispose();
    
    // Uygulamadan/sayfadan çıkılırken testi serbest bırak (eğer bu testse)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (_dataProvider.activeTestName == 'SPT Testi' &&
            !_dataProvider.isAppInBackground) {
          _dataProvider.stopTest();
        }
      }
    });

    super.dispose();
  }

  void _publishRecord(SptRecord r) {
    final dp = context.read<DataProvider>();

    final Map<String, dynamic> embeddedJson = {
      "TestTipi": "SPT Testi",
      "MesajTipi": "Kayit",
      "BoxID": dp.deviceData.boxId,
      "DeneyNo": r.deneyNo,
      "VurusSayisi": r.vurusSayisi,
      "ToplamDerinlik_m": r.toplamDerinlik,
      "SPT_Ornekleyicisi": _sptOrnekleyici,
      "YAS_VarMi": _yasMi,
      "YASS_m": _yasMi == 'Evet' ? (double.tryParse(_yassCtrl.text) ?? 0.0) : 0.0,
      "DeneyDerinligi_cm": r.deneyDerinligiCm,
    };

    final Map<String, dynamic> payloadMap = {
      'operator_name': dp.operatorName ?? 'Otomatik Sistem',
      'kuyu_name': '${dp.wellNo ?? "KUYU"} - SPT TESTİ ADIM ${r.deneyNo}',
      'operator_number': dp.registrationNo ?? '000',
      'team_name': 'Sondaj Ekibi',
      'fault_text': jsonEncode(embeddedJson),
      'fault_meter': r.toplamDerinlik
    };

    dp.sendUdpReport(payloadMap);
  }

  void _publishSummaryReportToUdp() {
    final dp = context.read<DataProvider>();
    
    List<Map<String, dynamic>> adimlar = [];
    for (var r in _records) {
      adimlar.add({
        "Adim": r.deneyNo,
        "VurusSayisi": r.vurusSayisi,
        "DeneyDerinligi_cm": r.deneyDerinligiCm,
      });
    }

    final Map<String, dynamic> embeddedJson = {
      "TestTipi": "SPT Testi",
      "MesajTipi": "Ozet",
      "BoxID": dp.deviceData.boxId,
      "ToplamDerinlik_m": double.tryParse(_toplamDerinlikCtrl.text) ?? 0.0,
      "SPT_Ornekleyicisi": _sptOrnekleyici,
      "YAS_VarMi": _yasMi,
      "YASS_m": _yasMi == 'Evet' ? (double.tryParse(_yassCtrl.text) ?? 0.0) : 0.0,
      "Adimlar": adimlar
    };

    final Map<String, dynamic> summaryMap = {
      'operator_name': dp.operatorName ?? 'Otomatik Sistem',
      'kuyu_name': '${dp.wellNo ?? "KUYU"} - SPT TESTİ ÖZET',
      'operator_number': dp.registrationNo ?? '000',
      'team_name': 'Sondaj Ekibi',
      'fault_text': jsonEncode(embeddedJson),
      'fault_meter': double.tryParse(_toplamDerinlikCtrl.text) ?? 0.0
    };
    
    dp.sendUdpReport(summaryMap);
  }

  void _onDataChanged() {
    final deviceData = _dataProvider.deviceData;

    // Toplam İlerleme otomatik olarak _finishStep çağrıldığında artırılacaktır.

    int currentSignal = deviceData.auxData.length > 1 ? deviceData.auxData[1] : 0;
    
    // Sinyal arttıysa yeni vuruş var (hem 0/1 toggle hem kümülatif sayaç için çalışır)
    if (currentSignal > _previousVurusSignal) {
      final yeniVurus = currentSignal - _previousVurusSignal;
      // Sadece test aktif durumdayken sayacı artırıyoruz
      if (_isRunning) {
        setState(() {
          _currentVurus += yeniVurus;
          _checkExperimentStatus();
        });
      }
    }
    _previousVurusSignal = currentSignal;

  }

  void _checkExperimentStatus() {
    if (!_isRunning) return;

    if (_currentVurus >= 50) {
      // Refü Durumu
      setState(() {
        _isRunning = false;
      });
      _showManualDepthDialog();
    }
  }

  void _startTest() {
    final List<String> eksik = [];
    if (_toplamDerinlikCtrl.text.trim().isEmpty) eksik.add('Derinlik (m)');
    if (_yasMi == 'Evet' && _yassCtrl.text.trim().isEmpty) eksik.add('YAS Giriniz');

    if (eksik.isNotEmpty) {
      AppDialogs.showStandardDialog(
        context,
        title: 'Eksik Bilgi',
        message: 'Lütfen başlatmadan önce şu alanları doldurun:\n\n• ${eksik.join("\n• ")}',
        color: Colors.orange,
        icon: Icons.info,
      );
      return;
    }

    if (context.read<DataProvider>().isAnyOtherTestRunning('SPT Testi')) {
      AppDialogs.showStandardDialog(
        context,
        title: 'Test Başlatılamaz',
        message: 'Şu anda başka bir sekmede aktif bir test devam ediyor. Lütfen önce onu sonlandırın.',
        color: Colors.red,
        icon: Icons.error,
      );
      return;
    }

    // TEST KİLİDİNİ BAŞLAT
    context.read<DataProvider>().startTest('SPT Testi');

    // Sensörün mevcut değerini referans al — test başlarken sinyal 1'deyse
    // ilk geçişi kaçırmaması için _previousVurusSignal güncelleniyor
    _previousVurusSignal = _dataProvider.deviceData.auxData.length > 1
        ? _dataProvider.deviceData.auxData[1]
        : 0;

    setState(() {
      if (_currentDeney == 0 || _currentDeney > 3) {
        _records.clear();
        _currentDeney = 1;
        _currentDerinlik = 0.0; // Yeni testte ilerleme sıfırlanır
      }
      _currentVurus = 0;
      _isRunning = true;
    });
  }

  void _stopTest() {
    if (!_isRunning) return;
    // Kullanıcı durdurduysa 15 cm tamamlandı kabul edilir.
    _finishStep(15.0);
  }

  void _finishStep(double depthCm) {
    setState(() {
      _isRunning = false;
      _currentDerinlik += (depthCm / 100.0);
      
      final rec = SptRecord(
        deneyNo: _currentDeney,
        vurusSayisi: _currentVurus,
        toplamDerinlik: double.tryParse(_toplamDerinlikCtrl.text) ?? 0.0,
        deneyDerinligiCm: depthCm,
      );
      _records.add(rec);
      _publishRecord(rec);

      // Eğer 3 aşama bittiyse veya test refü olup elle değer girildiyse (15 harici değer veya 50 vuruş)
      if (_currentDeney >= 3 || depthCm != 15.0 || _currentVurus >= 50) {
        _finishTestCompletely();
      } else {
        // Sonraki deneye geç, ama BAŞLAT'ı bekleyecek (isRunning false oldu bile)
        _currentDeney++;
        _currentVurus = 0;
      }
    });
  }

  void _showForceEndDialog() {
    AppDialogs.showConfirmDialog(
      context,
      title: 'Deneyi Sonlandır',
      message: 'Deneyi erken sonlandırmak üzeresiniz. Onaylıyor musunuz?',
      color: Colors.red,
      icon: Icons.warning,
      onConfirm: () => _finishTestCompletely(isForced: true),
      confirmText: 'Sonlandır',
    );
  }

  void _finishTestCompletely({bool isForced = false}) {
    _publishSummaryReportToUdp();
    
    AppDialogs.showStandardDialog(
      context,
      title: isForced ? 'Deney Sonlandırıldı' : 'Deney Tamamlandı',
      message: isForced ? 'Deney erken sonlandırıldı.\nSPT Testi raporu gönderildi.' : 'SPT testi başarıyla tamamlandı.\nSPT Testi raporu gönderildi.',
      color: isForced ? Colors.red : Colors.green,
      icon: isForced ? Icons.warning : Icons.check_circle,
      onConfirm: _resetEntireTest,
    );
  }

  void _resetEntireTest() {
    // TEST KİLİDİNİ KALDIR
    if (mounted) {
      context.read<DataProvider>().stopTest();
    }
    setState(() {
      _records.clear();
      _isRunning = false;
      _currentDeney = 0;
      _currentVurus = 0;
      _currentDerinlik = 0.0;
    });
  }

  void _showManualDepthDialog() {
    final TextEditingController cmCtrl = TextEditingController();
    AppDialogs.showCustomDialog(
      context,
      title: '50 Vuruşa Ulaşıldı (Refü)',
      color: Colors.orange,
      icon: Icons.warning,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('50 vuruşa ulaşıldığı için test otomatik durduruldu. Lütfen bu aşamada inilen toplam mesafeyi (cm) giriniz:', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 16),
          TextField(
            controller: cmCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 28),
            decoration: const InputDecoration(
              labelText: 'İlerleme (cm)',
              labelStyle: TextStyle(fontSize: 24),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            double cm = double.tryParse(cmCtrl.text) ?? 0.0;
            Navigator.of(context).pop();
            _finishStep(cm);
          },
          child: const Text('Tamam', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _incrementVurus() {
    // Manuel tıklama devre dışı bırakıldı. Vuruş sayısı sadece _onDataChanged içindeki aux_1 dijital girişinden artacak.
    // if (!_isRunning) return;
    // setState(() {
    //   _currentVurus++;
    //   _checkExperimentStatus();
    // });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final dataProvider = context.watch<DataProvider>();
    final bool isTestActive = dataProvider.activeTestName == 'SPT Testi';
    
    final bool isLocked = dataProvider.isSystemLocked;
    
    return Stack(
      children: [
        AbsorbPointer(
          absorbing: isLocked,
          child: Opacity(
            opacity: isLocked ? 0.4 : 1.0,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
          // ── ÜST: Göstergeler ve Butonlar ──
          SizedBox(
            height: 140,
            child: Row(
              children: [
                Expanded(child: GestureDetector(
                  onTap: _incrementVurus,
                  child: _buildInfoCard(_currentDeney > 0 ? 'Deney $_currentDeney Vuruş' : 'Vuruş Sayısı', Text(
                    '$_currentVurus', 
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)
                  )),
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoCard('Toplam SPT İlerleme (cm)', Text(
                  (_currentDerinlik * 100).toStringAsFixed(0),
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)
                ))),
                const SizedBox(width: 12),
                Expanded(child: _buildControlButtons()),
              ],
            ),
          ),
          const SizedBox(height: 16),
            // "Vuruş sayısının altına Derinlik (m) ve Yas evet hayır sekmesi."
            IgnorePointer(
              ignoring: isTestActive,
              child: Opacity(
                opacity: isTestActive ? 0.7 : 1.0,
                child: Row(
                  children: [
                    Expanded(child: _buildTextField('Derinlik (m)', _toplamDerinlikCtrl, isNumber: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDropdown('SPT Örnekleyicisi', _sptOrnekleyici, ['İç Tüplü', 'İç Tüpsüz'], (val) => setState(() => _sptOrnekleyici = val!))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDropdown('YAS', _yasMi, ['Evet', 'Hayır'], (val) => setState(() => _yasMi = val!))),
                    const SizedBox(width: 12),
                    if (_yasMi == 'Evet')
                      Expanded(child: _buildTextField('YAS Giriniz (m)', _yassCtrl, isNumber: true))
                    else
                      const Expanded(child: SizedBox()), // Hizalama için boşluk
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          // ── ALT: Sonuç Tablosu ──
          Expanded(
            child: Stack(
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Container(
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Color(0xFF37474F),
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Center(child: Text('DENEY NO', style: _headerStyle))),
                            Expanded(child: Center(child: Text('VURUŞ SAYISI', style: _headerStyle))),
                            Expanded(child: Center(child: Text('DENEY DERİNLİĞİ (cm)', style: _headerStyle))),
                          ],
                        ),
                      ),
                      // Tablo İçeriği
                      Expanded(
                        child: _records.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.playlist_add, size: 64, color: Colors.grey.shade400),
                                    const SizedBox(height: 12),
                                    Text('Henüz deney kaydı yok.', style: TextStyle(color: Colors.grey.shade500, fontSize: 16), textAlign: TextAlign.center),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                itemCount: _records.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                            final r = _records[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Expanded(child: Center(child: Text('Deney ${r.deneyNo}', style: _cellStyle))),
                                  Expanded(child: Center(child: Text('${r.vurusSayisi}', style: _cellStyle))),
                                  Expanded(child: Center(child: Text(r.deneyDerinligiCm.toStringAsFixed(0), style: _cellStyle))),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (isTestActive)
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: ElevatedButton.icon(
                        onPressed: _showForceEndDialog,
                        icon: const Icon(Icons.stop, color: Colors.white, size: 28),
                        label: const Text('Deneyi Sonlandır', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
              ],
            ),
          )
        ], // ends Column children
      ), // ends Column
    ), // ends Padding
  ), // ends Opacity
), // ends AbsorbPointer
        if (isLocked)
          Positioned.fill(
            child: Align(
              alignment: const Alignment(0.0, -0.8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Lütfen testlere başlamak için önce "Rapor Gönder" sekmesinden formu doldurup gönderin.',
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ], // ends Stack children
    ); // ends Stack
  }

  Widget _buildInfoCard(String title, Widget content, {Color? titleColor}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: Center(child: content)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 16, color: titleColor ?? Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    if (!_isRunning) {
      return InkWell(
        onTap: _startTest,
        child: Card(
          color: Colors.green,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
                SizedBox(height: 8),
                Text('BAŞLAT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              ],
            ),
          ),
        ),
      );
    } else {
      return InkWell(
        onTap: _stopTest,
        child: Card(
          color: Colors.red,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.stop_circle, color: Colors.white, size: 40),
                SizedBox(height: 8),
                Text('DURDUR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        fillColor: Colors.transparent,
        filled: true,
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        fillColor: Colors.transparent,
        filled: true,
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }
}

const TextStyle _headerStyle = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.bold,
  fontSize: 18,
);

const TextStyle _cellStyle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w500,
);
