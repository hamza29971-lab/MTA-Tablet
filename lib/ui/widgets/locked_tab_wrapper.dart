import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';

class LockedTabWrapper extends StatelessWidget {
  final Widget child;

  const LockedTabWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isLocked = context.watch<DataProvider>().isSystemLocked;

    return Stack(
      children: [
        AbsorbPointer(
          absorbing: isLocked,
          child: Opacity(
            opacity: isLocked ? 0.3 : 1.0,
            child: child,
          ),
        ),
        if (isLocked)
          Positioned.fill(
            child: Align(
              alignment: const Alignment(0.0, -0.8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Lütfen ekranı açmak için önce "Rapor Gönder" sekmesinden formu doldurup gönderin.',
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
