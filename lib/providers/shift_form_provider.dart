import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'report_provider.dart';
import 'data_provider.dart';
import '../models/report_data.dart';

class ShiftFormProvider extends ChangeNotifier {
  final List<Map<String, String>> personnelList = [];
  final List<Map<String, String>> malzemeList = [];

  final TextEditingController aController = TextEditingController();
  final TextEditingController sController = TextEditingController();
  final TextEditingController mController = TextEditingController();
  final TextEditingController uController = TextEditingController();
  final TextEditingController pController = TextEditingController();
  final TextEditingController ilerlemeController = TextEditingController();
  final TextEditingController karotBoyuController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController muhafazaMetrajiController = TextEditingController();

  double t = 0.0;
  double v2 = 0.0;
  double v3 = 0.0;
  double v4 = 0.0;

  ShiftFormProvider() {
    aController.addListener(calculate);
    sController.addListener(calculate);
    mController.addListener(calculate);
    uController.addListener(calculate);
    pController.addListener(calculate);
  }

  void calculate() {
    double a = double.tryParse(aController.text.replaceAll(',', '.')) ?? 0.0;
    double s = double.tryParse(sController.text.replaceAll(',', '.')) ?? 0.0;
    double m = double.tryParse(mController.text.replaceAll(',', '.')) ?? 0.0;
    double u = double.tryParse(uController.text.replaceAll(',', '.')) ?? 0.0;
    double p = double.tryParse(pController.text.replaceAll(',', '.')) ?? 0.0;
    
    t = a * s;
    v2 = t + m;
    v3 = p + u;
    v4 = v2 - v3;
    notifyListeners();
  }

  void addPerson(String title, String name, String regNo) {
    personnelList.add({
      'title': title,
      'name': name,
      'reg_no': regNo,
    });
    notifyListeners();
  }

  void updatePerson(int index, String title, String name, String regNo) {
    personnelList[index] = {
      'title': title,
      'name': name,
      'reg_no': regNo,
    };
    notifyListeners();
  }

  void removePerson(int index) {
    personnelList.removeAt(index);
    notifyListeners();
  }

  void clearPersonnel() {
    personnelList.clear();
    notifyListeners();
  }

  void addMalzeme(String type, String brandDesc, String amount) {
    malzemeList.add({
      'type': type,
      'brand_desc': brandDesc,
      'amount': amount,
    });
    notifyListeners();
  }

  void updateMalzeme(int index, String type, String brandDesc, String amount) {
    malzemeList[index] = {
      'type': type,
      'brand_desc': brandDesc,
      'amount': amount,
    };
    notifyListeners();
  }

  void removeMalzeme(int index) {
    malzemeList.removeAt(index);
    notifyListeners();
  }

  void clearMalzeme() {
    malzemeList.clear();
    notifyListeners();
  }

  void clearForm() {
    aController.clear();
    sController.clear();
    mController.clear();
    uController.clear();
    pController.clear();
    ilerlemeController.clear();
    karotBoyuController.clear();
    descController.clear();
    muhafazaMetrajiController.clear();
    t = 0.0;
    v2 = 0.0;
    v3 = 0.0;
    v4 = 0.0;
    // clearPersonnel(); // YENİ: Personel listesinin vardiya sonu silinmemesi için kapatıldı.
    clearMalzeme();
  }

  bool validateForm(BuildContext context) {
    if (aController.text.trim().isEmpty ||
        sController.text.trim().isEmpty ||
        mController.text.trim().isEmpty ||
        uController.text.trim().isEmpty ||
        pController.text.trim().isEmpty ||
        ilerlemeController.text.trim().isEmpty ||
        karotBoyuController.text.trim().isEmpty) {
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
            child: Text('Lütfen Ölçümler sekmesindeki tüm zorunlu alanları eksiksiz doldurun.', style: TextStyle(fontSize: 30)),
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
      return false;
    }
    return true;
  }

  void submitReport(BuildContext context, ReportProvider reportProvider, DataProvider dp) {
    FocusScope.of(context).unfocus();
    if (!validateForm(context)) return;

    final Map<String, dynamic> payload = {
      'type': 'shift',

      'rod_cnt': double.tryParse(aController.text.replaceAll(',', '.')) ?? 0.0,
      'rod_len': double.tryParse(sController.text.replaceAll(',', '.')) ?? 0.0,
      'tot_rod_len': double.parse(t.toStringAsFixed(2)),
      'tool_len': double.tryParse(mController.text.replaceAll(',', '.')) ?? 0.0,
      'tot_tool_len': double.parse(v2.toStringAsFixed(2)),
      'mors_wat': double.tryParse(uController.text.replaceAll(',', '.')) ?? 0.0,
      'mors_und': double.tryParse(pController.text.replaceAll(',', '.')) ?? 0.0,
      'tot_m': double.parse(v3.toStringAsFixed(2)),
      'well_depth': double.parse(v4.toStringAsFixed(2)),
      'adv_m': double.tryParse(ilerlemeController.text.replaceAll(',', '.')) ?? 0.0,
      'core_m': karotBoyuController.text,
      'cas_len': muhafazaMetrajiController.text,
      'desc': descController.text,
      'personnel_list': personnelList,
      'material_list': malzemeList.map((m) {
        String engType = m['type'] ?? '';
        if (engType == 'Yakıt') engType = 'Fuel';
        else if (engType == 'Yağ') engType = 'Oil';
        else if (engType == 'Kimyasal') engType = 'Chemical';
        return {
          'type': engType,
          'brand_desc': m['brand_desc'],
          'amount': m['amount'],
        };
      }).toList(),
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
                    clearForm();
                    provider.resetStatus();
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
}
