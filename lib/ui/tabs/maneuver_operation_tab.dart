import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/report_data.dart';
import '../../providers/report_provider.dart';
import '../../providers/data_provider.dart';
import '../widgets/locked_tab_wrapper.dart';
import '../widgets/keyboard_scrollable_wrapper.dart';

class ManeuverOperationTab extends StatefulWidget {
  const ManeuverOperationTab({super.key});

  @override
  State<ManeuverOperationTab> createState() => _ManeuverOperationTabState();
}

class _ManeuverOperationTabState extends State<ManeuverOperationTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Her manevra: {karot_orani, tij_uzunlugu, manevra_boyu, kuyu_metraji}
  final List<Map<String, String>> _maneuvers = [];

  // ── Manevra Ekle Dialog ────────────────────────────────────────────────
  void _addManeuverDialog({int? editIndex}) {
    final isEditing = editIndex != null;
    final karotController = TextEditingController(
      text: isEditing ? _maneuvers[editIndex]['karot_orani'] : '',
    );
    final tijController = TextEditingController(
      text: isEditing ? _maneuvers[editIndex]['tij_uzunlugu'] : '',
    );
    final manevraBaslangicController = TextEditingController(
      text: isEditing ? _maneuvers[editIndex]['manevra_baslangic'] : '',
    );
    final manevraBitisController = TextEditingController(
      text: isEditing ? _maneuvers[editIndex]['manevra_bitis'] : '',
    );
    final kuyuMetrajiController = TextEditingController(
      text: isEditing ? _maneuvers[editIndex]['kuyu_metraji'] : '',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Icon(isEditing ? Icons.edit : Icons.add_circle_outline,
                size: 40, color: const Color(0xFF046464)),
            const SizedBox(width: 16),
            Text(
              isEditing ? 'Manevrayı Düzenle' : 'Manevra Ekle',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ]),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogField('Karot Oranı', karotController),
                  const SizedBox(height: 24),
                  _buildDialogField('Tij Uzunluğu', tijController),
                  const SizedBox(height: 24),
                  _buildDialogField('Manevra Başlangıç', manevraBaslangicController),
                  const SizedBox(height: 24),
                  _buildDialogField('Manevra Bitiş', manevraBitisController),
                  const SizedBox(height: 24),
                  _buildDialogField('Kuyu Metrajı', kuyuMetrajiController),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal', style: TextStyle(fontSize: 24, color: Colors.grey)),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF046464),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final entry = {
                  'karot_orani': karotController.text.trim(),
                  'tij_uzunlugu': tijController.text.trim(),
                  'manevra_baslangic': manevraBaslangicController.text.trim(),
                  'manevra_bitis': manevraBitisController.text.trim(),
                  'kuyu_metraji': kuyuMetrajiController.text.trim(),
                };
                setState(() {
                  if (isEditing) {
                    _maneuvers[editIndex] = entry;
                  } else {
                    _maneuvers.add(entry);
                  }
                });
                Navigator.pop(ctx);
              },
              child: Text(
                isEditing ? 'Güncelle' : 'Ekle',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 24),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 24),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      ),
    );
  }

  // ── Tablo başlık satırı ────────────────────────────────────────────────
  Widget _buildHeaderRow() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFE8F1F1),
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: const Row(
        children: [
          Expanded(flex: 1, child: Text('Sıra', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF046464)))),
          Expanded(flex: 2, child: Center(child: Text('Karot Oranı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF046464))))),
          Expanded(flex: 2, child: Center(child: Text('Tij Uzunluğu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF046464))))),
          Expanded(flex: 2, child: Center(child: Text('Başlangıç', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF046464))))),
          Expanded(flex: 2, child: Center(child: Text('Bitiş', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF046464))))),
          Expanded(flex: 2, child: Center(child: Text('Kuyu Metrajı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF046464))))),
          Expanded(flex: 2, child: Center(child: Text('İşlem', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF046464))))),
        ],
      ),
    );
  }

  // ── Tablo veri satırı ────────────────────────────────────────────────
  Widget _buildDataRow(int index, Map<String, String> m) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text('${index + 1}', style: const TextStyle(fontSize: 16))),
          Expanded(flex: 2, child: Center(child: Text(m['karot_orani'] ?? '', style: const TextStyle(fontSize: 16)))),
          Expanded(flex: 2, child: Center(child: Text(m['tij_uzunlugu'] ?? '', style: const TextStyle(fontSize: 16)))),
          Expanded(flex: 2, child: Center(child: Text(m['manevra_baslangic'] ?? '', style: const TextStyle(fontSize: 16)))),
          Expanded(flex: 2, child: Center(child: Text(m['manevra_bitis'] ?? '', style: const TextStyle(fontSize: 16)))),
          Expanded(flex: 2, child: Center(child: Text(m['kuyu_metraji'] ?? '', style: const TextStyle(fontSize: 16)))),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _addManeuverDialog(editIndex: index),
                  tooltip: 'Düzenle',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setState(() => _maneuvers.removeAt(index)),
                  tooltip: 'Sil',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Raporu Gönder ────────────────────────────────────────────────────
  Future<void> _submitReport() async {
    if (_maneuvers.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 64),
              SizedBox(width: 12),
              Text('Eksik Bilgi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 34)),
            ],
          ),
          content: const SizedBox(
            width: 800,
            child: Text('Lütfen en az bir manevra ekleyin.', style: TextStyle(fontSize: 30)),
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
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    final reportProvider = context.read<ReportProvider>();
    final dp = context.read<DataProvider>();

    final Map<String, dynamic> payload = {
      'type': 'maneuver_operation',
      'maneuvers': _maneuvers,
      'datetime': DateTime.now().toIso8601String(),
    };

    final reportData = ReportData(
      operatorName: dp.operatorName ?? '',
      kuyuName: dp.wellNo ?? '',
      operatorNumber: dp.registrationNo ?? '',
      teamName: dp.teamName ?? '',
      faultText: jsonEncode(payload),
      faultMeter: dp.teslimAlinanMetraj ?? 0.0,
      bolgeAdi: dp.bolgeAdi ?? '',
      kampAdi: dp.kampAdi ?? '',
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
            String message = isSuccess ? 'Manevra raporu başarıyla gönderildi.' : provider.ackMessage;

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
                      setState(() => _maneuvers.clear());
                    }
                    context.read<ReportProvider>().resetStatus();
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

  // ── Build ────────────────────────────────────────────────────────────
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Başlık ve Manevra Ekle Butonu — PersonnelReportTab ile aynı
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Manevra Listesi',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF046464)),
                    ),
                    ElevatedButton.icon(
                      onPressed: _addManeuverDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Manevra Ekle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF046464),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tam Ekran Tablo — PersonnelReportTab ile aynı
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: _maneuvers.isEmpty
                        ? const Center(
                            child: Text(
                              'Henüz manevra eklenmedi.\nSağ üstteki butondan manevra ekleyebilirsiniz.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeaderRow(),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _maneuvers.length,
                                  itemBuilder: (ctx, index) =>
                                      _buildDataRow(index, _maneuvers[index]),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Raporu Gönder — PersonnelReportTab'daki "Sonraki" butonu ile aynı boyut/stil
                Align(
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
                        textStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
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
      ),
    );
  }
}
