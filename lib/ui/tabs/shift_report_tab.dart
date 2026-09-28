import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/shift_form_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/data_provider.dart';
import '../../main.dart'; // homeKey için
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

  // Giriş kutusu
  Widget _input(String label, TextEditingController ctrl,
      {TextInputAction action = TextInputAction.next, bool isNumber = true, bool readOnly = false}) {
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
          readOnly: readOnly,
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          textInputAction: action,
          inputFormatters: isNumber
              ? [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ]
              : null,
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
    final formProvider = context.watch<ShiftFormProvider>();

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
                                _input('Tij Adedi', formProvider.aController),
                                _input('Bir Tij Uzunluğu (m)', formProvider.sController),
                                _calc('Tijlerin Toplam Uzunluğu (m)', formProvider.t),
                                _input('Karotiyer+Zırh+Uzatma+Portkron+Matkap Uzunluğu (m)', formProvider.mController),
                                _calc('Matkap Ucundan Su Başlığına Kadar Takım Uzunluğu (m)', formProvider.v2),
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
                                _input('Morset Üstü Su Başlığı (m)', formProvider.uController),
                                _input('Morset Üstü Şase Altı (m)', formProvider.pController),
                                _calc('Toplam Mesafe (m)', formProvider.v3),
                                _calc('Kuyu Derinliği (m)', formProvider.v4),
                                _input('Yapılan İlerleme (m)', formProvider.ilerlemeController),
                                _input('Karot Boyu (m)', formProvider.karotBoyuController, action: TextInputAction.next),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // ─── ALT KISIM ───
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: formProvider.descController,
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
                            onPressed: () {
                              final reportProvider = context.read<ReportProvider>();
                              final dataProvider = context.read<DataProvider>();
                              formProvider.submitReport(context, reportProvider, dataProvider);
                            },
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
}
