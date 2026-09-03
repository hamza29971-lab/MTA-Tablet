import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/data_provider.dart';
import '../../models/report_data.dart';
import '../widgets/industrial_text_field.dart';
import '../../services/cloudinary_service.dart';

class KarotiyerTab extends StatefulWidget {
  const KarotiyerTab({super.key});

  @override
  State<KarotiyerTab> createState() => _KarotiyerTabState();
}

class _KarotiyerTabState extends State<KarotiyerTab> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = [];

  final TextEditingController _matkapController = TextEditingController();
  final TextEditingController _portkronController = TextEditingController();
  final TextEditingController _zirhController = TextEditingController();
  final TextEditingController _zirhAltiController = TextEditingController();
  final TextEditingController _markaModelController = TextEditingController();

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
        _markaModelController.text.trim().isEmpty ||
        _images.isEmpty) {
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
            child: Text('Lütfen formdaki tüm alanları doldurun ve en az bir fotoğraf seçin.',
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

    // Fotoğrafları Cloudinary'ye yükle
    List<String> imageUrls = [];
    if (_images.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: SizedBox(
              width: 800,
              child: Row(
                children: [
                  CircularProgressIndicator(color: Color(0xFF046464)),
                  SizedBox(width: 20),
                  Text('Fotoğraflar yükleniyor...', style: TextStyle(fontSize: 28)),
                ],
              ),
            ),
          );
        },
      );
      imageUrls = await CloudinaryService.uploadImages(_images);
      if (mounted) Navigator.of(context).pop();
    }

    if (!mounted) return;
    final reportProvider = context.read<ReportProvider>();
    final dp = context.read<DataProvider>();

    final Map<String, dynamic> payload = {
      'Test Tipi': 'Karotiyer Bilgileri',
      'Matkap': _matkapController.text.trim(),
      'Portkron': _portkronController.text.trim(),
      'Zırh': _zirhController.text.trim(),
      'Zırh Altı': _zirhAltiController.text.trim(),
      'Marka / Model': _markaModelController.text.trim(),
      'Fotoğraflar': imageUrls,
      'Tarih / Saat': DateTime.now().toIso8601String(),
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
      {TextInputAction action = TextInputAction.next}) {
    return IndustrialTextField(
      label: label,
      controller: controller,
      keyboardType: TextInputType.text,
    );
  }

  void _clearFormAndResetStatus() {
    setState(() {
      _images.clear();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: SizedBox(
          height: 750, // Sabit yükseklik, klavye açılınca daralmaz, kaydırılabilir olur
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildTextField('Matkap', _matkapController),
                            _buildTextField('Portkron', _portkronController),
                            _buildTextField('Zırh', _zirhController),
                            _buildTextField('Zırh Altı', _zirhAltiController),
                            _buildTextField(
                                'Marka / Model', _markaModelController,
                                action: TextInputAction.done),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  // ─── SAĞ KART: FOTOĞRAF ───
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.camera_alt_outlined,
                                        color: Color(0xFF046464)),
                                    SizedBox(width: 8),
                                    Text(
                                      'Karotiyer Fotoğrafı',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${_images.length} fotoğraf',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _pickImage(ImageSource.gallery),
                                    icon: const Icon(
                                        Icons.add_photo_alternate),
                                    label: const Text('Görsel Ekle'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFF046464),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _pickImage(ImageSource.camera),
                                    icon: const Icon(
                                        Icons.camera_alt_outlined),
                                    label: const Text('Fotoğraf Çek'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black87,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      side: const BorderSide(
                                          color: Colors.grey),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.grey.shade300),
                                ),
                                child: _images.isEmpty
                                    ? const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                                Icons.cloud_upload_outlined,
                                                size: 64,
                                                color: Colors.grey),
                                            SizedBox(height: 16),
                                            Text(
                                              'Henüz fotoğraf eklenmedi',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  color: Colors.black54),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Birden fazla fotoğraf seçebilirsiniz.',
                                              style: TextStyle(
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      )
                                    : GridView.builder(
                                        padding: const EdgeInsets.all(12),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
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
                                                borderRadius:
                                                    BorderRadius.circular(8),
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
                                                      _images
                                                          .removeAt(index);
                                                    });
                                                  },
                                                  child: Container(
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Colors.black54,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    padding:
                                                        const EdgeInsets.all(
                                                            4),
                                                    child: const Icon(
                                                        Icons.close,
                                                        color: Colors.white,
                                                        size: 16),
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
            // ─── GÖNDER BUTONU ───
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
    )));
  }
}
