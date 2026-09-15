import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../widgets/keyboard_scrollable_wrapper.dart';
import '../../services/mqtt_service.dart';
import '../../services/udp_service.dart';
import '../../services/cloudinary_service.dart';
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
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = [];
  
  // Text Controllers

  final TextEditingController _kuyuNoController = TextEditingController();
  final TextEditingController _metrajBaslangicController = TextEditingController();
  final TextEditingController _metrajBitisController = TextEditingController();

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> selectedImages = await _picker.pickMultiImage();
        if (selectedImages.isNotEmpty) {
          setState(() {
            _images.addAll(selectedImages);
          });
        }
      } else {
        final XFile? photo = await _picker.pickImage(source: source);
        if (photo != null) {
          setState(() {
            _images.add(photo);
          });
        }
      }
    } catch (e) {
      debugPrint('Fotoğraf seçme hatası: $e');
    }
  }

  Future<void> _submitReport() async {
    FocusScope.of(context).unfocus();

    final isKuyuEmpty = _kuyuNoController.text.trim().isEmpty;
    final isMetrajBasEmpty = _metrajBaslangicController.text.trim().isEmpty;
    final isMetrajBitEmpty = _metrajBitisController.text.trim().isEmpty;
    final isImagesEmpty = _images.isEmpty;

    if (isKuyuEmpty || isMetrajBasEmpty || isMetrajBitEmpty) {
      String errorMsg = 'Lütfen metin alanlarını (Kuyu No, Metraj) doldurun.';

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

    // Fotoğraflar JSON formatını bozmamak için her zaman boş liste olarak gönderilir
    List<String> imageUrls = [];

    if (!mounted) return;
    final reportProvider = context.read<ReportProvider>();
    final dp = context.read<DataProvider>();
    
    // Sadece API'ye gönderilecek verileri hazırla
    final Map<String, dynamic> payload = {
      'type': 'core_log',
      'well_no': _kuyuNoController.text,
      'start_m': double.tryParse(_metrajBaslangicController.text.replaceAll(',', '.')) ?? 0.0,
      'end_m': double.tryParse(_metrajBitisController.text.replaceAll(',', '.')) ?? 0.0,
      'photos': imageUrls,
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

  Widget _buildTextField(String label, TextEditingController controller) {
    return IndustrialTextField(
      label: label,
      controller: controller,
      keyboardType: TextInputType.text,
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
            // Ana İçerik (İki Kolon)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // SOL KOLON: FORM (Karot Logu, Kuyu No, Metraj)
                  Expanded(
                    flex: 1,
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextField('Kuyu No', _kuyuNoController),
                            const SizedBox(height: 24),
                            // Metraj Alanı
                            const Text(
                              'Metraj',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF046464)),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: IndustrialTextField(
                                    controller: _metrajBaslangicController,
                                    label: '',
                                    hintText: 'Başlangıç',
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(
                                    '-',
                                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey),
                                  ),
                                ),
                                Expanded(
                                  child: IndustrialTextField(
                                    controller: _metrajBitisController,
                                    label: '',
                                    hintText: 'Bitiş',
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.done,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  // SAĞ KOLON: GÖRSELLER
                  Expanded(
                    flex: 1,
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.camera_alt_outlined, color: Color(0xFF046464)),
                                    SizedBox(width: 8),
                                    Text(
                                      'Karot Fotoğrafı',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${_images.length} fotoğraf',
                                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {}, // Fotoğraf özelliği iptal edildi (sadece görsel)
                                icon: const Icon(Icons.camera_alt_outlined),
                                label: const Text('Fotoğraf Çek'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: const BorderSide(color: Colors.grey),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: _images.isEmpty
                                    ? const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.cloud_upload_outlined, size: 64, color: Colors.grey),
                                            SizedBox(height: 16),
                                            Text(
                                              'Henüz fotoğraf eklenmedi',
                                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Birden fazla fotoğraf seçebilirsiniz.',
                                              style: TextStyle(color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      )
                                    : GridView.builder(
                                        padding: const EdgeInsets.all(12),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                        ),
                                        itemCount: _images.length,
                                        itemBuilder: (context, index) {
                                          return Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.file(
                                                  File(_images[index].path),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      _images.removeAt(index);
                                                    });
                                                  },
                                                  child: Container(
                                                    decoration: const BoxDecoration(
                                                      color: Colors.black54,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    padding: const EdgeInsets.all(4),
                                                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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
                  label: const Text('Gönder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF046464),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    padding: const EdgeInsets.symmetric(vertical: 20),
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
      _images.clear();
      _kuyuNoController.clear();
      _metrajBaslangicController.clear();
      _metrajBitisController.clear();
    });
    context.read<ReportProvider>().resetStatus();
  }

}
