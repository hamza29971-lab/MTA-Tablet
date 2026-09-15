import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/mqtt_service.dart';
import '../../services/udp_service.dart';
import '../widgets/keyboard_scrollable_wrapper.dart';
import '../../models/report_data.dart';
import '../widgets/industrial_text_field.dart';
import '../../providers/report_provider.dart';
import '../../providers/data_provider.dart';
import '../widgets/locked_tab_wrapper.dart';

class KarotiyerTab extends StatefulWidget {
  const KarotiyerTab({super.key});

  @override
  State<KarotiyerTab> createState() => _KarotiyerTabState();
}

class _KarotiyerTabState extends State<KarotiyerTab> {
  final TextEditingController _matkapController = TextEditingController();
  final TextEditingController _portkronController = TextEditingController();
  final TextEditingController _zirhController = TextEditingController();
  final TextEditingController _zirhAltiController = TextEditingController();
  final TextEditingController _markaModelController = TextEditingController();

  @override
  void dispose() {
    _matkapController.dispose();
    _portkronController.dispose();
    _zirhController.dispose();
    _zirhAltiController.dispose();
    _markaModelController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    FocusScope.of(context).unfocus();

    if (_matkapController.text.trim().isEmpty ||
        _portkronController.text.trim().isEmpty ||
        _zirhController.text.trim().isEmpty ||
        _zirhAltiController.text.trim().isEmpty ||
        _markaModelController.text.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 64),
            SizedBox(width: 12),
            Text('Eksik Bilgi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 34)),
          ]),
          content: const SizedBox(
            width: 800,
            child: Text('Lütfen formdaki tüm alanları doldurun.',
                style: TextStyle(fontSize: 30)),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF046464),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Tamam', style: TextStyle(fontSize: 28)),
            )
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    final reportProvider = context.read<ReportProvider>();
    final dp = context.read<DataProvider>();

    final Map<String, dynamic> payload = {
      'type': 'karotiyer',
      'drill': _matkapController.text.trim(),
      'port': _portkronController.text.trim(),
      'armor': _zirhController.text.trim(),
      'sub_arm': _zirhAltiController.text.trim(),
      'brand_mod': _markaModelController.text.trim(),
      'photos': [],
      'datetime': DateTime.now().toIso8601String(),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                content: const SizedBox(
                  width: 400,
                  height: 150,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF046464)),
                      SizedBox(height: 24),
                      Text('Gönderiliyor, lütfen bekleyin...',
                          style: TextStyle(fontSize: 24)),
                    ],
                  ),
                ),
              );
            }

            bool isSuccess = provider.status == ReportStatus.success;
            IconData icon = isSuccess ? Icons.check_circle : Icons.error;
            Color color = isSuccess ? Colors.green : Colors.red;
            String title = isSuccess ? 'Başarılı' : 'Hata';
            String message = isSuccess
                ? 'Karotiyer bilgileri başarıyla gönderildi.'
                : provider.ackMessage;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(children: [
                Icon(icon, color: color, size: 64),
                const SizedBox(width: 12),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 34)),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 20),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    if (isSuccess) {
                      // context.read<DataProvider>().clearOperatorInfo();
                    }
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

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputAction action = TextInputAction.next, bool isNumber = true}) {
    return IndustrialTextField(
      label: label,
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
    );
  }

  void _clearFormAndResetStatus() {
    setState(() {
      _matkapController.clear();
      _portkronController.clear();
      _zirhController.clear();
      _zirhAltiController.clear();
      _markaModelController.clear();
    });
    context.read<ReportProvider>().resetStatus();
  }

  @override
  Widget build(BuildContext context) {
    return LockedTabWrapper(
      child: Container(
        color: const Color(0xFFF5F7FA),
        child: KeyboardScrollableWrapper(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ana İçerik (İki Kolon)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── SOL KART: FORM ───
                  Expanded(
                    flex: 1,
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextField('Matkap', _matkapController),
                            _buildTextField('Portkron', _portkronController),
                            _buildTextField('Zırh', _zirhController),
                            _buildTextField('Zırh Altı', _zirhAltiController),
                            _buildTextField('Marka / Model', _markaModelController, action: TextInputAction.done, isNumber: false),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  // ─── SAĞ GÖRSEL ───
                  Expanded(
                    flex: 1,
                    child: Image.asset(
                      'assets/images/core_barrel_diagram.png',
                      fit: BoxFit.contain,
                      color: const Color(0xFFF5F7FA),
                      colorBlendMode: BlendMode.multiply,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // ─── GÖNDER BUTONU ───
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 250,
                child: ElevatedButton.icon(
                  onPressed: _submitReport,
                  icon: const Icon(Icons.send),
                  label: const Text('Raporu Gönder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF046464),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    ));
  }
}
