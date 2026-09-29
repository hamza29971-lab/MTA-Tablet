import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../widgets/keyboard_scrollable_wrapper.dart';
import '../widgets/locked_tab_wrapper.dart';
import '../widgets/industrial_text_field.dart';

class WellCompletionTab extends StatefulWidget {
  const WellCompletionTab({super.key});

  @override
  State<WellCompletionTab> createState() => _WellCompletionTabState();
}

class _WellCompletionTabState extends State<WellCompletionTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _kuyuAdiController = TextEditingController();
  final TextEditingController _kampAdiController = TextEditingController();
  final TextEditingController _kuyuMetrajiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Kuyu Adı ve Kamp Adı sisteme kaydedilen değerle önceden doldurulur
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final dp = context.read<DataProvider>();
        // Kamp Adı otomatik gelir (readOnly)
        _kampAdiController.text = dp.kampAdi ?? '';
        // Kuyu Adı boş açılır, kullanıcı elle yazar
      }
    });
  }

  @override
  void dispose() {
    _kuyuAdiController.dispose();
    _kampAdiController.dispose();
    _kuyuMetrajiController.dispose();
    super.dispose();
  }

  void _completeWell(BuildContext context) {
    final dp = context.read<DataProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 64),
            SizedBox(width: 12),
            Text('Kuyuyu Tamamla',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 34)),
          ],
        ),
        content: const SizedBox(
          width: 800,
          child: Text(
            'Kuyu tamamlandı olarak işaretlenecek ve sistem kilitlenecektir. '
            'Yeni kuyu için "Rapor Gönder" sayfasından tekrar giriş yapılabilecektir. '
            'Onaylıyor musunuz?',
            style: TextStyle(fontSize: 30),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal',
                style: TextStyle(fontSize: 24, color: Colors.grey)),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              dp.clearOperatorInfo();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Kuyu başarıyla tamamlandı. Yeni kayıt girebilirsiniz.')),
              );
              _kuyuAdiController.clear();
              _kampAdiController.clear();
              _kuyuMetrajiController.clear();
            },
            child: const Text('Evet, Tamamla', style: TextStyle(fontSize: 28)),
          ),
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
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ana İçerik — Karot Bilgileri ile birebir aynı yapı
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 800,
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(48.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Başlık
                              const Text(
                                'Kuyu Bitiş Sayfası',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF046464),
                                ),
                              ),
                              const SizedBox(height: 32),
                              // Kuyu Adı — düzenlenebilir, initState'te doldurulur
                              IndustrialTextField(
                                label: 'Kuyu Adı',
                                controller: _kuyuAdiController,
                              ),
                              const SizedBox(height: 24),
                              // Kamp Adı — otomatik gelir, readOnly
                              IndustrialTextField(
                                label: 'Kamp Adı',
                                controller: _kampAdiController,
                                readOnly: true,
                              ),
                              const SizedBox(height: 24),
                              // Kuyu Metrajı — elle girilir
                              IndustrialTextField(
                                label: 'Kuyu Metrajı (m)',
                                controller: _kuyuMetrajiController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Kuyu Tamamlandı Butonu — Karot Bilgileri "Raporu Gönder" ile aynı
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 250,
                    child: ElevatedButton.icon(
                      onPressed: () => _completeWell(context),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Kuyu Tamamlandı'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
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
