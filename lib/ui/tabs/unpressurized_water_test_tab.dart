import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../utils/app_dialogs.dart';

class UnpressurizedWaterRecord {
  final int no;
  final String sure;
  final double baslangicLitre;
  final double bitisLitre;
  final double harcananLitre;
  final bool isEarlyFinished;

  UnpressurizedWaterRecord({
    required this.no,
    required this.sure,
    required this.baslangicLitre,
    required this.bitisLitre,
    required this.harcananLitre,
    this.isEarlyFinished = false,
  });
}

class UnpressurizedWaterTestTab extends StatefulWidget {
  const UnpressurizedWaterTestTab({super.key});

  @override
  State<UnpressurizedWaterTestTab> createState() => _UnpressurizedWaterTestTabState();
}

class _UnpressurizedWaterTestTabState extends State<UnpressurizedWaterTestTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isRunning = false;
  Timer? _timer;
  int _secondsElapsed = 0;
  final int _maxSeconds = 300; // 5 dakika

  double _initialLiters = 0.0;
  double _currentLiters = 0.0;
  int _currentDeneyNo = 1;

  final List<UnpressurizedWaterRecord> _records = [];

  // Form State
  final TextEditingController _deneyZonu1Ctrl = TextEditingController();
  final TextEditingController _deneyZonu2Ctrl = TextEditingController();
  String _yasVarMi = 'Evet';
  final TextEditingController _yassCtrl = TextEditingController();
  
  final TextEditingController _kuyuYaricapiCtrl = TextEditingController();
  final TextEditingController _delikliBoruYaricapiCtrl = TextEditingController();
  final TextEditingController _delikCapiCtrl = TextEditingController();
  final TextEditingController _delikAdediCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _deneyZonu1Ctrl.dispose();
    _deneyZonu2Ctrl.dispose();
    _yassCtrl.dispose();
    _kuyuYaricapiCtrl.dispose();
    _delikliBoruYaricapiCtrl.dispose();
    _delikCapiCtrl.dispose();
    _delikAdediCtrl.dispose();
    _timer?.cancel();

    // Uygulamadan/sayfadan çıkılırken testi serbest bırak (eğer bu testse)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final dp = context.read<DataProvider>();
        if (dp.activeTestName == 'Basınçsız Su Testi' &&
            !dp.isAppInBackground) {
          dp.stopTest();
        }
      }
    });

    super.dispose();
  }

  void _publishRecord(UnpressurizedWaterRecord r) {
    final dp = context.read<DataProvider>();

    final Map<String, dynamic> embeddedJson = {
      "TestTipi": "Basınçsız Su Testi",
      "MesajTipi": "Kayit",
      "BoxID": dp.deviceData.boxId,
      "No": r.no,
      "Sure": r.sure,
      "BaslangicLitre": double.parse(r.baslangicLitre.toStringAsFixed(1)),
      "BitisLitre": double.parse(r.bitisLitre.toStringAsFixed(1)),
      "HarcananLitre": double.parse(r.harcananLitre.toStringAsFixed(1)),
      "DeneyZonu_m": "${_deneyZonu1Ctrl.text}-${_deneyZonu2Ctrl.text}",
      "YAS_VarMi": _yasVarMi,
      "YASS_m": _yasVarMi == 'Evet' ? (double.tryParse(_yassCtrl.text.replaceAll(',', '.')) ?? 0.0) : 0.0,
      "KuyuYaricapi_m": double.tryParse(_kuyuYaricapiCtrl.text.replaceAll(',', '.')) ?? 0.0,
      "DelikliBoruYaricapi_m": double.tryParse(_delikliBoruYaricapiCtrl.text.replaceAll(',', '.')) ?? 0.0,
      "DelikCapi_m": double.tryParse(_delikCapiCtrl.text.replaceAll(',', '.')) ?? 0.0,
      "DelikAdedi": int.tryParse(_delikAdediCtrl.text) ?? 0,
    };

    final Map<String, dynamic> payloadMap = {
      'operator_name': dp.operatorName ?? 'Otomatik Sistem',
      'kuyu_name': '${dp.wellNo ?? "KUYU"} - BASINÇSIZ SU TESTİ ADIM ${r.no}',
      'operator_number': dp.registrationNo ?? '000',
      'team_name': 'Sondaj Ekibi',
      'fault_text': jsonEncode(embeddedJson),
      'fault_meter': double.tryParse(_deneyZonu1Ctrl.text) ?? 0.0
    };

    dp.sendUdpReport(payloadMap);
  }

  void _publishSummaryReportToUdp() {
    final dp = context.read<DataProvider>();
    
    double totalWater = 0.0;
    List<Map<String, dynamic>> adimlar = [];
    for (var r in _records) {
      adimlar.add({
        "No": r.no,
        "Sure": r.sure,
        "HarcananLitre": double.parse(r.harcananLitre.toStringAsFixed(1)),
      });
      totalWater += r.harcananLitre;
    }

    final Map<String, dynamic> embeddedJson = {
      "TestTipi": "Basınçsız Su Testi",
      "MesajTipi": "Ozet",
      "BoxID": dp.deviceData.boxId,
      "DeneyZonu_m": "${_deneyZonu1Ctrl.text}-${_deneyZonu2Ctrl.text}",
      "YAS_VarMi": _yasVarMi,
      "YASS_m": _yasVarMi == 'Evet' ? (double.tryParse(_yassCtrl.text.replaceAll(',', '.')) ?? 0.0) : 0.0,
      "ToplamHarcananSu_L": double.parse(totalWater.toStringAsFixed(1)),
      "Adimlar": adimlar
    };

    final Map<String, dynamic> summaryMap = {
      'operator_name': dp.operatorName ?? 'Otomatik Sistem',
      'kuyu_name': '${dp.wellNo ?? "KUYU"} - BASINÇSIZ SU TESTİ ÖZET',
      'operator_number': dp.registrationNo ?? '000',
      'team_name': 'Sondaj Ekibi',
      'fault_text': jsonEncode(embeddedJson),
      'fault_meter': double.tryParse(_deneyZonu1Ctrl.text) ?? 0.0
    };
    
    dp.sendUdpReport(summaryMap);
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _showForceEndDialog() {
    AppDialogs.showConfirmDialog(
      context,
      title: 'Deneyi Sonlandır',
      message: 'Deneyi erken sonlandırmak üzeresiniz. Onaylıyor musunuz?',
      color: Colors.red,
      icon: Icons.warning,
      onConfirm: () => _showEndTestDialog(isForced: true),
      confirmText: 'Sonlandır',
    );
  }

  void _showEndTestDialog({bool isForced = false}) {
    _publishSummaryReportToUdp();
    AppDialogs.showStandardDialog(
      context,
      title: isForced ? 'Deney Sonlandırıldı' : 'Deney Tamamlandı',
      message: isForced ? 'Deney erken sonlandırıldı.\nBasınçsız Su Testi raporu gönderildi.' : 'Basınçsız su testi başarıyla tamamlandı.\nBasınçsız Su Testi raporu gönderildi.',
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
      _currentDeneyNo = 1;
      _secondsElapsed = 0;
      _initialLiters = 0.0;
      _currentLiters = 0.0;
    });
  }

  void _completeExperiment() {
    _timer?.cancel();
    
    final record = UnpressurizedWaterRecord(
      no: _currentDeneyNo,
      sure: _formatTime(_secondsElapsed),
      baslangicLitre: _initialLiters,
      bitisLitre: _currentLiters,
      harcananLitre: _currentLiters - _initialLiters,
      isEarlyFinished: _secondsElapsed < _maxSeconds,
    );

    setState(() {
      _records.add(record);
      _publishRecord(record);
      _isRunning = false;
      
      if (_currentDeneyNo < 4) {
        _currentDeneyNo++;
      } else {
        _showEndTestDialog();
      }
    });
  }

  void _toggleTimer() {
    if (_isRunning) {
      // Erken iptal etme veya durdurma
      _completeExperiment();
      
      // EğER test tamamen bittiyse (_currentDeneyNo == 4 vs.) _completeExperiment içinde
      // _showEndTestDialog çağrılıyor ve o da _resetEntireTest() çağırıyor (kilidi kaldırıyor).
      // Eğer kullanıcı testi erken DURDURDUYSA ve deney 4'e gelmediyse kilit hala aktif kalmalı ki devam edebilsin.
      // (Eğer "Durdur" testi tamamen siliyorsa _resetEntireTest çağrılmalı, ama burada durdurma = "sonraki deneye geç" gibi çalışıyor).
      
    } else {
      // BAŞLAT
      if (context.read<DataProvider>().isAnyOtherTestRunning('Basınçsız Su Testi')) {
        AppDialogs.showStandardDialog(
          context,
          title: 'Test Başlatılamaz',
          message: 'Şu anda başka bir sekmede aktif bir test devam ediyor. Lütfen önce onu sonlandırın.',
          color: Colors.red,
          icon: Icons.error,
        );
        return;
      }
      // Zorunlu alan kontrolü
      final List<String> eksik = [];
      if (_deneyZonu1Ctrl.text.trim().isEmpty || _deneyZonu2Ctrl.text.trim().isEmpty) eksik.add('Deney Zonu Boyu (m)');
      if (_yasVarMi == 'Evet' && _yassCtrl.text.trim().isEmpty) eksik.add('YAS Giriniz');
      if (_kuyuYaricapiCtrl.text.trim().isEmpty) eksik.add('Kuyu Yarıçapı');
      if (_delikliBoruYaricapiCtrl.text.trim().isEmpty) eksik.add('Delikli Boru Yarıçapı');
      if (_delikCapiCtrl.text.trim().isEmpty) eksik.add('Delik Çapı');
      if (_delikAdediCtrl.text.trim().isEmpty) eksik.add('Delik Adedi');

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

      final dataProvider = context.read<DataProvider>();
      double currentLitersVal = dataProvider.deviceData.analogData.length > 11
          ? dataProvider.deviceData.analogData[11].toDouble()
          : 0.0;

      setState(() {
        _secondsElapsed = 0;
        _initialLiters = currentLitersVal;
        _currentLiters = currentLitersVal;
        _isRunning = true;
      });

      // TEST KİLİDİNİ BAŞLAT
      context.read<DataProvider>().startTest('Basınçsız Su Testi');

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          _secondsElapsed++;
          
          final dp = context.read<DataProvider>();
          _currentLiters = dp.deviceData.analogData.length > 11 ? dp.deviceData.analogData[11].toDouble() : _currentLiters;
          
          if (_secondsElapsed >= _maxSeconds) {
            _completeExperiment();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final dataProvider = context.watch<DataProvider>();
    
    // Analog 11'den live total litre okuma
    double liveLiters = dataProvider.deviceData.analogData.length > 11
        ? dataProvider.deviceData.analogData[11].toDouble()
        : 0.0;

    double consumedLive = _isRunning ? (liveLiters - _initialLiters) : 0.0;
    if (consumedLive < 0) consumedLive = 0.0; // Sayacın ters dönme ihtimaline karşı

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
          // ── ÜST KISIM: LİTRE VE SÜRE ──
          SizedBox(
            height: 150,
            child: Row(
              children: [
                Expanded(
                  child: _buildTopCard(
                    label: 'Harcanan Su',
                    value: _isRunning ? consumedLive.toStringAsFixed(1) : '0.0',
                    unit: 'Litre',
                    subLabel: 'Bu deney boyunca',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _toggleTimer,
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: _isRunning ? Colors.red.shade600 : Colors.green.shade600,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isRunning ? Icons.stop_circle_outlined : Icons.play_circle_fill_outlined,
                                size: 48,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _isRunning ? 'DURDUR' : 'BAŞLAT',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
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
                    value: _formatTime(_isRunning ? _secondsElapsed : 0),
                    unit: '',
                    subLabel: _isRunning ? 'Geçen Süre' : 'Hazır',
                    isTimer: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── ORTA KISIM: FORM ALANLARI ──
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildDoubleTextField('Deney Zonu\nBoyu (m)', _deneyZonu1Ctrl, _deneyZonu2Ctrl, enabled: !_isRunning && _records.isEmpty)),
                      Expanded(child: _buildDropdown('YAS', _yasVarMi, ['Evet', 'Hayır'], (!_isRunning && _records.isEmpty) ? (val) => setState(() => _yasVarMi = val!) : null, centered: true)),
                      if (_yasVarMi == 'Evet') Expanded(child: _buildSingleTextField('YAS\nGiriniz (m)', _yassCtrl, enabled: !_isRunning && _records.isEmpty)), 
                      Expanded(child: _buildSingleTextField('Kuyu\nYarıçapı (m)', _kuyuYaricapiCtrl, enabled: !_isRunning && _records.isEmpty)),
                      Expanded(child: _buildSingleTextField('Delikli Boru\nYarıçapı (m)', _delikliBoruYaricapiCtrl, enabled: !_isRunning && _records.isEmpty)),
                      Expanded(child: _buildSingleTextField('Delik\nÇapı (m)', _delikCapiCtrl, enabled: !_isRunning && _records.isEmpty)),
                      Expanded(child: _buildSingleTextField('Delik\nAdedi', _delikAdediCtrl, enabled: !_isRunning && _records.isEmpty)),
                      const SizedBox(width: 8),
                      _buildDeneyNoIndicator(),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── ALT KISIM: TABLO ──
          Expanded(
            child: Stack(
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      // Tablo Başlığı
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF37474F),
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        child: Row(
                          children: [
                            const SizedBox(width: 80, child: Text('Deney No', style: _headerStyle, textAlign: TextAlign.center)),
                            const SizedBox(width: 16),
                            const Expanded(child: Text('Süre (dk)', style: _headerStyle, textAlign: TextAlign.center)),
                            const Expanded(child: Text('Harcanan Litre', style: _headerStyle, textAlign: TextAlign.center)),
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
                                padding: const EdgeInsets.only(bottom: 12),
                                itemCount: _records.length,
                                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                                itemBuilder: (context, index) {
                                  final r = _records[index];
                                  final isEven = index % 2 == 0;
                                  
                                  Color rowColor = isEven ? Colors.green.shade50 : Colors.green.shade100;
                                  if (r.isEarlyFinished) {
                                    rowColor = Colors.red.shade100; // Erken bitirilmişse kırmızıya çevir
                                  }

                                  return Container(
                                    color: rowColor,
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    child: Row(
                                      children: [
                                        SizedBox(width: 80, child: Text('${r.no}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center)),
                                        const SizedBox(width: 16),
                                        Expanded(child: Text(r.sure, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87), textAlign: TextAlign.center)),
                                        Expanded(child: Text('${r.harcananLitre.toStringAsFixed(1)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                if (dataProvider.activeTestName == 'Basınçsız Su Testi')
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

  Widget _buildTopCard({required String label, required String value, required String unit, required String subLabel, bool isTimer = false}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              unit.isNotEmpty ? '$value $unit' : value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: isTimer ? 36 : 40, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87), textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(subLabel, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildDoubleTextField(String label, TextEditingController ctrl1, TextEditingController ctrl2, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 36, child: Align(alignment: Alignment.bottomCenter, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87), textAlign: TextAlign.center, maxLines: 2))),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: TextField(enabled: enabled, controller: ctrl1, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: InputDecoration(filled: !enabled, fillColor: Colors.grey.shade200, border: const OutlineInputBorder(), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12)))),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text('-')),
              Expanded(child: TextField(enabled: enabled, controller: ctrl2, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: InputDecoration(filled: !enabled, fillColor: Colors.grey.shade200, border: const OutlineInputBorder(), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12)))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSingleTextField(String label, TextEditingController ctrl, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 36, child: Align(alignment: Alignment.bottomCenter, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87), textAlign: TextAlign.center, maxLines: 2))),
          const SizedBox(height: 4),
          TextField(enabled: enabled, controller: ctrl, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: InputDecoration(filled: !enabled, fillColor: Colors.grey.shade200, border: const OutlineInputBorder(), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12))),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, void Function(String?)? onChanged, {bool centered = false}) {
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
            decoration: BoxDecoration(color: onChanged == null ? Colors.grey.shade200 : Colors.transparent, border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
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

  Widget _buildDeneyNoIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(
          height: 36,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Text('Deney No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [1, 2, 3, 4].map((no) {
            bool isActive = _currentDeneyNo == no;
            bool isCompleted = _records.any((r) => r.no == no);
            
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Container(
                width: 32,
                height: 42,
                decoration: BoxDecoration(
                  color: isActive ? Colors.blue : (isCompleted ? Colors.green.shade600 : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$no',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: (isActive || isCompleted) ? Colors.white : Colors.black87),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

const TextStyle _headerStyle = TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16);
