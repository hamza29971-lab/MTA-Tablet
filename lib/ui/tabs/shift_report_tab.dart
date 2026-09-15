import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/mqtt_service.dart';
import '../../providers/report_provider.dart';
import '../../providers/data_provider.dart';
import '../../models/report_data.dart';
import '../widgets/locked_tab_wrapper.dart';
import '../widgets/keyboard_scrollable_wrapper.dart';
class ShiftReportTab extends StatefulWidget {
  const ShiftReportTab({super.key});

  @override
  State<ShiftReportTab> createState() => _ShiftReportTabState();
}

class _ShiftReportTabState extends State<ShiftReportTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final TextEditingController _aController = TextEditingController();
  final TextEditingController _sController = TextEditingController();
  final TextEditingController _mController = TextEditingController();
  final TextEditingController _uController = TextEditingController();
  final TextEditingController _pController = TextEditingController();
  final TextEditingController _ilerlemeController = TextEditingController();
  final TextEditingController _karotBoyuController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _muhafazaSayisiController = TextEditingController();
  final TextEditingController _muhafazaMetrajiController = TextEditingController();

  double _t = 0.0;
  double _2 = 0.0;
  double _3 = 0.0;
  double _4 = 0.0;

  @override
  void initState() {
    super.initState();
    _aController.addListener(_calculate);
    _sController.addListener(_calculate);
    _mController.addListener(_calculate);
    _uController.addListener(_calculate);
    _pController.addListener(_calculate);
  }

  @override
  void dispose() {
    _aController.dispose();
    _sController.dispose();
    _mController.dispose();
    _uController.dispose();
    _pController.dispose();
    _ilerlemeController.dispose();
    _karotBoyuController.dispose();
    _descController.dispose();
    _muhafazaSayisiController.dispose();
    _muhafazaMetrajiController.dispose();
    super.dispose();
  }

  void _calculate() {
    double a = double.tryParse(_aController.text.replaceAll(',', '.')) ?? 0.0;
    double s = double.tryParse(_sController.text.replaceAll(',', '.')) ?? 0.0;
    double m = double.tryParse(_mController.text.replaceAll(',', '.')) ?? 0.0;
    double u = double.tryParse(_uController.text.replaceAll(',', '.')) ?? 0.0;
    double p = double.tryParse(_pController.text.replaceAll(',', '.')) ?? 0.0;
    setState(() {
      _t = a * s;
      _2 = _t + m;
      _3 = p + u;
      _4 = _2 - _3;
    });
  }

  void _submitReport() {
    FocusScope.of(context).unfocus();
    if (_aController.text.trim().isEmpty ||
        _sController.text.trim().isEmpty ||
        _mController.text.trim().isEmpty ||
        _uController.text.trim().isEmpty ||
        _pController.text.trim().isEmpty ||
        _ilerlemeController.text.trim().isEmpty ||
        _karotBoyuController.text.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 64),
            SizedBox(width: 12),
            Text('Eksik Bilgi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 34)),
          ]),
          content: const SizedBox(
            width: 800,
            child: Text('Lütfen formdaki tüm alanları eksiksiz doldurun.', style: TextStyle(fontSize: 30)),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF046464),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Tamam', style: TextStyle(fontSize: 28)),
            )
          ],
        ),
      );
      return;
    }

    // final mqttService = context.read<MqttService>();
    final reportProvider = context.read<ReportProvider>();
    final dp = context.read<DataProvider>();
    
    final Map<String, dynamic> payload = {
      'type': 'shift',
      'rod_cnt': double.tryParse(_aController.text.replaceAll(',', '.')) ?? 0.0,
      'rod_len': double.tryParse(_sController.text.replaceAll(',', '.')) ?? 0.0,
      'tot_rod_len': double.parse(_t.toStringAsFixed(2)),
      'tool_len': double.tryParse(_mController.text.replaceAll(',', '.')) ?? 0.0,
      'tot_tool_len': double.parse(_2.toStringAsFixed(2)),
      'mors_wat': double.tryParse(_uController.text.replaceAll(',', '.')) ?? 0.0,
      'mors_und': double.tryParse(_pController.text.replaceAll(',', '.')) ?? 0.0,
      'tot_m': double.parse(_3.toStringAsFixed(2)),
      'well_depth': double.parse(_4.toStringAsFixed(2)),
      'adv_m': double.tryParse(_ilerlemeController.text.replaceAll(',', '.')) ?? 0.0,
      'core_m': _karotBoyuController.text,
      'cas_cnt': _muhafazaSayisiController.text,
      'cas_len': _muhafazaMetrajiController.text,
      'desc': _descController.text,
      'date': DateTime.now().toIso8601String(),
    };
    
    final faultTextJson = jsonEncode(payload);

    final reportData = ReportData(
      operatorName: dp.operatorName ?? '',
      kuyuName: dp.wellNo ?? '',
      operatorNumber: dp.registrationNo ?? '',
      teamName: dp.teamName ?? '',
      faultText: faultTextJson,
      faultMeter: dp.teslimAlinanMetraj ?? 0.0,
      bolgeAdi: dp.bolgeAdi ?? '',
      teslimAlinanMetraj: dp.teslimAlinanMetraj ?? 0.0,
    );
    
    reportProvider.sendReport(reportData);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Consumer<ReportProvider>(
          builder: (context, provider, child) {
            if (provider.status == ReportStatus.initial) {
              return const SizedBox.shrink();
            }

            if (provider.status == ReportStatus.sending) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                content: const SizedBox(
                  width: 400,
                  height: 150,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF046464)),
                      SizedBox(height: 24),
                      Text('Gönderiliyor, lütfen bekleyin...', style: TextStyle(fontSize: 24)),
                    ],
                  ),
                ),
              );
            }

            bool isSuccess = provider.status == ReportStatus.success;
            IconData icon = isSuccess ? Icons.check_circle : Icons.error;
            Color color = isSuccess ? Colors.green : Colors.red;
            String title = isSuccess ? 'Başarılı' : 'Hata';
            String message = isSuccess ? 'Vardiya raporu başarıyla gönderildi.' : provider.ackMessage;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(children: [
                Icon(icon, color: color, size: 64),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 34)),
              ]),
              content: SizedBox(
                width: 800,
                child: Text(message, style: const TextStyle(fontSize: 30)),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF046464),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _clearFormAndResetStatus();
                  },
                  child: const Text('Tamam', style: TextStyle(fontSize: 28)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Giriş kutusu
  Widget _input(String label, TextEditingController ctrl,
      {TextInputAction action = TextInputAction.next, bool isNumber = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF046464))),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          textInputAction: action,
          // Sayısal alanlarda sadece rakam ve nokta/virgül kabul et
          inputFormatters: isNumber
              ? [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ]
              : null,
          onChanged: isNumber ? (_) => _calculate() : null,
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFF046464), width: 2)),
          ),
        ),
      ],
    );
  }

  // Hesaplanan değer satırı
  Widget _calc(String label, double value, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFF046464).withOpacity(0.08)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: highlight ? const Color(0xFF046464) : Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: highlight
                        ? const Color(0xFF046464)
                        : Colors.black87)),
          ),
          Text(value.toStringAsFixed(2),
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: highlight
                      ? const Color(0xFF046464)
                      : Colors.black87)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LockedTabWrapper(
      child: Container(
        color: const Color(0xFFF5F7FA),
        child: KeyboardScrollableWrapper(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // İKİ KOLONLU İÇERİK
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ─── SOL KART ───
                      Expanded(
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _input('Tij Adedi', _aController),
                                _input('Bir Tij Uzunluğu (m)', _sController),
                                _calc('Tijlerin Toplam Uzunluğu (m)', _t),
                                _input('Karotiyer+Zırh+Uzatma+Portkron+Matkap Uzunluğu (m)', _mController),
                                _calc('Matkap Ucundan Su Başlığına Kadar Takım Uzunluğu (m)', _2),
                                _input('Kuyudaki muhafaza sayısı', _muhafazaSayisiController),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // ─── SAĞ KART ───
                      Expanded(
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _input('Morset Üstü Su Başlığı (m)', _uController),
                                _input('Morset Üstü Şase Altı (m)', _pController),
                                _calc('Toplam Mesafe (m)', _3),
                                _calc('Kuyu Derinliği (m)', _4),
                                _input('Yapılan İlerleme (m)', _ilerlemeController),
                                _input('Karot Boyu (m)', _karotBoyuController, action: TextInputAction.next),
                                _input('Kuyudaki muhafaza metrajı (m)', _muhafazaMetrajiController),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // ─── GÖNDER BUTONU ───
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _descController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Açıklama (Varsa)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: 250,
                          height: 60,
                          child: ElevatedButton.icon(
                            onPressed: _submitReport,
                            icon: const Icon(Icons.send),
                            label: const Text('Raporu Gönder'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF046464),
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _clearFormAndResetStatus() {
    setState(() {
      _aController.clear();
      _sController.clear();
      _mController.clear();
      _uController.clear();
      _pController.clear();
      _ilerlemeController.clear();
      _karotBoyuController.clear();
      _descController.clear();
      _muhafazaSayisiController.clear();
      _muhafazaMetrajiController.clear();
    });
    context.read<ReportProvider>().resetStatus();
  }

}
