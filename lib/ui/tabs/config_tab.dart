// lib/ui/tabs/config_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/app_config.dart';
import '../../providers/config_provider.dart';
import '../../utils/app_dialogs.dart';

class ConfigTab extends StatefulWidget {
  const ConfigTab({super.key});

  @override
  State<ConfigTab> createState() => _ConfigTabState();
}

class _ConfigTabState extends State<ConfigTab> {
  bool _isAuthenticated = false;
  final TextEditingController _passwordController = TextEditingController();
  final String _correctPassword = "1864"; // Şifreyi burada belirliyoruz

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _authenticate() {
    if (_passwordController.text == _correctPassword) {
      setState(() {
        _isAuthenticated = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hatalı şifre!'),
          backgroundColor: Colors.red,
        ),
      );
    }
    _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Eğer kimlik doğrulanmadıysa şifre ekranını, doğrulandıysa ayar listesini göster
    return _isAuthenticated ? _buildConfigScreen() : _buildPasswordScreen();
  }

  // Şifre Giriş Ekranı
  Widget _buildPasswordScreen() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 60, color: Colors.grey),
            const SizedBox(height: 24),
            Text('Ayarları Görüntülemek İçin Şifre Girin', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Şifre',
              ),
              onSubmitted: (_) => _authenticate(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _authenticate,
              child: const Text('Giriş Yap'),
            ),
          ],
        ),
      ),
    );
  }

  // Ayarların Listelendiği Ekran
// lib/ui/tabs/config_tab.dart

  Widget _buildConfigScreen() {
    final provider = context.watch<ConfigurationProvider>();
    final configs = provider.appConfig.gaugeConfigs.values.toList();
    
    // Doğru sıralama mantığı
    configs.sort((a, b) {
      var partsA = a.id.split('_');
      var partsB = b.id.split('_');
      int prefixCompare = partsA[0].compareTo(partsB[0]);
      if (prefixCompare != 0) return prefixCompare;
      int numA = int.tryParse(partsA.length > 1 ? partsA[1] : '0') ?? 0;
      int numB = int.tryParse(partsB.length > 1 ? partsB[1] : '0') ?? 0;
      return numA.compareTo(numB);
    });

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // FAB için altta boşluk
        children: [
          _HomePageGaugeSelector(),
          const SizedBox(height: 16),
          // Eğim Kaynakları Ayar Kartı
          _InclinationSourceEditor(),
          const SizedBox(height: 16),
          // Mevcut ayar kartları
          ...configs.map((config) => _ConfigEditorCard(
                key: ValueKey(config.id),
                config: config,
              )).toList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          AppDialogs.showStandardDialog(
            context,
            title: 'Ayarları Sıfırla',
            message: 'Tüm ayarlar varsayılan fabrika ayarlarına döndürülecektir. Bu işlem geri alınamaz. Emin misiniz?',
            color: Colors.red,
            icon: Icons.warning,
            onConfirm: provider.restoreToDefaults,
          );
        },
        icon: const Icon(Icons.restore),
        label: const Text('Varsayılana Dön'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}

class _HomePageGaugeSelector extends StatefulWidget {
  @override
  __HomePageGaugeSelectorState createState() => __HomePageGaugeSelectorState();
}

class __HomePageGaugeSelectorState extends State<_HomePageGaugeSelector> {
  late List<String> _selectedIds;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Provider'dan başlangıç değerlerini al
    final config = context.watch<ConfigurationProvider>().appConfig;
    _selectedIds = List.from(config.homePageGaugeIds); // Kopyasını oluştur
  }

  void _saveHomePageGauges() {
    final provider = context.read<ConfigurationProvider>();
    final currentConfig = provider.appConfig;
    final newConfig = AppConfig(
      gaugeConfigs: currentConfig.gaugeConfigs,
      machineRollAnalogIndex: currentConfig.machineRollAnalogIndex,
      machinePitchAnalogIndex: currentConfig.machinePitchAnalogIndex,
      towerRollAnalogIndex: currentConfig.towerRollAnalogIndex,
      towerPitchAnalogIndex: currentConfig.towerPitchAnalogIndex,
      homePageGaugeIds: _selectedIds, // Yeni seçilen ID'leri kullan
    );
    provider.updateAppConfig(newConfig);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Anasayfa göstergeleri kaydedildi.'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allGauges = context.read<ConfigurationProvider>().appConfig.gaugeConfigs.entries.toList();
    allGauges.sort((a, b) => a.value.label.compareTo(b.value.label)); // Alfabetik sırala

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Anasayfa Gösterge Seçimi', style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return _buildDropdown(
                  'Gösterge ${index + 1}',
                  _selectedIds[index],
                  allGauges,
                  (val) => setState(() => _selectedIds[index] = val!),
                );
              },
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(onPressed: _saveHomePageGauges, child: const Text('Kaydet')),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<MapEntry<String, GaugeConfig>> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
      items: items.map((entry) => DropdownMenuItem(
        value: entry.key,
        child: Text(entry.value.label, overflow: TextOverflow.ellipsis),
      )).toList(),
      onChanged: onChanged,
    );
  }
}

