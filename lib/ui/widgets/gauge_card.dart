// import 'package:flutter/material.dart';
// import 'package:syncfusion_flutter_gauges/gauges.dart';

// // Bu enum, projenizde genel bir yerde tanımlı değilse burada kalabilir.
// enum PopUpAlertLevel { normal, warning, critical }

// class GaugeCard extends StatefulWidget {
//   final String label;
//   final String unit;
//   final double value;
//   final double minValue;
//   final double maxValue;
//   final double warningValue;
//   final double criticalValue;

//   const GaugeCard({
//     super.key,
//     required this.label,
//     required this.unit,
//     required this.value,
//     required this.minValue,
//     required this.maxValue,
//     required this.warningValue,
//     required this.criticalValue,
//   });

//   @override
//   State<GaugeCard> createState() => _GaugeCardState();
// }

// class _GaugeCardState extends State<GaugeCard> {
//   // YENİ: Pop-up'ları ve özel mesajlarını yöneten Map.
//   // Artık _popupEnabledLabels Set'ine ihtiyacımız yok.
  // static const Map<String, Map<PopUpAlertLevel, String>> _popupMessages = {
  //   // Anahtar: Gösterge etiketinin küçük harfli hali
  //   'hidrolik sıcaklık': {
  //     PopUpAlertLevel.warning: 'Hidrolik yağ sıcaklığı yükseldi. Sistemi aşırı zorlamaktan kaçının.',
  //     PopUpAlertLevel.critical: 'KRİTİK: Hidrolik yağ aşırı ısındı! Ciddi hasar riski. Sistemi soğuması için durdurun.',
  //   },
  //   // 'servis pompası basıncı': {
  //   //   PopUpAlertLevel.warning:
  //   //       'Hidrolik yağ sıcaklığı yükseldi. Sistemi aşırı zorlamaktan kaçının.',
  //   //   PopUpAlertLevel.critical:
  //   //       'KRİTİK: Hidrolik yağ aşırı ısındı! Ciddi hasar riski. Sistemi soğuması için durdurun.',
  //   // },
  //   'hidrolik seviye': {
  //     PopUpAlertLevel.warning:
  //         'Hidrolik yağ seviyesi azalıyor. En kısa sürede tamamlayın.',
  //     PopUpAlertLevel.critical:
  //         'KRİTİK: Hidrolik yağ seviyesi tehlikeli derecede düşük! Pompa hasarı riski. Derhal takviye yapın.',
  //   },
  //   'motor hararet': {
  //     PopUpAlertLevel.warning:
  //         'Motor soğutma suyu sıcaklığı artıyor. Motoru rölantide çalıştırarak soğutun.',
  //     PopUpAlertLevel.critical:
  //         'KRİTİK: Motor hararet yaptı! Kalıcı hasarı önlemek için motoru hemen durdurun.',
  //   },
  // };

//   bool _isDialogShowing = false;

//   @override
//   void didUpdateWidget(GaugeCard oldWidget) {
//     super.didUpdateWidget(oldWidget);

//     final lowerCaseLabel = widget.label.toLowerCase();

//     // Sadece _popupMessages haritasında tanımlı olan gauge'lar için devam et.
//     if (!_popupMessages.containsKey(lowerCaseLabel)) {
//       return;
//     }

//     final currentLevel = _getAlertLevel(widget.value);
//     final previousLevel = _getAlertLevel(oldWidget.value);

//     if (currentLevel.index > previousLevel.index && !_isDialogShowing) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (mounted) {
//           _showAlertDialog(currentLevel);
//         }
//       });
//     }
//   }

//   PopUpAlertLevel _getAlertLevel(double value) {
//     if (value >= widget.criticalValue) {
//       return PopUpAlertLevel.critical;
//     } else if (value >= widget.warningValue) {
//       return PopUpAlertLevel.warning;
//     } else {
//       return PopUpAlertLevel.normal;
//     }
//   }

//   void _showAlertDialog(PopUpAlertLevel level) {
//     setState(() {
//       _isDialogShowing = true;
//     });

