import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/keyboard_scrollable_wrapper.dart';
import '../../providers/shift_form_provider.dart';
import '../../main.dart'; // homeKey için
import '../widgets/locked_tab_wrapper.dart';

class MalzemeTab extends StatefulWidget {
  const MalzemeTab({super.key});

  @override
  State<MalzemeTab> createState() => _MalzemeTabState();
}

class _MalzemeTabState extends State<MalzemeTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  final List<String> _tipOptions = ['Yakıt', 'Yağ', 'Kimyasal', 'Diğer'];

  void _addMalzemeDialog({int? index}) {
    final formProvider = context.read<ShiftFormProvider>();
    final isEditing = index != null;

    String selectedTip = _tipOptions.first;
    final turController = TextEditingController();
    final miktarController = TextEditingController();
    final customTipController = TextEditingController();

    if (isEditing) {
      final item = formProvider.malzemeList[index];
      if (_tipOptions.contains(item['type'])) {
        selectedTip = item['type']!;
      } else {
        selectedTip = 'Diğer';
        customTipController.text = item['type'] ?? '';
      }
      turController.text = item['brand_desc'] ?? '';
      miktarController.text = item['amount'] ?? '';
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(children: [
                Icon(isEditing ? Icons.edit : Icons.add_box, size: 40, color: const Color(0xFF046464)),
                const SizedBox(width: 16),
                Text(isEditing ? 'Malzeme Düzenle' : 'Malzeme Ekle', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              ]),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedTip,
                        decoration: InputDecoration(
                          labelText: 'Malzeme Tipi', 
                          labelStyle: const TextStyle(fontSize: 24),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        ),
                        style: const TextStyle(fontSize: 24, color: Colors.black87),
                        items: _tipOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setStateDialog(() => selectedTip = val);
                          }
                        },
                      ),
                      if (selectedTip == 'Diğer') ...[
                        const SizedBox(height: 24),
                        TextField(
                          controller: customTipController,
                          style: const TextStyle(fontSize: 24),
                          decoration: InputDecoration(
                            labelText: 'Lütfen Türü Belirtiniz',
                            labelStyle: const TextStyle(fontSize: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      TextField(
                        controller: turController,
                        style: const TextStyle(fontSize: 24),
                        decoration: InputDecoration(
                          labelText: 'Türü / Açıklaması',
                          labelStyle: const TextStyle(fontSize: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: miktarController,
                        style: const TextStyle(fontSize: 24),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Miktar (${selectedTip == 'Yağ' ? 'Teneke' : selectedTip == 'Kimyasal' ? 'Kilogram' : selectedTip == 'Yakıt' ? 'Litre' : 'Birim'})',
                          labelStyle: const TextStyle(fontSize: 24),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        ),
                      ),
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
                    String finalType = selectedTip == 'Diğer' ? customTipController.text.trim() : selectedTip;
                    if (finalType.isEmpty || turController.text.trim().isEmpty || miktarController.text.trim().isEmpty) {
                      return;
                    }
                    if (isEditing) {
                      formProvider.updateMalzeme(
                        index,
                        finalType,
                        turController.text.trim(),
                        miktarController.text.trim(),
                      );
                    } else {
                      formProvider.addMalzeme(
                        finalType,
                        turController.text.trim(),
                        miktarController.text.trim(),
                      );
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(isEditing ? 'Güncelle' : 'Ekle', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFE8F1F1),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: const Row(
        children: [
          Expanded(flex: 1, child: Text('Sıra', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF046464)))),
          Expanded(flex: 2, child: Text('Malzeme Tipi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF046464)))),
          Expanded(flex: 3, child: Text('Türü / Açıklaması', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF046464)))),
          Expanded(flex: 2, child: Text('Miktar (Birim)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF046464)))),
          Expanded(flex: 2, child: Center(child: Text('İşlem', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF046464))))),
        ],
      ),
    );
  }

  Widget _buildDataRow(int index, Map<String, String> item, ShiftFormProvider formProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text('${index + 1}', style: const TextStyle(fontSize: 16))),
          Expanded(flex: 2, child: Text(item['type'] ?? '', style: const TextStyle(fontSize: 16))),
          Expanded(flex: 3, child: Text(item['brand_desc'] ?? '', style: const TextStyle(fontSize: 16))),
          Expanded(flex: 2, child: Text(item['amount'] ?? '', style: const TextStyle(fontSize: 16))),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _addMalzemeDialog(index: index),
                  tooltip: 'Düzenle',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    formProvider.removeMalzeme(index);
                  },
                  tooltip: 'Sil',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final formProvider = context.watch<ShiftFormProvider>();
    final malzemeList = formProvider.malzemeList;

    return LockedTabWrapper(
      child: Container(
        color: const Color(0xFFF5F7FA),
        child: KeyboardScrollableWrapper(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Başlık ve Ekle Butonu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kullanılan Malzemeler',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF046464)),
                    ),
                    ElevatedButton.icon(
                      onPressed: _addMalzemeDialog,
                      icon: const Icon(Icons.add_box),
                      label: const Text('Malzeme Ekle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF046464),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Tam Ekran Tablo (Özel Liste Görünümü)
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: malzemeList.isEmpty
                        ? const Center(
                            child: Text(
                              'Henüz malzeme eklenmedi.\nSağ üstteki butondan malzeme ekleyebilirsiniz.',
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
                                  itemCount: malzemeList.length,
                                  itemBuilder: (ctx, index) {
                                    return _buildDataRow(index, malzemeList[index], formProvider);
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Sonraki Butonu
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 250,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // 10. sekme olan 'Ölçümler' sayfasına geç
                        homeKey.currentState?.goToPage(10);
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Sonraki: Ölçümler'),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
