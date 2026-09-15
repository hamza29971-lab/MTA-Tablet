import 'package:flutter/material.dart';

class KeyboardScrollableWrapper extends StatelessWidget {
  final Widget child;

  const KeyboardScrollableWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Scaffold artık resizeToAvoidBottomInset: false olduğu için ekran küçülmeyecek.
    // Ancak klavyenin kaydırmayı tetiklemesi için, ScrollView'ın "görüş alanını" manuel daraltacağız.
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          // Görüş alanını klavye boyutu kadar KÜÇÜLTÜYORUZ ki kaydırma tetiklensin!
          height: constraints.maxHeight - bottomInset,
          child: SingleChildScrollView(
            // Ekstra padding'e gerek kalmadı çünkü görüş alanı daraldı
            child: ConstrainedBox(
              constraints: BoxConstraints(
                // İçeriği her zaman ekranın TAM VE ORİJİNAL yüksekliğine kilitliyoruz (Sabit Ekran)
                minHeight: constraints.maxHeight,
                maxHeight: constraints.maxHeight,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