//     // DEĞİŞİKLİK: Mesajı haritadan alıyoruz.
//     final lowerCaseLabel = widget.label.toLowerCase();
//     final customMessage =
//         _popupMessages[lowerCaseLabel]?[level] ??
//         'Bilinmeyen bir uyarı oluştu.';
//     final finalMessage =
//         '$customMessage\n\nMevcut Değer: ${widget.value.toStringAsFixed(1)} ${widget.unit}';

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Row(
//             children: [
//               Icon(
//                 level == PopUpAlertLevel.critical ? Icons.error : Icons.warning,
//                 color: level == PopUpAlertLevel.critical
//                     ? Colors.red
//                     : Colors.orange,
//                 size: 32,
//               ),
//               const SizedBox(width: 10),
//               Text(
//                 level == PopUpAlertLevel.critical ? 'KRİTİK ALARM' : 'UYARI',
//               ),
//             ],
//           ),
//           content: Text(
//             finalMessage, // Özel mesajı burada kullanıyoruz
//             style: const TextStyle(fontSize: 24),
//           ),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('Tamam'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     ).then((_) {
//       if (mounted) {
//         setState(() {
//           _isDialogShowing = false;
//         });
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     // build metodu, önceki görsel güncellemelerin hepsini içerir ve
//     // stateful widget'a uyumlu hale getirilmiştir. (widget. ile erişim)
//     const Map<String, double> secondaryAxisFactors = {
//       'ana vinç çekme kuvveti': 15.0,
//       'rotasyon devir': 10.0,
//       'su basıncı': 5.0,
//     };
//     const Map<String, String> secondaryAxisUnits = {
//       'ana vinç çekme kuvveti': 'TON',
//       'rotasyon devir': '100 M/DAK',
//       'su basıncı': '100 L/DAK',
//     };
//     const Map<String, double> primaryAxisIntervals = {
//       'ana vinç çekme kuvveti': 50.0,
//       'su basıncı': 50.0,
//       'rotasyon devir': 200.0,
//     };

//     final lowerCaseLabel = widget.label.toLowerCase();
//     final conversionFactor = secondaryAxisFactors[lowerCaseLabel];
//     final secondaryUnit = secondaryAxisUnits[lowerCaseLabel];
//     final primaryInterval = primaryAxisIntervals[lowerCaseLabel];
//     final bool isCritical =
//         _getAlertLevel(widget.value) == PopUpAlertLevel.critical;

//     final List<RadialAxis> axes = [];

//     if (conversionFactor != null) {
//       final double minSecondary = widget.minValue * conversionFactor;
//       final double maxSecondary = widget.maxValue * conversionFactor;
//       final double? secondaryInterval = primaryInterval != null
//           ? primaryInterval * conversionFactor
//           : null;

//       final primaryAxis = RadialAxis(
//         minimum: widget.minValue,
//         maximum: widget.maxValue,
//         interval: primaryInterval,
//         showLastLabel: true,
//         startAngle: 180,
//         endAngle: 0,
//         showLabels: true,
//         showTicks: true,
//         labelOffset: -30,
//         tickOffset: -5,
//         axisLineStyle: const AxisLineStyle(
//           thickness: 0.15,
//           thicknessUnit: GaugeSizeUnit.factor,
//         ),
//         pointers: <GaugePointer>[
//           NeedlePointer(
//             value: widget.value,
//             enableAnimation: true,
//             animationDuration: 400,
//             needleStartWidth: 1,
//             needleEndWidth: 5,
//             needleLength: 0.8,
//             knobStyle: const KnobStyle(knobRadius: 0.08),
//           ),
//         ],
//         ranges: <GaugeRange>[
//           GaugeRange(
//             startValue: widget.minValue,
//             endValue: widget.warningValue,
//             color: Colors.green,
//             startWidth: 0.15,
//             endWidth: 0.15,
//             sizeUnit: GaugeSizeUnit.factor,
//           ),
//           GaugeRange(
//             startValue: widget.warningValue,
//             endValue: widget.criticalValue,
//             color: Colors.orange,
//             startWidth: 0.15,
//             endWidth: 0.15,
//             sizeUnit: GaugeSizeUnit.factor,
//           ),
//           GaugeRange(
//             startValue: widget.criticalValue,
//             endValue: widget.maxValue,
//             color: Colors.red,
//             startWidth: 0.15,
//             endWidth: 0.15,
//             sizeUnit: GaugeSizeUnit.factor,
//           ),
//         ],
//         annotations: <GaugeAnnotation>[
//           GaugeAnnotation(
//             widget: Text(
//               "${widget.value.toStringAsFixed(1)} ${widget.unit.toUpperCase()}",
//               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 48,
//               ),
//             ),
//             angle: 90,
//             positionFactor: 0.65,
//           ),
//         ],
//       );
//       final secondaryAxis = RadialAxis(
//         minimum: minSecondary,
//         maximum: maxSecondary,
//         interval: secondaryInterval,
//         showLastLabel: true,
//         startAngle: 180,
//         endAngle: 0,
//         showLabels: true,
//         showTicks: true,
//         axisLineStyle: const AxisLineStyle(thickness: 0),
//         labelOffset: 25,
//         tickOffset: 10,
//         axisLabelStyle: GaugeTextStyle(
//           fontSize: 14,
//           color: Colors.black,
//           fontWeight: FontWeight.bold,
//         ),
//         annotations: <GaugeAnnotation>[
//           if (secondaryUnit != null)
//             GaugeAnnotation(
//               widget: Text(
//                 secondaryUnit,
//                 style: const TextStyle(
//                   fontSize: 24,
//                   color: Colors.black,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               angle: 90,
//               positionFactor: 0.95,
//             ),
//         ],
//       );
//       axes.add(primaryAxis);
//       axes.add(secondaryAxis);
//     } else {
//       final primaryAxis = RadialAxis(
//         minimum: widget.minValue,
//         maximum: widget.maxValue,
//         interval: primaryInterval,
//         showLastLabel: true,
//         startAngle: 180,
//         endAngle: 0,
//         showLabels: true,
//         showTicks: true,
//         labelOffset: 15,
//         tickOffset: 2,
//         axisLineStyle: const AxisLineStyle(
//           thickness: 0.15,
//           thicknessUnit: GaugeSizeUnit.factor,
//         ),
//         pointers: <GaugePointer>[
//           NeedlePointer(
//             value: widget.value,
//             enableAnimation: true,
//             animationDuration: 400,
//             needleStartWidth: 1,
//             needleEndWidth: 5,
//             needleLength: 0.8,
//             knobStyle: const KnobStyle(knobRadius: 0.08),
//           ),
//         ],
//         ranges: <GaugeRange>[
//           GaugeRange(
//             startValue: widget.minValue,
//             endValue: widget.warningValue,
//             color: Colors.green,
//             startWidth: 0.15,
//             endWidth: 0.15,
//             sizeUnit: GaugeSizeUnit.factor,
//           ),
//           GaugeRange(
//             startValue: widget.warningValue,
//             endValue: widget.criticalValue,
//             color: Colors.orange,
//             startWidth: 0.15,
//             endWidth: 0.15,
//             sizeUnit: GaugeSizeUnit.factor,
//           ),
//           GaugeRange(
//             startValue: widget.criticalValue,
//             endValue: widget.maxValue,
//             color: Colors.red,
//             startWidth: 0.15,
//             endWidth: 0.15,
//             sizeUnit: GaugeSizeUnit.factor,
//           ),
//         ],
//         annotations: <GaugeAnnotation>[
//           GaugeAnnotation(
//             widget: Text(
//               "${widget.value.toStringAsFixed(1)} ${widget.unit.toUpperCase()}",
//               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 48,
//               ),
//             ),
//             angle: 90,
//             positionFactor: 0.65,
//           ),
//         ],
//       );
//       axes.add(primaryAxis);
//     }

//     return Card(
//       elevation: isCritical ? 8.0 : 4.0,
//       shadowColor: isCritical ? Colors.red.shade300 : null,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//         side: BorderSide(
//           color: isCritical ? Colors.red.shade500 : Colors.transparent,
//           width: 12,
//         ),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           children: [
//             Expanded(flex: 8, child: SfRadialGauge(axes: axes)),
//             Flexible(
//               flex: 1,
//               child: FittedBox(
//                 fit: BoxFit.contain,
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       widget.label,
//                       textAlign: TextAlign.center,
//                       style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 32,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class GaugeCard extends StatelessWidget {
  final String label;
  final String unit;
  final double value;
  final double minValue;
  final double maxValue;
  final double warningValue;
  final double criticalValue;

  const GaugeCard({
    super.key,
    required this.label,
    required this.unit,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.warningValue,
    required this.criticalValue,
  });

  String _turkishUpperCase(String text) {
    return text.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // Göstergeye özel konfigürasyonlar
    const Map<String, double> secondaryAxisFactors = {
      'ana vinç çekme kuvveti': 15.0,
      'rotasyon devir': 10.0,
    };
    const Map<String, String> secondaryAxisUnits = {
      'ana vinç çekme kuvveti': 'TON',
      'rotasyon devir': '100 M/DAK',
    };
    const Map<String, double> primaryAxisIntervals = {
      'ana vinç çekme kuvveti': 50.0,
      'rotasyon devir': 200.0,
      'rotasyon tork': 50.0,
      'çamur su basıncı': 50.0,
      'rotasyon i̇lerleme': 100.0,
      'rotasyon ilerleme': 100.0,
      'su litre': 5000.0,
      'morset yağlama': 10.0,
      'wireline vinç': 50.0,
      'motor devri': 500.0,
      'motor hararet': 50.0,
      'motor yağ basıncı': 20.0,
      'motor yağ sıcaklığı': 20.0,
      'yakıt seviyesi 1': 20.0,
      'yakıt seviyesi 2': 20.0,
      'mazot sıcaklığı': 50.0,
      'askı basıncı': 50.0,
      'takım ağırlığı askı': 50.0,
      'baskı basıncı': 50.0,
      'servis pompa basıncı': 50.0,
      'servis & çamur pompa basıncı': 50.0,
      'ana pompa basıncı': 50.0,
      'spt vuruş': 10.0,
    };

    final lowerCaseLabel = label.toLowerCase();
    final conversionFactor = secondaryAxisFactors[lowerCaseLabel];
    final secondaryUnit = secondaryAxisUnits[lowerCaseLabel];
    final primaryInterval = primaryAxisIntervals[lowerCaseLabel];
    
    // Kritik durum kontrolü basitleştirildi
    final bool isCritical = value >= criticalValue;
    
    final Color color1 = Colors.green;
    final Color color2 = Colors.orange;
    final Color color3 = Colors.red;
    
    final double range1End = warningValue;
    final double range2Start = warningValue;
    final double range2End = criticalValue;
    final double range3Start = criticalValue;
    
    final List<RadialAxis> axes = [];

    if (conversionFactor != null) {
      final double minSecondary = minValue * conversionFactor;
      final double maxSecondary = maxValue * conversionFactor;
      final double? secondaryInterval = primaryInterval != null ? primaryInterval * conversionFactor : null;

      final primaryAxis = RadialAxis(
        minimum: minValue,
        maximum: maxValue,
        interval: primaryInterval,
        showLastLabel: true,
        startAngle: 180,
        endAngle: 0,
        showLabels: true,
        showTicks: true,
        labelOffset: -45,
        tickOffset: -5,
        axisLineStyle: const AxisLineStyle(
          thickness: 0.15,
          thicknessUnit: GaugeSizeUnit.factor,
        ),
        pointers: <GaugePointer>[
          NeedlePointer(
            value: value,
            enableAnimation: true,
            animationDuration: 400,
            needleStartWidth: 1,
            needleEndWidth: 5,
            needleLength: 0.8,
            knobStyle: const KnobStyle(knobRadius: 0.08),
          ),
        ],
        ranges: <GaugeRange>[
          GaugeRange(
            startValue: minValue,
            endValue: range1End,
            color: color1,
            startWidth: 0.15,
            endWidth: 0.15,
            sizeUnit: GaugeSizeUnit.factor,
          ),
          GaugeRange(
            startValue: range2Start,
            endValue: range2End,
            color: color2,
            startWidth: 0.15,
            endWidth: 0.15,
            sizeUnit: GaugeSizeUnit.factor,
          ),
          GaugeRange(
            startValue: range3Start,
            endValue: maxValue,
            color: color3,
            startWidth: 0.15,
            endWidth: 0.15,
            sizeUnit: GaugeSizeUnit.factor,
          ),
        ],
        annotations: <GaugeAnnotation>[
          GaugeAnnotation(
            widget: Text(
              "${value.toStringAsFixed(1)} ${_turkishUpperCase(unit)}",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 48,
              ),
            ),
            angle: 90,
            positionFactor: 0.65,
          ),
        ],
      );
      final secondaryAxis = RadialAxis(
        minimum: minSecondary,
        maximum: maxSecondary,
        interval: secondaryInterval,
        showLastLabel: true,
        startAngle: 180,
        endAngle: 0,
        showLabels: true,
        showTicks: true,
        axisLineStyle: const AxisLineStyle(thickness: 0),
        labelOffset: 25,
        tickOffset: 10,
        axisLabelStyle: GaugeTextStyle(
          fontSize: 14,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        annotations: <GaugeAnnotation>[
          if (secondaryUnit != null)
            GaugeAnnotation(
              widget: Text(
                secondaryUnit,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              angle: 90,
              positionFactor: 0.95,
            ),
        ],
      );
      axes.add(primaryAxis);
      axes.add(secondaryAxis);
    } else {
      final primaryAxis = RadialAxis(
        minimum: minValue,
        maximum: maxValue,
        interval: primaryInterval,
        onLabelCreated: (AxisLabelCreatedArgs args) {
          if (lowerCaseLabel == 'ana pompa basıncı' && (args.text == '50' || args.text == '150')) {
            args.text = '';
          }
        },
        showLastLabel: true,
        startAngle: 180,
        endAngle: 0,
        showLabels: true,
        showTicks: true,
        labelOffset: 15,
        tickOffset: 2,
        axisLineStyle: const AxisLineStyle(
          thickness: 0.15,
          thicknessUnit: GaugeSizeUnit.factor,
        ),
        pointers: <GaugePointer>[
          NeedlePointer(
            value: value,
            enableAnimation: true,
            animationDuration: 400,
            needleStartWidth: 1,
            needleEndWidth: 5,
            needleLength: 0.8,
            knobStyle: const KnobStyle(knobRadius: 0.08),
          ),
        ],
        ranges: <GaugeRange>[
          GaugeRange(
            startValue: minValue,
            endValue: range1End,
            color: color1,
            startWidth: 0.15,
            endWidth: 0.15,
            sizeUnit: GaugeSizeUnit.factor,
          ),
          GaugeRange(
            startValue: range2Start,
            endValue: range2End,
            color: color2,
            startWidth: 0.15,
            endWidth: 0.15,
            sizeUnit: GaugeSizeUnit.factor,
          ),
          GaugeRange(
            startValue: range3Start,
            endValue: maxValue,
            color: color3,
            startWidth: 0.15,
            endWidth: 0.15,
            sizeUnit: GaugeSizeUnit.factor,
          ),
        ],
        annotations: <GaugeAnnotation>[
          GaugeAnnotation(
            widget: Text(
              "${value.toStringAsFixed(1)} ${_turkishUpperCase(unit)}",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 48,
              ),
            ),
            angle: 90,
            positionFactor: 0.65,
          ),
        ],
      );
      axes.add(primaryAxis);
    }

    return Card(
      elevation: isCritical ? 8.0 : 4.0,
      shadowColor: isCritical ? Colors.red.shade300 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCritical ? Colors.red.shade500 : Colors.transparent,
          width: 12,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(flex: 8, child: SfRadialGauge(axes: axes)),
            Flexible(
              flex: 1,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _turkishUpperCase(label),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