class _InclinationSourceEditor extends StatefulWidget {
  @override
  __InclinationSourceEditorState createState() => __InclinationSourceEditorState();
}

class __InclinationSourceEditorState extends State<_InclinationSourceEditor> {
  late int _machineRollIndex;
  late int _machinePitchIndex;
  late int _towerRollIndex;
  late int _towerPitchIndex;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final config = context.watch<ConfigurationProvider>().appConfig;
    _machineRollIndex = config.machineRollAnalogIndex;
    _machinePitchIndex = config.machinePitchAnalogIndex;
    _towerRollIndex = config.towerRollAnalogIndex;
    _towerPitchIndex = config.towerPitchAnalogIndex;
  }

  void _saveInclinationSources() {
    final provider = context.read<ConfigurationProvider>();
    final currentConfig = provider.appConfig;
    final newConfig = AppConfig(
      gaugeConfigs: currentConfig.gaugeConfigs,
      machineRollAnalogIndex: _machineRollIndex,
      machinePitchAnalogIndex: _machinePitchIndex,
      towerRollAnalogIndex: _towerRollIndex,
      towerPitchAnalogIndex: _towerPitchIndex,
      homePageGaugeIds: currentConfig.homePageGaugeIds,
    );
    provider.updateAppConfig(newConfig);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Eğim kaynakları kaydedildi.'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Eğim Sensör Kaynakları', style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            Row(
              children: [
                Expanded(child: _buildDropdown('Makina Roll', _machineRollIndex, (val) => setState(() => _machineRollIndex = val!))),
                const SizedBox(width: 8),
                Expanded(child: _buildDropdown('Makina Pitch', _machinePitchIndex, (val) => setState(() => _machinePitchIndex = val!))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildDropdown('Kule Roll', _towerRollIndex, (val) => setState(() => _towerRollIndex = val!))),
                const SizedBox(width: 8),
                Expanded(child: _buildDropdown('Kule Pitch', _towerPitchIndex, (val) => setState(() => _towerPitchIndex = val!))),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(onPressed: _saveInclinationSources, child: const Text('Kaydet')),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, int value, ValueChanged<int?> onChanged) {
    return DropdownButtonFormField<int>(
      value: value,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
      items: List.generate(16, (index) => DropdownMenuItem(
        value: index,
        child: Text('Analog ${index + 1}'),
      )),
      onChanged: onChanged,
    );
  }
}


// Her bir gösterge ayarını düzenlemek için kullanılan özel Card widget'ı
class _ConfigEditorCard extends StatefulWidget {
  final GaugeConfig config;

  const _ConfigEditorCard({super.key, required this.config});

  @override
  State<_ConfigEditorCard> createState() => _ConfigEditorCardState();
}

// lib/ui/tabs/config_tab.dart dosyasının içindeki state sınıfı

class _ConfigEditorCardState extends State<_ConfigEditorCard> {
  // 1. Birim için Controller'ı kaldırıp, seçili değeri tutacak bir String ekliyoruz.
  late final TextEditingController _labelController;
  late String _selectedUnit; // <-- DEĞİŞTİ
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  late final TextEditingController _warningController; // YENİ
  late final TextEditingController _criticalController;

  // 2. Dropdown içinde gösterilecek birimlerin listesini tanımlıyoruz.
  final List<String> _availableUnits = [
    'RPM', 'Bar', '°C', '%', 'V', 'A', 'N/A', '',
  ];


  @override
  void initState() {
    super.initState();
    final config = widget.config;
    _labelController = TextEditingController(text: config.label);
    _minController = TextEditingController(text: config.minValue.toString());
    _maxController = TextEditingController(text: config.maxValue.toString());
    _warningController = TextEditingController(text: config.warningValue.toString()); // YENİ
    _criticalController = TextEditingController(text: config.criticalValue.toString());
    
    // 3. Başlangıçta seçili olan birimi ayarlıyoruz.
    // Eğer kayıtlı birim listede yoksa, "N/A" seçeneğini varsayılan yapalım.
    _selectedUnit = _availableUnits.contains(config.unit) ? config.unit : 'N/A';
  }

  @override
  void dispose() {
    _labelController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _warningController.dispose(); // YENİ
    _criticalController.dispose();
    // unitController artık olmadığı için dispose'dan da kaldırıldı.
    super.dispose();
  }

  void _saveChanges() {
    final provider = context.read<ConfigurationProvider>();
    
    final newConfig = GaugeConfig(
      id: widget.config.id,
      label: _labelController.text,
      // 4. Kaydederken controller yerine state değişkenindeki değeri kullanıyoruz.
      unit: _selectedUnit, // <-- DEĞİŞTİ
      minValue: double.tryParse(_minController.text) ?? widget.config.minValue,
      maxValue: double.tryParse(_maxController.text) ?? widget.config.maxValue,
      warningValue: double.tryParse(_warningController.text) ?? widget.config.warningValue,
      criticalValue: double.tryParse(_criticalController.text) ?? widget.config.criticalValue,
      isLabelEditable: widget.config.isLabelEditable,
    );

    provider.updateGaugeConfig(newConfig);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${newConfig.label} ayarları kaydedildi.'),
        backgroundColor: Colors.green,
      ),
    );
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.config.id, style: Theme.of(context).textTheme.labelSmall),
            const Divider(),
            Row(
              children: [
                Expanded(flex: 3, child: _buildTextField(_labelController, 'Etiket', enabled: widget.config.isLabelEditable)),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Birim',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _availableUnits.map((String unit) {
                      return DropdownMenuItem<String>(
                        value: unit,
                        child: Text(unit.isEmpty ? 'Yok' : unit), // Boş string ise "Yok" yazsın
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedUnit = newValue;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTextField(_minController, 'Min. Değer', isNumber: true)),
                const SizedBox(width: 8),
                Expanded(child: _buildTextField(_maxController, 'Maks. Değer', isNumber: true)),
                const SizedBox(width: 8),
                Expanded(child: _buildTextField(_criticalController, 'Kritik Değer', isNumber: true)),
              ],
            ),
            const SizedBox(height: 12), // YENİ BOŞLUK
            Row( 
              children: [
                Expanded(child: _buildTextField(_warningController, 'Uyarı Değeri', isNumber: true)),
                const SizedBox(width: 8),
                Expanded(child: _buildTextField(_criticalController, 'Kritik Değer', isNumber: true)),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _saveChanges,
                child: const Text('Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bu yardımcı metot aynı kalıyor
  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false, bool enabled = true}) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))] : [],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}

