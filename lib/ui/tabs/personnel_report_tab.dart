import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/shift_form_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/data_provider.dart';
import '../../main.dart'; // homeKey için
import '../widgets/locked_tab_wrapper.dart';
import '../widgets/keyboard_scrollable_wrapper.dart';

class PersonnelReportTab extends StatefulWidget {
  const PersonnelReportTab({super.key});

  @override
  State<PersonnelReportTab> createState() => _PersonnelReportTabState();
}

class _PersonnelReportTabState extends State<PersonnelReportTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final List<String> _titles = ['Vardiya Sondörü', 'Kule Şefi', 'Kamp Şefi', 'Sondaj Personeli', 'Şoför'];

  void _addPersonDialog({int? index}) {
    final formProvider = context.read<ShiftFormProvider>();
    final isEditing = index != null;

    String selectedTitle = _titles.first;
    final nameController = TextEditingController();
    bool isOnLeave = false;

    if (isEditing) {
      final person = formProvider.personnelList[index];
      if (_titles.contains(person['title'])) {
        selectedTitle = person['title']!;
      }
      String nm = person['name'] ?? '';
      if (nm.endsWith(' (İzinli)')) {
        isOnLeave = true;
        nameController.text = nm.substring(0, nm.length - 9).trim();
      } else {
        nameController.text = nm;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(children: [
                Icon(isEditing ? Icons.edit : Icons.person_add, size: 40, color: const Color(0xFF046464)),
                const SizedBox(width: 16),
                Text(isEditing ? 'Kişiyi Düzenle' : 'Kişi Ekle', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              ]),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedTitle,
                        decoration: InputDecoration(
                          labelText: 'Ünvan', 
                          labelStyle: const TextStyle(fontSize: 24),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        ),
                        style: const TextStyle(fontSize: 24, color: Colors.black87),
                        items: _titles.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setStateDialog(() => selectedTitle = val);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: nameController,
                        style: const TextStyle(fontSize: 24),
                        decoration: InputDecoration(
                          labelText: 'İsim Soyisim',
                          labelStyle: const TextStyle(fontSize: 24),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        ),
                      ),
                      const SizedBox(height: 24),
                      CheckboxListTile(
                        title: const Text('İzinli', style: TextStyle(fontSize: 20)),
                        value: isOnLeave,
                        activeColor: const Color(0xFF046464),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (bool? val) {
                          setStateDialog(() {
                            isOnLeave = val ?? false;
                          });
                        },
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
                    if (nameController.text.trim().isEmpty) {
                      return;
                    }
                    String finalName = nameController.text.trim();
                    if (isOnLeave) {
                      finalName += ' (İzinli)';
                    }

                    if (isEditing) {
                      formProvider.updatePerson(
                        index,
                        selectedTitle,
                        finalName,
                        '',
                      );
                    } else {
                      formProvider.addPerson(
                        selectedTitle,
                        finalName,
                        '',
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
          Expanded(flex: 3, child: Text('İsim Soyisim', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF046464)))),
          Expanded(flex: 2, child: Text('Ünvan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF046464)))),
          Expanded(flex: 2, child: Center(child: Text('İşlem', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF046464))))),
        ],
      ),
    );
  }

  Widget _buildDataRow(int index, Map<String, String> p, ShiftFormProvider formProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text('${index + 1}', style: const TextStyle(fontSize: 16))),
          Expanded(flex: 3, child: Text(p['name'] ?? '', style: const TextStyle(fontSize: 16))),
          Expanded(flex: 2, child: Text(p['title'] ?? '', style: const TextStyle(fontSize: 16))),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _addPersonDialog(index: index),
                  tooltip: 'Düzenle',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => formProvider.removePerson(index),
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
    final personnelList = formProvider.personnelList;

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
                      'Personel Listesi',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF046464)),
                    ),
                    ElevatedButton.icon(
                      onPressed: personnelList.length >= 10 ? null : () => _addPersonDialog(),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Kişi Ekle'),
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
                    child: personnelList.isEmpty
                        ? const Center(
                            child: Text(
                              'Henüz kişi eklenmedi.\nSağ üstteki butondan personel ekleyebilirsiniz.',
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
                                  itemCount: personnelList.length,
                                  itemBuilder: (ctx, index) {
                                    return _buildDataRow(index, personnelList[index], formProvider);
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Sonraki Sayfaya Geç Butonu
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 250,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        homeKey.currentState?.goToPage(9);
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Sonraki: Malzemeler'),
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
