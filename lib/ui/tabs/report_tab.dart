// // // // lib/ui/tabs/report_tab.dart
// // // import 'package:flutter/material.dart';
// // // import 'package:provider/provider.dart';
// // // import '../../models/report_data.dart';
// // // import '../../providers/report_provider.dart';

// // // class ReportTab extends StatefulWidget {
// // //   const ReportTab({super.key});

// // //   @override
// // //   State<ReportTab> createState() => _ReportTabState();
// // // }

// // // class _ReportTabState extends State<ReportTab> {
// // //   final _formKey = GlobalKey<FormState>();
// // //   final _operatorNameController = TextEditingController();
// // //   final _operatorNumberController = TextEditingController();
// // //   final _teamNameController = TextEditingController();
// // //   final _faultTextController = TextEditingController();

// // //   @override
// // //   void dispose() {
// // //     _operatorNameController.dispose();
// // //     _operatorNumberController.dispose();
// // //     _teamNameController.dispose();
// // //     _faultTextController.dispose();
// // //     super.dispose();
// // //   }

// // //   void _submitReport() {
// // //     // Formun geçerli olup olmadığını kontrol et
// // //     if (_formKey.currentState?.validate() ?? false) {
// // //       final reportData = ReportData(
// // //         operatorName: _operatorNameController.text,
// // //         operatorNumber: _operatorNumberController.text,
// // //         teamName: _teamNameController.text,
// // //         faultText: _faultTextController.text,
// // //       );
// // //       // Provider üzerinden raporu gönder
// // //       context.read<ReportProvider>().sendReport(reportData);
// // //     }
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     // ReportProvider'daki durum değişikliklerini dinle
// // //     final reportProvider = context.watch<ReportProvider>();

// // //     return Center(
// // //       child: SingleChildScrollView(
// // //         padding: const EdgeInsets.all(32.0),
// // //         child: ConstrainedBox(
// // //           constraints: const BoxConstraints(maxWidth: 600),
// // //           child: Form(
// // //             key: _formKey,
// // //             child: Column(
// // //               crossAxisAlignment: CrossAxisAlignment.stretch,
// // //               children: [
// // //                 Text('Arıza Raporu Oluştur', style: Theme.of(context).textTheme.headlineMedium),
// // //                 const SizedBox(height: 24),
// // //                 _buildTextField(_operatorNameController, 'Operatör İsmi'),
// // //                 const SizedBox(height: 16),
// // //                 _buildTextField(_operatorNumberController, 'Operatör Numarası', isNumber: true),
// // //                 const SizedBox(height: 16),
// // //                 _buildTextField(_teamNameController, 'Takım İsmi'),
// // //                 const SizedBox(height: 16),
// // //                 _buildTextField(_faultTextController, 'Arıza Açıklaması', maxLines: 5),
// // //                 const SizedBox(height: 24),
                
