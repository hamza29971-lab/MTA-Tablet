import 'package:flutter/material.dart';

class IndicatorCard extends StatelessWidget {
  final String label;
  final bool isActive;

  const IndicatorCard({
    super.key,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final Color lightColor = isActive ? Colors.redAccent.shade400 : Colors.grey.shade700;
    final Color glowColor = isActive ? Colors.redAccent.shade400.withOpacity(0.7) : Colors.transparent;

    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        // DEĞİŞİKLİK: Column yerine Stack kullanıyoruz.
        child: Stack(
          // Stack'in tüm alanı kaplamasını sağlar
          alignment: Alignment.center, 
          children: [
            // 1. Katman: Etiket (Üste hizalanmış)
            Align(
              alignment: Alignment.topCenter,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            
            // 2. Katman: Işık (Tam merkeze yerleştirilmiş)
            // Center widget'ı sayesinde bu Container her zaman dikey ve yatayda ortalanır.
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: lightColor,
                  border: Border.all(color: Colors.black26, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor,
                      blurRadius: 15.0,
                      spreadRadius: 3.0,
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
