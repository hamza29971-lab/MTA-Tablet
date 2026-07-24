import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vtm_tablet/ui/tabs/spt_tab.dart';
import 'package:vtm_tablet/ui/tabs/home_tab.dart';
import 'package:vtm_tablet/utils/app_dialogs.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';

class BstRecord {
  final int no;
  final String sure;
  final double suBasinciOrtalama;
  final double toplamLitre;
  final double basincAdimi;
  final double egimMiktari;
  final bool isEarlyFinished;

  BstRecord({
    required this.no,
    required this.sure,
    required this.suBasinciOrtalama,
    required this.toplamLitre,
    required this.basincAdimi,
    required this.egimMiktari,
    this.isEarlyFinished = false,
  });
}

class ControlTab extends StatefulWidget {
  const ControlTab({super.key});

  @override
  State<ControlTab> createState() => _ControlTabState();
}

class _ControlTabState extends State<ControlTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ── BST Sayaç ──────────────────────────────────────────
  bool _isRunning = false;
  bool _isTestActive = false; // Tüm testin kilitli ve aktif olduğu genel durum
  Timer? _timer;
  int _secondsElapsed = 0;

  double _sumWaterPressure = 0.0;
  int _pressureCount = 0;
  double _currentAvgPressure = 0.0;
  double _totalLiters = 0.0;
  double _initialLitersForStep = 0.0;
  List<double> _currentSequence = [];
  int _sequenceIndex = 0;
  int _subStepIndex = 0;

  final List<BstRecord> _records = [];

  // ── Form State ─────────────────────────────────────────
  final TextEditingController _deneyZonu1Ctrl = TextEditingController();
  final TextEditingController _deneyZonu2Ctrl = TextEditingController();
  String _manometreYuksekligi = '1,25';
  String _yasVarMi = 'Evet';
  final TextEditingController _yassCtrl = TextEditingController();
  final TextEditingController _egimCtrl = TextEditingController(text: '0,0');
  String _ozelDurum = '-';
  String _basincTipi = 'TipA';
  
  bool _isTargetSelected = false;
  double _selectedTarget = 0.0;

  // ── Otomatik Adım Kontrolü ───────────────────────────────
  static const Map<String, List<double>> _tipSteps = {
    'TipA': [2, 4, 6, 8, 10],
    'TipB': [3, 6, 10],
    'TipC': [1, 2, 3],
    'TipD': [], 
  };

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _publishRecord(BstRecord r) {
    final dp = context.read<DataProvider>();
    
    final Map<String, dynamic> embeddedJson = {
      "TestTipi": "Basınçlı Su Testi",
      "MesajTipi": "Kayit",
      "BoxID": dp.deviceData.boxId,
      "No": r.no,
      "Sure": r.sure,
      "BasincAdimi": r.basincAdimi,
      "SuBasinciOrtalama": double.parse(r.suBasinciOrtalama.toStringAsFixed(2)),
      "ToplamLitre": double.parse(r.toplamLitre.toStringAsFixed(1)),
      "DeneyZonu_m": "${_deneyZonu1Ctrl.text}-${_deneyZonu2Ctrl.text}",
      "ManometreYuksekligi_m": double.tryParse(_manometreYuksekligi.replaceAll(',', '.')) ?? 0.0,
      "YAS_VarMi": _yasVarMi,
      "YASS_m": _yasVarMi == 'Evet' ? (double.tryParse(_yassCtrl.text.replaceAll(',', '.')) ?? 0.0) : 0.0,
      "EgimMiktari": double.parse(r.egimMiktari.toStringAsFixed(1)),
      "OzelDurum": _ozelDurum,
      "BasincTipi": _basincTipi,
      "ErkenBitirildi": r.isEarlyFinished,
    };

    final Map<String, dynamic> payloadMap = {
      'operator_name': dp.operatorName ?? 'Otomatik Sistem',
      'kuyu_name': '${dp.wellNo ?? "KUYU"} - BASINÇLI SU TESTİ ADIM ${r.no}',
      'operator_number': dp.registrationNo ?? '000',
      'team_name': 'Sondaj Ekibi',
      'fault_text': jsonEncode(embeddedJson),
      'fault_meter': double.tryParse(_deneyZonu1Ctrl.text) ?? 0.0
    };

    dp.sendUdpReport(payloadMap);
  }

  void _publishSummaryReportToUdp() {
    final dp = context.read<DataProvider>();
    
    double totalWater = 0;
    List<Map<String, dynamic>> adimlar = [];
    for (var r in _records) {
      adimlar.add({
        "No": r.no,
        "Sure": r.sure,
        "BasincAdimi": r.basincAdimi,
        "SuBasinciOrtalama": double.parse(r.suBasinciOrtalama.toStringAsFixed(2)),
        "ToplamLitre": double.parse(r.toplamLitre.toStringAsFixed(1)),
        "ErkenBitirildi": r.isEarlyFinished
      });
      totalWater += r.toplamLitre;
    }

    final Map<String, dynamic> embeddedJson = {
      "TestTipi": "Basınçlı Su Testi",
      "MesajTipi": "Ozet",
      "BoxID": dp.deviceData.boxId,
      "DeneyZonu_m": "${_deneyZonu1Ctrl.text}-${_deneyZonu2Ctrl.text}",
      "BasincTipi": _basincTipi,
      "HedefAdim": _selectedTarget.toInt(),
      "OzelDurum": _ozelDurum,
      "YAS_VarMi": _yasVarMi,
      "YASS_m": _yasVarMi == 'Evet' ? (double.tryParse(_yassCtrl.text.replaceAll(',', '.')) ?? 0.0) : 0.0,
      "ToplamHarcananSu_L": double.parse(totalWater.toStringAsFixed(1)),
      "Adimlar": adimlar
    };

    final Map<String, dynamic> summaryMap = {
      'operator_name': dp.operatorName ?? 'Otomatik Sistem',
      'kuyu_name': '${dp.wellNo ?? "KUYU"} - BASINÇLI SU TESTİ ÖZET',
      'operator_number': dp.registrationNo ?? '000',
      'team_name': 'Sondaj Ekibi',
      'fault_text': jsonEncode(embeddedJson),
      'fault_meter': double.tryParse(_deneyZonu1Ctrl.text) ?? 0.0
    };
    
    dp.sendUdpReport(summaryMap);
  }

  List<double> _generateSequence(String tip, double target) {
    final steps = _tipSteps[tip] ?? [];
    if (steps.isEmpty) return [target];
    
    List<double> seq = [];
    for (double s in steps) {
      seq.add(s);
      if (s >= target) break;
    }
    for (int i = seq.length - 2; i >= 0; i--) {
      seq.add(seq[i]);
    }
    return seq;
  }

  void _showTestDialog(String title, String message, Color? color, {VoidCallback? onConfirm}) {
    AppDialogs.showStandardDialog(
      context,
      title: title,
      message: message,
      color: color ?? Colors.black87,
      icon: color == Colors.red ? Icons.error : (color == Colors.orange ? Icons.warning : Icons.info),
      onConfirm: onConfirm,
    );
  }

  void _resetEntireTest() {
    _timer?.cancel();
    // TEST KİLİDİNİ KALDIR
    if (mounted) {
      context.read<DataProvider>().stopTest();
    }
    setState(() {
      _records.clear();
      _isTestActive = false;
      _isRunning = false;
      _isTargetSelected = false;
      _selectedTarget = 0.0;
      _currentSequence = [];
      _sequenceIndex = 0;
      _subStepIndex = 0;
      _secondsElapsed = 0;
      _sumWaterPressure = 0.0;
      _pressureCount = 0;
      _currentAvgPressure = 0.0;
      _totalLiters = 0.0;
      _initialLitersForStep = 0.0; // Yeni test için referans sıfırlanıyor
      _ozelDurum = '-'; // Eski testten kalan hatayı temizle
    });
  }

  void _recordCurrentStep({required bool isEarly, bool shouldPause = false}) {
    if (!_isTestActive || _currentSequence.isEmpty) return;

    final double currentStepTarget = _currentSequence[_sequenceIndex];
    final dataProvider = context.read<DataProvider>();
    double currentEgim = dataProvider.deviceData.analogData.length > 15
        ? dataProvider.deviceData.analogData[15].toDouble()
        : 0.0;

    double avgPressure = _pressureCount > 0 ? _currentAvgPressure : 0.0;
    double roundedAvg = double.parse(avgPressure.toStringAsFixed(1));
    
    // Tolerans Kontrolü
    bool isPressureValid = (roundedAvg >= currentStepTarget - 0.5 && roundedAvg <= currentStepTarget + 0.5);

    if (!isPressureValid) {
      // Sadece uyarı gösteriyoruz, özel durumu otomatik değiştirmiyoruz. 
      // Özel durum sadece 'Deneyi Sonlandır' menüsünden seçilince atanır.
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _showTestDialog(
            '⚠️ Hedefe Ulaşılamadı', 
            'Hedeflenen $currentStepTarget bar basınca ulaşılamadı (Ort: ${avgPressure.toStringAsFixed(2)} bar).', 
            Colors.orange
          );
        }
      });
    }

    final record = BstRecord(
      no: _records.length + 1,
      sure: _formatTime(_secondsElapsed),
      suBasinciOrtalama: avgPressure,
      toplamLitre: _totalLiters,
      basincAdimi: currentStepTarget,
      egimMiktari: currentEgim,
      isEarlyFinished: isEarly || !isPressureValid,
    );

    setState(() {
      _records.add(record);
      _publishRecord(record);

      _subStepIndex++;
      if (_subStepIndex >= 2) {
        _subStepIndex = 0;
        _sequenceIndex++;
      }

      if (_sequenceIndex >= _currentSequence.length) {
        _endTestFully();
      } else {
        _secondsElapsed = 0;
        _sumWaterPressure = 0.0;
        _pressureCount = 0;
        _currentAvgPressure = 0.0;
        _totalLiters = 0.0;
        final dp = context.read<DataProvider>();
        _initialLitersForStep = dp.deviceData.analogData.length > 11 ? dp.deviceData.analogData[11].toDouble() : 0.0;
        if (shouldPause) {
          _isRunning = false;
          _timer?.cancel();
        }
      }
    });
  }

  void _showEndTestDialog() {
    String tempOzelDurum = _ozelDurum == "-" ? 'Deney Hatası' : _ozelDurum;
    AppDialogs.showCustomDialog(
      context,
      title: 'Deneyi Sonlandır',
      color: Colors.red,
      icon: Icons.warning,
      content: StatefulBuilder(
        builder: (context, setStateSB) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Deneyi bitmeden sonlandırmak üzeresiniz.\nLütfen özel durum (sebep) seçiniz:', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: tempOzelDurum,
                    isExpanded: true,
                    style: const TextStyle(fontSize: 28, color: Colors.black87),
                    onChanged: (val) {
                      setStateSB(() => tempOzelDurum = val!);
                    },
                    items: [
                      'Deney Hatası',
                      'Paker Tutmadı',
                      'Basınç Yükselmedi',
                      'Kuyu Ağzından Su Geldi'
                    ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  ),
                ),
              ),
            ],
          );
        }
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal', style: TextStyle(fontSize: 24, color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          onPressed: () {
            Navigator.of(context).pop();
            setState(() => _ozelDurum = tempOzelDurum);
            _recordCurrentStep(isEarly: true, shouldPause: true);
            _endTestFully();
          },
          child: const Text('Sonlandır ve Raporla', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
        ),
      ],
    );
  }

  void _endTestFully() {
    _timer?.cancel();
    // TEST KİLİDİNİ KALDIR
    if (mounted) {
      context.read<DataProvider>().stopTest();
    }
    setState(() {
      _isRunning = false;
      _isTestActive = false;
    });
    
    _publishSummaryReportToUdp();

    bool hasFailure = _records.any((r) => r.isEarlyFinished);
    
    if (_sequenceIndex >= _currentSequence.length) {
      if (hasFailure) {
        _showTestDialog(
          'Deney Tamamlandı', 
          'Tüm test dizilimi bitti ancak bazı basınç hedeflerine ulaşılamadı.\nBasınçlı Su Testi raporu gönderildi.', 
          Colors.orange,
          onConfirm: _resetEntireTest,
        );
      } else {
        _showTestDialog(
          '✅ Deney Tamamlandı', 
          'Tüm test dizilimi başarıyla sonlandırıldı.\nBasınçlı Su Testi raporu gönderildi.', 
          Colors.green,
          onConfirm: _resetEntireTest,
        );
      }
    } else {
      _showTestDialog(
        'Deney Sonlandırıldı', 
        'Test yarıda kesildi.\nYapılan işlemler kaydedildi ve Basınçlı Su Testi raporu gönderildi.', 
        Colors.red,
        onConfirm: _resetEntireTest,
      );
    }
  }

  void _startPeriodicTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsElapsed++;
        final dataProvider = context.read<DataProvider>();
        double currentPressure = 0.0;
        if (dataProvider.deviceData.analogData.length > 9) {
          currentPressure =
              dataProvider.deviceData.analogData[9].toDouble();
        }
        final double currentFlowRate = currentPressure * 5.0; // Sadece ekrandaki anlık debi göstergesi için tutulabilir
        _sumWaterPressure += currentPressure;
        _pressureCount++;
        _currentAvgPressure = _sumWaterPressure / _pressureCount;
        
        // GERÇEK LİTRE SENSÖRÜNDEN (Analog 11) OKUMA (Sayaç)
        double liveTotalLiters = dataProvider.deviceData.analogData.length > 11 
            ? dataProvider.deviceData.analogData[11].toDouble() 
            : _initialLitersForStep;
        
        _totalLiters = liveTotalLiters - _initialLitersForStep;

        // 5 dakika (300 saniye) dolunca (Kullanıcı talebi)
        if (_secondsElapsed >= 300) {
          _recordCurrentStep(isEarly: false, shouldPause: true);
        }
      });
    });
  }

  void _toggleTimer() {
    if (_isTestActive) {
      if (_isRunning) {
        // DURDUR (Erken atla ve beklet)
        _recordCurrentStep(isEarly: true, shouldPause: true);
      } else {
        // PAUSE'DAN DEVAM ET VEYA YENİ BAŞLA
        if (_secondsElapsed == 0) {
          final dp = context.read<DataProvider>();
          _initialLitersForStep = dp.deviceData.analogData.length > 11 ? dp.deviceData.analogData[11].toDouble() : 0.0;
        }
        setState(() {
          _isRunning = true;
        });
        _startPeriodicTimer();
      }
    } else {
      // BAŞLAT
      if (context.read<DataProvider>().isAnyOtherTestRunning('Basınçlı Su Testi')) {
        _showTestDialog('⚠️ Test Başlatılamaz', 'Şu anda başka bir sekmede aktif bir test devam ediyor. Lütfen önce onu sonlandırın.', Colors.red);
        return;
      }

      if (!_isTargetSelected) {
        _showTestDialog('⚠️ Hedef Seçilmedi', 'Testi başlatmadan önce Adım Sırası kutucuklarına tıklayarak bir Hedef belirleyiniz.', Colors.orange);
        return;
      }

      final List<String> eksik = [];
      if (_deneyZonu1Ctrl.text.trim().isEmpty || _deneyZonu2Ctrl.text.trim().isEmpty) {
        eksik.add('Deney Zonu (m)');
      }
      if (_yasVarMi == 'Evet' && _yassCtrl.text.trim().isEmpty) {
        eksik.add('YAS Giriniz');
      }
      if (eksik.isNotEmpty) {
        AppDialogs.showStandardDialog(
          context,
          title: 'Eksik Bilgi',
          message: 'Lütfen şu alanları doldurun:\n\n• ${eksik.join("\n• ")}',
          color: Colors.orange,
          icon: Icons.info,
        );
        return;
      }
      
      setState(() {
        _records.clear();
        _currentSequence = _generateSequence(_basincTipi, _selectedTarget);
        _sequenceIndex = 0;
        _subStepIndex = 0;
        _secondsElapsed = 0;
        _sumWaterPressure = 0.0;
        _pressureCount = 0;
        _currentAvgPressure = 0.0;
        _totalLiters = 0.0;
        _isTestActive = true;
        _isRunning = true;
        _ozelDurum = '-'; // Teste başlarken olası hatalı durumu temizle
      });

      // TEST BAŞLAMADAN ÖNCE sensorun anlık litre değerini referans al
      // Bu sayede test ekranı her zaman 0'dan başlar (10016 gibi büyük sayı çıkmaz)
      final dp = context.read<DataProvider>();
      _initialLitersForStep = dp.deviceData.analogData.length > 11
          ? dp.deviceData.analogData[11].toDouble()
          : 0.0;

      // TEST KİLİDİNİ BAŞLAT
      context.read<DataProvider>().startTest('Basınçlı Su Testi');

      _startPeriodicTimer();
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _deneyZonu1Ctrl.dispose();
    _deneyZonu2Ctrl.dispose();
    _yassCtrl.dispose();
    _egimCtrl.dispose();
    _timer?.cancel();
    
    // Uygulamadan/sayfadan çıkılırken testi serbest bırak (eğer bu testse)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final dp = context.read<DataProvider>();
        if (dp.activeTestName == 'Basınçlı Su Testi') {
          dp.stopTest();
        }
      }
    });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final dataProvider = context.watch<DataProvider>();
    final livePressure = dataProvider.deviceData.analogData.length > 9
        ? dataProvider.deviceData.analogData[9].toDouble()
        : 0.0;
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
          // ── ÜST: 5 Bilgi Kartı ──
          SizedBox(
            height: 150,
            child: Row(
              children: [
                Expanded(
                  child: _buildTopCard(
                    label: 'Su Basıncı',
                    value: livePressure.toStringAsFixed(1),
                    unit: 'BAR',
                    subLabel: 'Canlı',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTopCard(
                    label: 'Litre',
                    value: _totalLiters.toStringAsFixed(1),
                    unit: 'L',
                    subLabel: '',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _toggleTimer,
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: _isRunning
                              ? Colors.red.shade600
                              : Colors.green.shade600,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isRunning
                                    ? Icons.skip_next_rounded
                                    : Icons.play_circle_fill_outlined,
                                size: 48,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _isRunning ? 'DURDUR' : 'BAŞLAT',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTopCard(
                    label: 'Zaman',
                    value: _formatTime(_secondsElapsed),
                    unit: '',
                    subLabel: _isRunning ? 'Çalışıyor' : 'Durduruldu',
                    isTimer: true,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── ORTA: Form Alanı ────────────────────────────
          _buildFormSection(),
          const SizedBox(height: 12),

          // ── ALT: Kayıt Tablosu (sağ altta Özel Durumlar overlay) ──
          Expanded(
            child: Stack(
              children: [
                // Ana Tablo Kartı
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      // Tablo Başlığı
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF37474F),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 80,
                              child: Text('Basınç\nAdımı',
                                  style: _headerStyle,
                                  textAlign: TextAlign.center),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                                child: Text('Süre (dk)',
                                    style: _headerStyle,
                                    textAlign: TextAlign.center)),
                            const Expanded(
                                child: Text('Su Basıncı Ort. (bar)',
                                    style: _headerStyle,
                                    textAlign: TextAlign.center)),
                            const Expanded(
                                child: Text('Toplam Litre (L)',
                                    style: _headerStyle,
                                    textAlign: TextAlign.center)),
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
                                    Icon(Icons.playlist_add,
                                        size: 64, color: Colors.grey.shade400),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Henüz deney kaydı yok.',
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.only(bottom: 60),
                                itemCount: _records.length,
                                separatorBuilder: (_, __) => Divider(
                                    height: 1, color: Colors.grey.shade200),
                                itemBuilder: (context, index) {
                                  final r = _records[index];
                                  final isEven = index % 2 == 0;
                                  Color rowColor = isEven
                                      ? Colors.green.shade50
                                      : Colors.green.shade100;
                                  if (r.isEarlyFinished) {
                                    rowColor = Colors.red.shade100;
                                  }

                                  return Container(
                                    color: rowColor,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 16),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 80,
                                          child: Text(
                                              r.basincAdimi > 0
                                                  ? '${r.basincAdimi.toInt()}'
                                                  : '-',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                              textAlign: TextAlign.center),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(r.sure,
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                              textAlign: TextAlign.center),
                                        ),
                                        Expanded(
                                          child: Text(
                                              '${r.suBasinciOrtalama.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                              textAlign: TextAlign.center),
                                        ),
                                        Expanded(
                                          child: Text(
                                              '${r.toplamLitre.toStringAsFixed(1)}',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                              textAlign: TextAlign.center),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                // ── Sağ Alt Köşe: Özel Durumlar ve Deneyi Sonlandır ──
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isTestActive)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ElevatedButton.icon(
                            onPressed: _showEndTestDialog,
                            icon: const Icon(Icons.stop, color: Colors.white, size: 28),
                            label: const Text('Deneyi Sonlandır', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: const StadiumBorder(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildTopCard({
    required String label,
    required String value,
    required String unit,
    required String subLabel,
    bool isTimer = false,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              unit.isNotEmpty ? '$value $unit' : value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isTimer ? 36 : 40,
                    color: Colors.black87,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subLabel,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return IgnorePointer(
      ignoring: _isTestActive,
      child: Opacity(
        opacity: _isTestActive ? 0.7 : 1.0,
        child: Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildDoubleTextField('Deney Zonu\n(m)', _deneyZonu1Ctrl, _deneyZonu2Ctrl)),
                Expanded(child: _buildDropdown('Manometre\nYüksekliği (m)', _manometreYuksekligi, ['1,15', '1,20', '1,25', '1,30', '1,35', '1,40', '1,45', '1,50'], (val) => setState(() => _manometreYuksekligi = val!), centered: true)),
                Expanded(child: _buildDropdown('YAS', _yasVarMi, ['Evet', 'Hayır'], (val) => setState(() => _yasVarMi = val!), centered: true)),
                if (_yasVarMi == 'Evet')
                  Expanded(child: _buildSingleTextField('YAS\nGiriniz (m)', _yassCtrl)),
                Expanded(child: _buildDropdown('Basınç Tipi', _basincTipi, ['TipA', 'TipB', 'TipC', 'TipD'], (val) {
                  setState(() {
                    _basincTipi = val!;
                    _isTargetSelected = false;
                    _selectedTarget = 0.0;
                  });
                }, centered: true)),
                // ── Otomatik İlerleyen Adım Göstergesi ──
                const SizedBox(width: 8),
                _buildStepIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoubleTextField(String label, TextEditingController ctrl1, TextEditingController ctrl2) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 36, child: Align(alignment: Alignment.bottomCenter, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87), textAlign: TextAlign.center, maxLines: 2))),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: TextField(controller: ctrl1, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 12)))),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('-')),
              Expanded(child: TextField(controller: ctrl2, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 12)))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSingleTextField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 36, child: Align(alignment: Alignment.bottomCenter, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87), textAlign: TextAlign.center, maxLines: 2))),
          const SizedBox(height: 4),
          TextField(controller: ctrl, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12))),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, void Function(String?) onChanged, {bool centered = false}) {
    if (!items.contains(value) && items.isNotEmpty) {
      value = items.first;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          SizedBox(height: 36, child: Align(alignment: centered ? Alignment.bottomCenter : Alignment.bottomLeft, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87), textAlign: centered ? TextAlign.center : TextAlign.start, maxLines: 2))),
          const SizedBox(height: 4),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                onChanged: onChanged,
                focusColor: Colors.transparent,
                dropdownColor: Colors.white,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, overflow: TextOverflow.ellipsis))).toList(),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    List<double> steps;
    if (_isTargetSelected || _isTestActive) {
      steps = _generateSequence(_basincTipi, _selectedTarget);
    } else {
      steps = _tipSteps[_basincTipi] ?? [];
    }

    if (steps.isEmpty) return const SizedBox.shrink();

    Color statusColor = _isTestActive ? Colors.blue : Colors.grey;
    String statusLabel = _isTestActive ? '🔵 Devam' : '⏳ Bekliyor';
    if (!_isTestActive && _records.isNotEmpty) {
      statusColor = Colors.green;
      statusLabel = '✅ Bitti';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 36,
            child: Row(
              children: [
                const Text('Basınç Adımı',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    border: Border.all(color: statusColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor)),
                ),
                if (!_isTargetSelected && !_isTestActive && _records.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text('Hedef İçin Kutucuğa Tıklayın', style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: steps.asMap().entries.map((entry) {
                int index = entry.key;
                double step = entry.value;
  
                bool isVisited = index < _sequenceIndex || (!_isTestActive && _records.isNotEmpty && _records.length >= _currentSequence.length * 2);
                bool isCurrent = _isTestActive && index == _sequenceIndex;
                
                bool isFailed = false;
                if (isVisited || isCurrent) {
                  int recordIndex1 = index * 2;
                  int recordIndex2 = index * 2 + 1;
                  if (recordIndex1 < _records.length && _records[recordIndex1].isEarlyFinished) isFailed = true;
                  if (recordIndex2 < _records.length && _records[recordIndex2].isEarlyFinished) isFailed = true;
                }
  
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: GestureDetector(
                    onTap: () {
                      if (!_isTestActive && !_isTargetSelected && _records.isEmpty) {
                        setState(() {
                          _selectedTarget = step;
                          _isTargetSelected = true;
                        });
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? Colors.blue
                            : isVisited
                                ? (isFailed ? Colors.red.shade600 : Colors.green.shade600)
                                : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                        border: (!_isTestActive && !_isTargetSelected && _records.isEmpty)
                            ? Border.all(color: Colors.blueAccent.shade100, width: 2)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${step.toInt()}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: (isCurrent || isVisited) ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

const TextStyle _headerStyle = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.bold,
  fontSize: 16,
);