// // //                 // Duruma göre buton veya sonuç göstergesi
// // //                 if (reportProvider.status == ReportStatus.initial)
// // //                   ElevatedButton(
// // //                     onPressed: _submitReport,
// // //                     style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
// // //                     child: const Text('Raporu Gönder'),
// // //                   )
// // //                 else
// // //                   _buildStatusIndicator(reportProvider),
// // //               ],
// // //             ),
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, bool isNumber = false}) {
// // //     return TextFormField(
// // //       controller: controller,
// // //       maxLines: maxLines,
// // //       keyboardType: isNumber ? TextInputType.number : TextInputType.text,
// // //       decoration: InputDecoration(
// // //         labelText: label,
// // //         border: const OutlineInputBorder(),
// // //       ),
// // //       validator: (value) {
// // //         if (value == null || value.isEmpty) {
// // //           return 'Bu alan boş bırakılamaz';
// // //         }
// // //         return null;
// // //       },
// // //     );
// // //   }

// // //   Widget _buildStatusIndicator(ReportProvider provider) {
// // //     IconData icon;
// // //     Color color;
// // //     String message = provider.ackMessage;

// // //     switch (provider.status) {
// // //       case ReportStatus.sending:
// // //         return const Center(child: CircularProgressIndicator());
      
// // //       case ReportStatus.success:
// // //         // ✅ DEĞİŞİKLİK BURADA
// // //         // Gelen mesajın içeriğini kontrol ederek renk ve ikonu belirliyoruz.
// // //         if (message.toLowerCase().contains("kaydedildi")) {
// // //           icon = Icons.warning_amber_rounded; // Uyarı ikonu
// // //           color = Colors.amber.shade700; // Sarı/Amber tonu
// // //         } else {
// // //           icon = Icons.check_circle; // Başarı ikonu
// // //           color = Colors.green; // Yeşil renk
// // //         }
// // //         break;
      
// // //       case ReportStatus.error:
// // //       case ReportStatus.timeout:
// // //         icon = Icons.error;
// // //         color = Colors.red;
// // //         break;
      
// // //       default:
// // //         return const SizedBox.shrink();
// // //     }

// // //     return Column(
// // //       children: [
// // //         Container(
// // //           padding: const EdgeInsets.all(16),
// // //           decoration: BoxDecoration(
// // //             color: color.withOpacity(0.1),
// // //             borderRadius: BorderRadius.circular(8),
// // //             border: Border.all(color: color),
// // //           ),
// // //           child: Row(
// // //             mainAxisAlignment: MainAxisAlignment.center,
// // //             children: [
// // //               Icon(icon, color: color, size: 30),
// // //               const SizedBox(width: 16),
// // //               Expanded(child: Text(message, style: TextStyle(fontSize: 18, color: color))),
// // //             ],
// // //           ),
// // //         ),
// // //         const SizedBox(height: 16),
// // //         TextButton(
// // //           onPressed: () => provider.resetStatus(),
// // //           child: const Text('Yeni Rapor Oluştur'),
// // //         )
// // //       ],
// // //     );
// // //   }
// // // }

// // // lib/ui/tabs/report_tab.dart
// // import 'package:flutter/material.dart';
// // import 'package:provider/provider.dart';
// // import '../../models/report_data.dart';
// // import '../../providers/report_provider.dart';

// // class ReportTab extends StatefulWidget {
// //   const ReportTab({super.key});

// //   @override
// //   State<ReportTab> createState() => _ReportTabState();
// // }

// // class _ReportTabState extends State<ReportTab> {
// //   final _formKey = GlobalKey<FormState>();
// //   final _operatorNameController = TextEditingController();
// //   final _operatorNumberController = TextEditingController();
// //   // DEĞİŞİKLİK: Takım ismi için controller kaldırıldı.
// //   // final _teamNameController = TextEditingController(); 
// //   final _faultTextController = TextEditingController();

// //   // YENİ: Dropdown'dan seçilen takım ismini tutacak state değişkeni
// //   String? _selectedTeam;

// //   // YENİ: Dropdown listesi için seçenekler
// //   final List<String> _teamOptions = ['AW', 'BW', 'NQ', 'HQ', 'PQ'];

// //   @override
// //   void dispose() {
// //     _operatorNameController.dispose();
// //     _operatorNumberController.dispose();
// //     // DEĞİŞİKLİK: Artık kullanılmayan controller için dispose kaldırıldı.
// //     // _teamNameController.dispose();
// //     _faultTextController.dispose();
// //     super.dispose();
// //   }

// //   void _submitReport() {
// //     // Formun geçerli olup olmadığını kontrol et
// //     if (_formKey.currentState?.validate() ?? false) {
// //       final reportData = ReportData(
// //         operatorName: _operatorNameController.text,
// //         operatorNumber: _operatorNumberController.text,
// //         // DEĞİŞİKLİK: Değer artık state değişkeninden alınıyor.
// //         // Null olamayacağından emin olmak için '!' kullanıyoruz çünkü validator kontrol ediyor.
// //         teamName: _selectedTeam!,
// //         faultText: _faultTextController.text,
// //       );
// //       // Provider üzerinden raporu gönder
// //       context.read<ReportProvider>().sendReport(reportData);
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     // ReportProvider'daki durum değişikliklerini dinle
// //     final reportProvider = context.watch<ReportProvider>();

// //     return Center(
// //       child: SingleChildScrollView(
// //         padding: const EdgeInsets.all(32.0),
// //         child: ConstrainedBox(
// //           constraints: const BoxConstraints(maxWidth: 600),
// //           child: Form(
// //             key: _formKey,
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.stretch,
// //               children: [
// //                 Text('Arıza Raporu Oluştur', style: Theme.of(context).textTheme.headlineMedium),
// //                 const SizedBox(height: 24),
// //                 _buildTextField(_operatorNameController, 'Operatör İsmi'),
// //                 const SizedBox(height: 16),
// //                 _buildTextField(_operatorNumberController, 'Operatör Numarası', isNumber: true),
// //                 const SizedBox(height: 16),

// //                 // DEĞİŞİKLİK: TextFormField yerine DropdownButtonFormField kullanılıyor.
// //                 DropdownButtonFormField<String>(
// //                   value: _selectedTeam,
// //                   decoration: const InputDecoration(
// //                     labelText: 'Takım İsmi',
// //                     border: OutlineInputBorder(),
// //                   ),
// //                   hint: const Text('Bir takım seçin'),
// //                   items: _teamOptions.map((String team) {
// //                     return DropdownMenuItem<String>(
// //                       value: team,
// //                       child: Text(team),
// //                     );
// //                   }).toList(),
// //                   onChanged: (String? newValue) {
// //                     setState(() {
// //                       _selectedTeam = newValue;
// //                     });
// //                   },
// //                   validator: (value) {
// //                     if (value == null || value.isEmpty) {
// //                       return 'Lütfen bir takım seçin';
// //                     }
// //                     return null;
// //                   },
// //                 ),
                
// //                 const SizedBox(height: 16),
// //                 _buildTextField(_faultTextController, 'Arıza Açıklaması', maxLines: 5),
// //                 const SizedBox(height: 24),
                
// //                 // Duruma göre buton veya sonuç göstergesi
// //                 if (reportProvider.status == ReportStatus.initial)
// //                   ElevatedButton(
// //                     onPressed: _submitReport,
// //                     style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
// //                     child: const Text('Raporu Gönder'),
// //                   )
// //                 else
// //                   _buildStatusIndicator(reportProvider),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, bool isNumber = false}) {
// //     return TextFormField(
// //       controller: controller,
// //       maxLines: maxLines,
// //       keyboardType: isNumber ? TextInputType.number : TextInputType.text,
// //       decoration: InputDecoration(
// //         labelText: label,
// //         border: const OutlineInputBorder(),
// //       ),
// //       validator: (value) {
// //         if (value == null || value.isEmpty) {
// //           return 'Bu alan boş bırakılamaz';
// //         }
// //         return null;
// //       },
// //     );
// //   }

// //   Widget _buildStatusIndicator(ReportProvider provider) {
// //     IconData icon;
// //     Color color;
// //     String message = provider.ackMessage;

// //     switch (provider.status) {
// //       case ReportStatus.sending:
// //         return const Center(child: CircularProgressIndicator());
      
// //       case ReportStatus.success:
// //         if (message.toLowerCase().contains("kaydedildi")) {
// //           icon = Icons.warning_amber_rounded;
// //           color = Colors.amber.shade700;
// //         } else {
// //           icon = Icons.check_circle;
// //           color = Colors.green;
// //         }
// //         break;
      
// //       case ReportStatus.error:
// //       case ReportStatus.timeout:
// //         icon = Icons.error;
// //         color = Colors.red;
// //         break;
      
// //       default:
// //         return const SizedBox.shrink();
// //     }

// //     return Column(
// //       children: [
// //         Container(
// //           padding: const EdgeInsets.all(16),
// //           decoration: BoxDecoration(
// //             color: color.withOpacity(0.1),
// //             borderRadius: BorderRadius.circular(8),
// //             border: Border.all(color: color),
// //           ),
// //           child: Row(
// //             mainAxisAlignment: MainAxisAlignment.center,
// //             children: [
// //               Icon(icon, color: color, size: 30),
// //               const SizedBox(width: 16),
// //               Expanded(child: Text(message, style: TextStyle(fontSize: 18, color: color))),
// //             ],
// //           ),
// //         ),
// //         const SizedBox(height: 16),
// //         TextButton(
// //           onPressed: () => provider.resetStatus(),
// //           child: const Text('Yeni Rapor Oluştur'),
// //         )
// //       ],
// //     );
// //   }
// // }

// // lib/ui/tabs/report_tab.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../models/report_data.dart';
// import '../../providers/report_provider.dart';

// class ReportTab extends StatefulWidget {
//   const ReportTab({super.key});

//   @override
//   State<ReportTab> createState() => _ReportTabState();
// }

// class _ReportTabState extends State<ReportTab> {
//   final _formKey = GlobalKey<FormState>();
//   final _operatorNameController = TextEditingController();
//   final _operatorNumberController = TextEditingController();
//   final _faultTextController = TextEditingController();
//   final _faultMeterController = TextEditingController(); 

//   String? _selectedTeam;
//   final List<String> _teamOptions = ['AW 1.5M', 'AW 3M', 'BW 1.5M', 'BW 3M', 'NQ 1.5M', 'NQ 3M', 'HQ 1.5M', 'HQ 3M', 'PQ 1.5M', 'PQ 3M'];

//   @override
//   void dispose() {
//     _operatorNameController.dispose();
//     _operatorNumberController.dispose();
//     _faultTextController.dispose();
//     _faultMeterController.dispose();
//     super.dispose();
//   }

//     void _clearFormAndResetStatus() {
//     // Tüm metin alanlarını temizle
//     _operatorNameController.clear();
//     _operatorNumberController.clear();
//     _faultTextController.clear();
//     _faultMeterController.clear();
    
//     // Dropdown seçimini sıfırla
//     setState(() {
//       _selectedTeam = null;
//     });
    
//     // Provider'daki durumu başlangıç haline getir
//     // context.read kullanmak burada daha uygundur çünkü sadece bir eylem tetikliyoruz.
//     context.read<ReportProvider>().resetStatus();
//   }

//   void _submitReport() {
//     if (_formKey.currentState?.validate() ?? false) {
//       final reportData = ReportData(
//         operatorName: _operatorNameController.text,
//         operatorNumber: _operatorNumberController.text,
//         teamName: _selectedTeam!,
//         faultText: _faultTextController.text,
//         // Metin kutusundan gelen string, double'a çevrilerek gönderiliyor.
//         faultMeter: double.parse(_faultMeterController.text),
//       );
//       context.read<ReportProvider>().sendReport(reportData);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final reportProvider = context.watch<ReportProvider>();

//     return Center(
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(32.0),
//         child: ConstrainedBox(
//           constraints: const BoxConstraints(maxWidth: 600),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 Text('Rapor Oluştur', style: Theme.of(context).textTheme.headlineMedium),
//                 const SizedBox(height: 24),
//                 _buildTextField(_operatorNameController, 'Operatör İsmi'),
//                 const SizedBox(height: 16),
//                 _buildTextField(_operatorNumberController, 'Operatör Numarası', isNumber: true),
//                 const SizedBox(height: 16),
//                 DropdownButtonFormField<String>(
//                   value: _selectedTeam,
//                   decoration: const InputDecoration(
//                     labelText: 'Takım İsmi',
//                     border: OutlineInputBorder(),
//                   ),
//                   hint: const Text('Bir takım seçin'),
//                   items: _teamOptions.map((String team) {
//                     return DropdownMenuItem<String>(
//                       value: team,
//                       child: Text(team),
//                     );
//                   }).toList(),
//                   onChanged: (String? newValue) {
//                     setState(() {
//                       _selectedTeam = newValue;
//                     });
//                   },
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Lütfen bir takım seçin';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 _buildTextField(_faultTextController, 'Arıza Açıklaması (Varsa)', maxLines: 5),
//                 const SizedBox(height: 16),
                
//                 TextFormField(
//                   controller: _faultMeterController,
//                   keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                   decoration: const InputDecoration(
//                     labelText: 'Metraj',
//                     border: OutlineInputBorder(),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Bu alan boş bırakılamaz';
//                     }
//                     // Girilen değerin geçerli bir ondalıklı sayı olup olmadığını kontrol et.
//                     if (double.tryParse(value) == null) {
//                       return 'Lütfen geçerli bir sayı girin (örn: 12.5)';
//                     }
//                     return null;
//                   },
//                 ),
                
//                 const SizedBox(height: 24),
//                 if (reportProvider.status == ReportStatus.initial)
//                   ElevatedButton(
//                     onPressed: _submitReport,
//                     style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
//                     child: const Text('Raporu Gönder'),
//                   )
//                 else
//                   _buildStatusIndicator(reportProvider),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, bool isNumber = false}) {
//     return TextFormField(
//       controller: controller,
//       maxLines: maxLines,
//       keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
//       decoration: InputDecoration(
//         labelText: label,
//         border: const OutlineInputBorder(),
//       ),
//       validator: (value) {
//         if (value == null || value.isEmpty) {
//           return 'Bu alan boş bırakılamaz';
//         }
//         return null;
//       },
//     );
//   }

//   Widget _buildStatusIndicator(ReportProvider provider) {
//     IconData icon;
//     Color color;
//     String message = provider.ackMessage;

//     switch (provider.status) {
//       case ReportStatus.sending:
//         return const Center(child: CircularProgressIndicator());
      
//       case ReportStatus.success:
//         if (message.toLowerCase().contains("kaydedildi")) {
//           icon = Icons.warning_amber_rounded;
//           color = Colors.amber.shade700;
//         } else {
//           icon = Icons.check_circle;
//           color = Colors.green;
//         }
//         break;
      
//       case ReportStatus.error:
//       case ReportStatus.timeout:
//         icon = Icons.error;
//         color = Colors.red;
//         break;
      
//       default:
//         return const SizedBox.shrink();
//     }

//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: color),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(icon, color: color, size: 30),
//               const SizedBox(width: 16),
//               Expanded(child: Text(message, style: TextStyle(fontSize: 18, color: color))),
//             ],
//           ),
//         ),
//         const SizedBox(height: 16),
//         TextButton(
//           onPressed: _clearFormAndResetStatus,
//           child: const Text('Yeni Rapor Oluştur'),
//         )
//       ],
//     );
//   }
// }
// lib/ui/tabs/report_tab.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/report_data.dart';
import '../../providers/report_provider.dart';
import '../../providers/data_provider.dart';

class ReportTab extends StatefulWidget {
  const ReportTab({super.key});

  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab> {
  final _formKey = GlobalKey<FormState>();
  final _operatorNameController = TextEditingController();
  final _kuyuNameController = TextEditingController();
  final _operatorNumberController = TextEditingController();
  final _faultTextController = TextEditingController();
  final _faultMeterController = TextEditingController(); 

  String? _selectedTeam;
  final List<String> _teamOptions = ['AW 1.5M', 'AW 3M', 'BW 1.5M', 'BW 3M', 'NQ 1.5M', 'NQ 3M', 'HQ 1.5M', 'HQ 3M', 'PQ 1.5M', 'PQ 3M'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dp = context.read<DataProvider>();
      if (dp.operatorName != null && dp.operatorName!.isNotEmpty) {
        _operatorNameController.text = dp.operatorName!;
      }
      if (dp.wellNo != null && dp.wellNo!.isNotEmpty) {
        _kuyuNameController.text = dp.wellNo!;
      }
      if (dp.registrationNo != null && dp.registrationNo!.isNotEmpty) {
        _operatorNumberController.text = dp.registrationNo!;
      }
    });
    // Raporun başarı durumunu dinleyerek operatör bilgilerini güncelle
    context.read<ReportProvider>().addListener(_onReportStatusChanged);
  }

  void _onReportStatusChanged() {
    final provider = context.read<ReportProvider>();
    if (provider.status == ReportStatus.success) {
      final operatorName = _operatorNameController.text;
      final kuyuName = _kuyuNameController.text;
      final operatorNumber = _operatorNumberController.text;
      
      // Ana sisteme operatör bilgilerini kaydet (testlerin kilidini açar)
      context.read<DataProvider>().setOperatorInfo(operatorName, operatorNumber, kuyuName);
    }
  }

  @override
  void dispose() {
    context.read<ReportProvider>().removeListener(_onReportStatusChanged);
    _operatorNameController.dispose();
    _kuyuNameController.dispose();
    _operatorNumberController.dispose();
    _faultTextController.dispose();
    _faultMeterController.dispose();
    super.dispose();
  }

  void _clearFormAndResetStatus() {
    // Tüm metin alanlarını temizle
    _operatorNameController.clear();
    _kuyuNameController.clear();
    _operatorNumberController.clear();
    _faultTextController.clear();
    _faultMeterController.clear();
    
    // Dropdown seçimini sıfırla
    setState(() {
      _selectedTeam = null;
    });
    
    // Provider'daki durumu başlangıç haline getir
    context.read<ReportProvider>().resetStatus();

    // Sadece formu temizliyoruz, Kilit durumunu (isSystemLocked) burada DEĞİŞTİRMİYORUZ.
    // Kilit durumu sadece rapor başarıyla gönderildiğinde toggle edilir.
  }

  void _submitReport() {
    if (_formKey.currentState?.validate() ?? false) {
      final operatorName = _operatorNameController.text;
      // Kullanıcı ne yazarsa yazsın parantez içine al (sunucu ayracı)
      final kuyuName = '(${_kuyuNameController.text})';
      final operatorNumber = _operatorNumberController.text;
      final teamName = _selectedTeam!;

      // fault_text'i JSON formatında sar (sunucu formatıyla uyumluluk için)
      final faultTextJson = jsonEncode({
        'TestTipi': 'Arıza Raporu',
        'Aciklama': _faultTextController.text,
      });

      final reportData = ReportData(
        operatorName: operatorName,
        kuyuName: kuyuName,
        operatorNumber: operatorNumber,
        teamName: teamName,
        faultText: faultTextJson,
        faultMeter: double.parse(_faultMeterController.text),
      );
      context.read<ReportProvider>().sendReport(reportData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── HOŞGELDİNİZ HEADER ────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF024040), // koyu teal
                  Color(0xFF046464), // AppBar rengi
                  Color(0xFF067878), // açık teal
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
            child: Column(
              children: [
                // 3 Logo yan yana
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // DTS Logo
                    Container(
                      width: 160,
                      height: 85,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Center(
                        child: Image.asset(
                          'assets/logos/dts_logo.jpg',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    // DSİ Logo - beyaz arka planlı yuvarlak
                    Container(
                      width: 160,
                      height: 85,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Center(
                        child: Image.asset(
                          'assets/logos/dsi_logo.jpg',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    // Jeoteknik / Sondaj Logo
                    Container(
                      width: 160,
                      height: 85,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Center(
                        child: Image.asset(
                          'assets/logos/sondaj_logo.jpg',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Ana başlık
                const Text(
                  'DSİ TEMEL SONDAJ TAKİP PROGRAMI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                // Hoşgeldiniz
                const Text(
                  'Hoş Geldiniz',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),

          // ─── RAPOR FORMU ────────────────────────────────────────────────
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTextField(_operatorNameController, 'Operatör İsmi'),
                      const SizedBox(height: 16),
                      _buildTextField(_kuyuNameController, 'Kuyu Adı'),
                      const SizedBox(height: 16),
                      _buildTextField(_operatorNumberController, 'Operatör Numarası', isNumber: true),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedTeam,
                        decoration: const InputDecoration(
                          labelText: 'Takım İsmi',
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text('Bir takım seçin'),
                        items: _teamOptions.map((String team) {
                          return DropdownMenuItem<String>(
                            value: team,
                            child: Text(team),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedTeam = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen bir takım seçin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // ✅ DEĞİŞİKLİK: 'required: false' parametresi eklendi ve etiket güncellendi.
                      _buildTextField(_faultTextController, 'Arıza Açıklaması (Varsa)', maxLines: 5, required: false),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _faultMeterController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Metraj',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bu alan boş bırakılamaz';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Lütfen geçerli bir sayı girin (örn: 12.5)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      if (reportProvider.status == ReportStatus.initial)
                        ElevatedButton(
                          onPressed: _submitReport,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF046464),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'RAPORU GÖNDER',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                          ),
                        )
                      else
                        _buildStatusIndicator(reportProvider),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ✅ DEĞİŞİKLİK: 'required' parametresi eklendi ve validator güncellendi.
  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, bool isNumber = false, bool required = true}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        // Sadece 'required' true ise boş olup olmadığını kontrol et.
        if (required && (value == null || value.isEmpty)) {
          return 'Bu alan boş bırakılamaz';
        }
        return null;
      },
    );
  }

  Widget _buildStatusIndicator(ReportProvider provider) {
    IconData icon;
    Color color;
    String message = provider.ackMessage;

    switch (provider.status) {
      case ReportStatus.sending:
        return const Center(child: CircularProgressIndicator());
      
      case ReportStatus.success:
        if (message.toLowerCase().contains("kaydedildi")) {
          icon = Icons.warning_amber_rounded;
          color = Colors.amber.shade700;
        } else {
          icon = Icons.check_circle;
          color = Colors.green;
        }
        break;
      
      case ReportStatus.error:
      case ReportStatus.timeout:
        icon = Icons.error;
        color = Colors.red;
        break;
      
      default:
        return const SizedBox.shrink();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(width: 16),
              Expanded(child: Text(message, style: TextStyle(fontSize: 18, color: color))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _clearFormAndResetStatus,
          child: const Text('Yeni Rapor Oluştur'),
        )
      ],
    );
  }
}

