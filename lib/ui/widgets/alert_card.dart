// YENİ WIDGET: Animasyon ve durum yönetimini kendi içinde yapan kart.

import 'package:flutter/material.dart';
enum AlertLevel { normal, warning, critical }

class AlertCard extends StatefulWidget {
  final String title;
  final AlertLevel alertLevel;

  const AlertCard({
    super.key,
    required this.title,
    required this.alertLevel,
  });

  @override
  State<AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<AlertCard> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<Color?> _colorAnimation;
  final ColorTween _colorTween = ColorTween();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _colorAnimation = _colorTween.animate(_animationController);

    // Animasyonun sürekli tekrar etmesi için listener.
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    });

    // Başlangıç durumuna göre animasyonu ayarla.
    _updateAnimationState(widget.alertLevel);
  }

  // Widget'ın aldığı parametreler (örneğin alertLevel) değiştiğinde bu metot çalışır.
  @override
  void didUpdateWidget(AlertCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.alertLevel != oldWidget.alertLevel) {
      _updateAnimationState(widget.alertLevel);
    }
  }

  void _updateAnimationState(AlertLevel level) {
    if (level == AlertLevel.warning) {
      _colorTween.begin = Colors.white;
      _colorTween.end = Colors.yellow.shade600;
      if (!_animationController.isAnimating) {
        _animationController.forward();
      }
    } else if (level == AlertLevel.critical) {
      _colorTween.begin = Colors.white;
      _colorTween.end = Colors.red.shade600;
      if (!_animationController.isAnimating) {
        _animationController.forward();
      }
    } else { // Normal durum
      if (_animationController.isAnimating) {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mevcut duruma göre renkleri ve ikonu belirle.
    Color staticColor;
    Color foregroundColor;
    IconData icon;

    switch (widget.alertLevel) {
      case AlertLevel.normal:
        staticColor = Colors.green.shade400;
        foregroundColor = Colors.white;
        icon = Icons.check_circle;
        break;
      case AlertLevel.warning:
        staticColor = Colors.yellow.shade600;
        foregroundColor = Colors.black87;
        icon = Icons.warning_amber_rounded;
        break;
      case AlertLevel.critical:
        staticColor = Colors.red.shade700;
        foregroundColor = Colors.white;
        icon = Icons.error;
        break;
    }

    Widget cardContent = Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: foregroundColor,
              fontSize: 28,
            ),
          ),
          const Spacer(),
          Icon(icon, color: foregroundColor, size: 96),
          const Spacer(),
        ],
      ),
    );

    // Animasyon gerekiyorsa AnimatedBuilder, gerekmiyorsa sabit Card döndür.
    if (widget.alertLevel != AlertLevel.normal) {
      return AnimatedBuilder(
        animation: _colorAnimation,
        builder: (context, child) {
          return Card(
            color: _colorAnimation.value,
            margin: EdgeInsets.zero,
            child: child,
          );
        },
        child: cardContent,
      );
    } else {
      return Card(
        color: staticColor,
        margin: EdgeInsets.zero,
        child: cardContent,
      );
    }
  }
}
