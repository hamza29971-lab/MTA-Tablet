import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/keyboard_scrollable_wrapper.dart';
import '../../providers/report_provider.dart';
import '../../providers/data_provider.dart';
import '../../models/report_data.dart';
import '../widgets/industrial_text_field.dart';
import '../widgets/locked_tab_wrapper.dart';

class CoreLogTab extends StatefulWidget {
  const CoreLogTab({super.key});

  @override
  State<CoreLogTab> createState() => _CoreLogTabState();
}

class _CoreLogTabState extends State<CoreLogTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  // Text Controllers
  final TextEditingController _elmasNoController = TextEditingController();
  final TextEditingController _boruAdediController = TextEditingController();
  final TextEditingController _boruMetrajController = TextEditingController();

  Future<void> _submitReport() async {
    FocusScope.of(context).unfocus();

    final isElmasEmpty = _elmasNoController.text.trim().isEmpty;
    final isBoruAdediEmpty = _boruAdediController.text.trim().isEmpty;
    final isBoruMetrajEmpty = _boruMetrajController.text.trim().isEmpty;

    if (isElmasEmpty || isBoruAdediEmpty || isBoruMetrajEmpty) {
      String errorMsg = 'Lütfen metin alanlarını (Elmas Numarası, Boru Adedi, Boru Metrajı) doldurun.';

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 64),
                SizedBox(width: 12),
                Text('Eksik Bilgi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 34)),
              ],
            ),
            content: SizedBox(
              width: 800,
              child: Text(
                errorMsg,
                style: const TextStyle(fontSize: 30),
              ),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF046464),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tamam', style: TextStyle(fontSize: 28)),
              )
            ],
          );
        },
      );
      return;
    }

    if (!mounted) return;
    final reportProvider = context.read<ReportProvider>();
    final dp = context.read<DataProvider>();
    
    // Sadece API'ye gönderilecek verileri hazırla
    final Map<String, dynamic> payload = {
      'type': 'core_log',
      'diamond_no': _elmasNoController.text,
      'pipe_count': int.tryParse(_boruAdediController.text) ?? 0,
      'pipe_length': double.tryParse(_boruMetrajController.text.replaceAll(',', '.')) ?? 0.0,
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
      tijAdedi: dp.tijAdedi ?? 0.0,
      morsetUstu: dp.morsetUstu ?? 0.0,
    );
    
    reportProvider.sendReport(reportData);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Consumer<ReportProvider>(
          builder: (context, provider, child) {
            if (provider.status == ReportStatus.initial) {
              return const SizedBox.shrink(); // Popup kapanmadan hemen önceki salise için
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
            String message = isSuccess ? 'Karot bilgileri başarıyla gönderildi.' : provider.ackMessage;

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
                    if (isSuccess) {
                      _clearFormAndResetStatus();
                    } else {
                      context.read<ReportProvider>().resetStatus();
                    }
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

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return IndustrialTextField(
      label: label,
      controller: controller,
      keyboardType: keyboardType,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LockedTabWrapper(
      child: Container(
        color: const Color(0xFFF5F7FA), // Açık gri/mavi arkaplan
        child: KeyboardScrollableWrapper(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ana İçerik (Tek Kolon Ortalanmış)
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 800,
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(48.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTextField('Elmas Numarası', _elmasNoController),
                          const SizedBox(height: 24),
                          _buildTextField('Boru Adedi', _boruAdediController, keyboardType: TextInputType.number),
                          const SizedBox(height: 24),
                          _buildTextField('Boru Metrajı (m)', _boruMetrajController, keyboardType: TextInputType.number),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // GÖNDER BUTONU EN ALTTA SAĞDA
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
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  void _clearFormAndResetStatus() {
    setState(() {
      _elmasNoController.clear();
      _boruAdediController.clear();
      _boruMetrajController.clear();
    });
    context.read<ReportProvider>().resetStatus();
  }

}
