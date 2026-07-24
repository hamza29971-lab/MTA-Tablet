import 'package:flutter/material.dart';

class AppDialogs {
  /// Sabit ve büyük boyutlu standart uyarı mesajı popup'ı
  static void showStandardDialog(
    BuildContext context, {
    required String title,
    required String message,
    required Color color,
    required IconData icon,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 700),
          child: Text(
            message,
            style: const TextStyle(fontSize: 32),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (onConfirm != null) onConfirm();
            },
            child: const Text(
              'Tamam',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Onay gerektiren (İptal ve Onay butonlu) uyarı mesajı popup'ı
  static void showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required Color color,
    required IconData icon,
    required VoidCallback onConfirm,
    String confirmText = 'Tamam',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 700),
          child: Text(
            message,
            style: const TextStyle(fontSize: 32),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal', style: TextStyle(fontSize: 24, color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(confirmText, style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// İçeriği özelleştirilebilir (Örn: Dropdown içeren) büyük boyutlu popup
  static void showCustomDialog(
    BuildContext context, {
    required String title,
    required Widget content,
    required Color color,
    required IconData icon,
    required List<Widget> actions,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 700),
          child: content,
        ),
        actions: actions,
      ),
    );
  }
}