// class _ConfigEditorCardState extends State<_ConfigEditorCard> {
//   late final TextEditingController _labelController;
//   late final TextEditingController _unitController;
//   late final TextEditingController _minController;
//   late final TextEditingController _maxController;
//   late final TextEditingController _criticalController;

//   @override
//   void initState() {
//     super.initState();
//     final config = widget.config;
//     _labelController = TextEditingController(text: config.label);
//     _unitController = TextEditingController(text: config.unit);
//     _minController = TextEditingController(text: config.minValue.toString());
//     _maxController = TextEditingController(text: config.maxValue.toString());
//     _criticalController = TextEditingController(text: config.criticalValue.toString());
//   }

//   @override
//   void dispose() {
//     _labelController.dispose();
//     _unitController.dispose();
//     _minController.dispose();
//     _maxController.dispose();
//     _criticalController.dispose();
//     super.dispose();
//   }

//   void _saveChanges() {
//     // Provider'ı sadece fonksiyon çağırmak için 'read' ile alıyoruz.
//     final provider = context.read<ConfigurationProvider>();
    
//     // Metin alanlarındaki değerleri alıp doğru tiplere dönüştürüyoruz.
//     final newConfig = GaugeConfig(
//       id: widget.config.id,
//       label: _labelController.text,
//       unit: _unitController.text,
//       minValue: double.tryParse(_minController.text) ?? widget.config.minValue,
//       maxValue: double.tryParse(_maxController.text) ?? widget.config.maxValue,
//       criticalValue: double.tryParse(_criticalController.text) ?? widget.config.criticalValue,
//       isLabelEditable: widget.config.isLabelEditable,
//     );

//     // Provider üzerinden ayarı güncelliyoruz.
//     provider.updateGaugeConfig(newConfig);

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('${newConfig.label} ayarları kaydedildi.'),
//         backgroundColor: Colors.green,
//       ),
//     );
//     // Klavyeyi kapat
//     FocusScope.of(context).unfocus();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(widget.config.id, style: Theme.of(context).textTheme.labelSmall),
//             const Divider(),
//             Row(
//               children: [
//                 Expanded(flex: 3, child: _buildTextField(_labelController, 'Etiket', enabled: widget.config.isLabelEditable)),
//                 const SizedBox(width: 8),
//                 Expanded(flex: 2, child: _buildTextField(_unitController, 'Birim')),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Expanded(child: _buildTextField(_minController, 'Min. Değer', isNumber: true)),
//                 const SizedBox(width: 8),
//                 Expanded(child: _buildTextField(_maxController, 'Maks. Değer', isNumber: true)),
//                 const SizedBox(width: 8),
//                 Expanded(child: _buildTextField(_criticalController, 'Kritik Değer', isNumber: true)),
//               ],
//             ),
//             const SizedBox(height: 16),
//             Align(
//               alignment: Alignment.centerRight,
//               child: ElevatedButton(
//                 onPressed: _saveChanges,
//                 child: const Text('Kaydet'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // TextField oluşturmak için yardımcı metot
//   Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false, bool enabled = true}) {
//     return TextField(
//       controller: controller,
//       enabled: enabled,
//       keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
//       inputFormatters: isNumber ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))] : [],
//       decoration: InputDecoration(
//         labelText: label,
//         border: const OutlineInputBorder(),
//         isDense: true,
//       ),
//     );
//   }
// }
