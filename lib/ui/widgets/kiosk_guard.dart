// lib/ui/widgets/kiosk_guard.dart
//
// Uygulamanin etrafina gecirilen kiosk kabugu. Uc isi vardir:
//
//   1. Ekran kenarlarindan yapilan kaydirmalari ve geri tusunu yakalayip
//      parola ekranini acar.
//   2. Cihaz sahipligi yoksa uygulamayi kullanilamaz hale getirir
//      (bu uygulama YALNIZCA device-owner modunda calisir).
//   3. Kilit gorevi herhangi bir sebeple dusmusse geri baslatir.
//
// Parolalarin kendisi burada DEGILDIR; dogrulama Android tarafinda
// (MainActivity.kt) SHA-256 ozetleriyle yapilir.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vtm_tablet/services/kiosk_service.dart';

/// Kenardan kaydirmanin cikis denemesi sayilmasi icin gereken mesafe (piksel).
const double _kEdgeSwipeThreshold = 36.0;

/// Kenar seritlerinin kalinligi. Dar tutuluyor ki uygulamanin kendi
/// kaydirmalari (sayfa gecisleri, listeler) etkilenmesin.
const double _kEdgeStripSize = 18.0;

/// Gizli ikinci yol: sol ust koseye 3 saniye icinde 5 dokunus.
const int _kCornerTapCount = 5;
const Duration _kCornerTapWindow = Duration(seconds: 3);

/// Art arda yanlis parolada kilitlenme.
const int _kMaxAttempts = 5;
const Duration _kLockoutDuration = Duration(seconds: 30);

enum _Edge { left, right, top, bottom }

class KioskGuard extends StatefulWidget {
  const KioskGuard({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  final Widget child;

  /// Geri tusu geldiginde once acik bir diyalog var mi diye bakilir.
  final GlobalKey<NavigatorState> navigatorKey;

  /// Parola ekranini acan kabuk. Kabuk kuruluyken doludur.
  static VoidCallback? _promptOpener;

  /// Parola ekranini uygulamanin herhangi bir yerinden acar.
  ///
  /// Geri tusu iki farkli yoldan gelebiliyor: Android tarafindaki
  /// MainActivity.onBackPressed ve Flutter tarafindaki PopScope. Ikisi de
  /// buraya baglanir; ekran zaten aciksa ikinci cagri bir sey yapmaz.
  static void requestExitPrompt() => _promptOpener?.call();

  @override
  State<KioskGuard> createState() => _KioskGuardState();
}

class _KioskGuardState extends State<KioskGuard> with WidgetsBindingObserver {
  KioskStatus? _status;
  bool _promptOpen = false;
  bool _justReleased = false;
  bool _developerOverride = false;

  /// Cihaz sahibiyiz ama kilit gorevi DUSMUS. Bu durumda Samsung'un ekran
  /// ustundeki "..." tutamagi geri gelir ve kullanici bolunmus ekrana gecip
  /// uygulamadan cikabilir. Sessizce gecilmemesi gereken tek durum budur.
  bool _lockDown = false;

  Timer? _watchdog;
  Offset? _dragStart;
  final List<DateTime> _cornerTaps = <DateTime>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    KioskService.setExitAttemptHandler(_onExitAttempt);
    KioskGuard._promptOpener = _openPrompt;
    _refreshStatus();

    // Kilit gorevi bir sekilde dusmusse (sistem diyalogu, cokme, guncelleme)
    // sessizce geri baslatilir. Kilit dustugu SURECE kullanici uygulamadan
    // cikabilir, o yuzden kontrol siktir.
    _watchdog = Timer.periodic(const Duration(seconds: 15), (_) async {
      final status = await KioskService.status();
      if (!mounted || !status.available) return;

      if (status.deviceOwner && !status.locked && !status.released) {
        final healed = await KioskService.reassert();
        if (!mounted) return;
        setState(() {
          _status = healed;
          // Yeniden kilitleme denemesi de tutmadiysa durum gizlenmez.
          _lockDown =
              healed.deviceOwner && !healed.locked && !healed.released;
        });
        return;
      }

      setState(() {
        _status = status;
        _lockDown = false;
      });
    });
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    KioskService.clearExitAttemptHandler();
    if (identical(KioskGuard._promptOpener, _openPrompt)) {
      KioskGuard._promptOpener = null;
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatus();
    }
  }

  Future<void> _refreshStatus() async {
    final status = await KioskService.status();
    if (!mounted) return;
    // Kanal gecici olarak cevap veremediyse eldeki durum korunur: tek bir
    // basarisiz cagri yuzunden sahadaki tablette "koruma yok" ekrani acilmamali.
    if (!status.available && _status != null) return;
    setState(() {
      _status = status;
      if (status.released) _justReleased = true;
    });
  }

  // --------------------------------------------------------------- cikis yollari

  /// Geri tusu ve geri jesti Android tarafindan buraya yonlendirilir.
  void _onExitAttempt(String source) {
    if (_promptOpen) {
      setState(() => _promptOpen = false);
      return;
    }
    // Uygulamanin kendi diyalogu aciksa geri tusu once onu kapatsin.
    final navigator = widget.navigatorKey.currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return;
    }
    _openPrompt();
  }

  void _openPrompt() {
    if (_promptOpen || _justReleased) return;
    setState(() => _promptOpen = true);
  }

  void _onEdgePointerDown(PointerDownEvent event) => _dragStart = event.position;

  void _onEdgePointerMove(PointerMoveEvent event, _Edge edge) {
    final start = _dragStart;
    if (start == null || _promptOpen) return;

    final delta = event.position - start;
    final horizontal = delta.dx.abs() > delta.dy.abs();
    final triggered = switch (edge) {
      _Edge.left => horizontal && delta.dx > _kEdgeSwipeThreshold,
      _Edge.right => horizontal && delta.dx < -_kEdgeSwipeThreshold,
      _Edge.top => !horizontal && delta.dy > _kEdgeSwipeThreshold,
      _Edge.bottom => !horizontal && delta.dy < -_kEdgeSwipeThreshold,
    };

    if (triggered) {
      _dragStart = null;
      _openPrompt();
    }
  }

  void _onCornerTap(PointerDownEvent event) {
    final now = DateTime.now();
    _cornerTaps
      ..add(now)
      ..removeWhere((t) => now.difference(t) > _kCornerTapWindow);
    if (_cornerTaps.length >= _kCornerTapCount) {
      _cornerTaps.clear();
      _openPrompt();
    }
  }

  Future<void> _onUnlockResult(KioskUnlockResult result) async {
    switch (result) {
      case KioskUnlockResult.settings:
        // Ayarlar uygulamasi Android tarafinda kilitli olarak aciliyor.
        setState(() => _promptOpen = false);
      case KioskUnlockResult.released:
        setState(() {
          _promptOpen = false;
          _justReleased = true;
        });
        await _refreshStatus();
      case KioskUnlockResult.releaseFailed:
      case KioskUnlockResult.invalid:
      case KioskUnlockResult.unavailable:
        break;
    }
  }

  // --------------------------------------------------------------------- arayuz

  @override
  Widget build(BuildContext context) {
    // Kiosk yalnizca Android tabletlerde anlamli; diger platformlarda
    // uygulama oldugu gibi calisir.
    if (!KioskService.isSupported) return widget.child;

    final status = _status;
    final showBlockScreen = status != null &&
        status.available &&
        !status.deviceOwner &&
        !_justReleased &&
        !_developerOverride;

    return Directionality(
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,

          // Gizli kose: sol ust, 3 saniyede 5 dokunus.
          Positioned(
            left: 0,
            top: 0,
            width: 96,
            height: 96,
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: _onCornerTap,
              child: const SizedBox.expand(),
            ),
          ),

          // Dort kenar. Listener kullaniliyor (GestureDetector DEGIL): boylece
          // dokunuslar yalnizca IZLENIR, alttaki arayuzden calinmaz.
          _edgeStrip(_Edge.left),
          _edgeStrip(_Edge.right),
          _edgeStrip(_Edge.top),
          _edgeStrip(_Edge.bottom),

          // Kilit dustuyse sessiz kalinmaz: bu durumda bolunmus ekran tutamagi
          // geri gelir ve tablet artik guvenli degildir. IgnorePointer ile
          // sarili, altindaki kenar seridini kapatmaz.
          if (_lockDown && !_justReleased)
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: IgnorePointer(child: _LockDownBanner()),
            ),

          if (_justReleased)
            _blocking(_ReleasedScreen(onGoHome: KioskService.goHome)),

          if (showBlockScreen)
            _blocking(
              _NoProtectionScreen(
                onRetry: _refreshStatus,
                onDeveloperOverride: kDebugMode
                    ? () => setState(() => _developerOverride = true)
                    : null,
              ),
            ),

          if (_promptOpen)
            _blocking(
              _ExitPasswordOverlay(
                onCancel: () => setState(() => _promptOpen = false),
                onResult: _onUnlockResult,
              ),
            ),
        ],
      ),
    );
  }

  /// Uzerine bindigi arayuze HICBIR dokunusun gecmemesini garantiler.
  /// Yalnizca boyayan bir katman (Material) dokunusu yutmaz; parola ekrani
  /// aciktan altindaki butonlara basilabilseydi kilit anlamsiz olurdu.
  Widget _blocking(Widget child) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: child,
      ),
    );
  }

  Widget _edgeStrip(_Edge edge) {
    final listener = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onEdgePointerDown,
      onPointerMove: (event) => _onEdgePointerMove(event, edge),
      onPointerUp: (_) => _dragStart = null,
      onPointerCancel: (_) => _dragStart = null,
      child: const SizedBox.expand(),
    );

    switch (edge) {
      case _Edge.left:
        return Positioned(
            left: 0, top: 0, bottom: 0, width: _kEdgeStripSize, child: listener);
      case _Edge.right:
        return Positioned(
            right: 0, top: 0, bottom: 0, width: _kEdgeStripSize, child: listener);
      case _Edge.top:
        return Positioned(
            left: 0, right: 0, top: 0, height: _kEdgeStripSize, child: listener);
      case _Edge.bottom:
        return Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _kEdgeStripSize,
            child: listener);
    }
  }
}

// ------------------------------------------------------------------ parola ekrani

class _ExitPasswordOverlay extends StatefulWidget {
  const _ExitPasswordOverlay({required this.onCancel, required this.onResult});

  final VoidCallback onCancel;
  final Future<void> Function(KioskUnlockResult result) onResult;

  @override
  State<_ExitPasswordOverlay> createState() => _ExitPasswordOverlayState();
}

class _ExitPasswordOverlayState extends State<_ExitPasswordOverlay> {
  static const int _passwordLength = 6;

  String _entered = '';
  String? _error;
  bool _busy = false;
  int _attempts = 0;
  DateTime? _lockedUntil;
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  bool get _isLockedOut =>
      _lockedUntil != null && DateTime.now().isBefore(_lockedUntil!);

  int get _remainingLockSeconds =>
      _lockedUntil == null ? 0 : _lockedUntil!.difference(DateTime.now()).inSeconds + 1;

  void _append(String digit) {
    if (_busy || _isLockedOut || _entered.length >= _passwordLength) return;
    setState(() {
      _entered += digit;
      _error = null;
    });
    if (_entered.length == _passwordLength) _submit();
  }

  void _backspace() {
    if (_busy || _entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  void _clear() {
    if (_busy) return;
    setState(() {
      _entered = '';
      _error = null;
    });
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final result = await KioskService.unlock(_entered);
    if (!mounted) return;

    if (result == KioskUnlockResult.invalid ||
        result == KioskUnlockResult.unavailable ||
        result == KioskUnlockResult.releaseFailed) {
      _attempts++;
      setState(() {
        _busy = false;
        _entered = '';
        if (result == KioskUnlockResult.releaseFailed) {
          _error = 'Cihaz sahipligi birakilamadi. Kurulum scriptini kullanin.';
        } else if (result == KioskUnlockResult.unavailable) {
          _error = 'Kiosk katmanina ulasilamadi.';
        } else if (_attempts >= _kMaxAttempts) {
          _lockedUntil = DateTime.now().add(_kLockoutDuration);
          _attempts = 0;
          _error = 'Cok fazla yanlis deneme.';
          _startTicker();
        } else {
          _error = 'Parola hatali. (${_kMaxAttempts - _attempts} deneme kaldi)';
        }
      });
      return;
    }

    await widget.onResult(result);
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!_isLockedOut) {
        timer.cancel();
        setState(() {
          _lockedUntil = null;
          _error = null;
        });
      } else {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.82),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 460,
            margin: const EdgeInsets.symmetric(vertical: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, color: Color(0xFF046464), size: 32),
                    SizedBox(width: 12),
                    Text(
                      'YETKILI CIKISI',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF046464),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Uygulamadan cikmak icin yetkili parolasini girin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                _dots(),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  child: Center(
                    child: _busy
                        ? const CircularProgressIndicator(strokeWidth: 3)
                        : Text(
                            _isLockedOut
                                ? 'Kilitli. $_remainingLockSeconds saniye bekleyin.'
                                : (_error ?? ''),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                _keypad(),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _busy ? null : widget.onCancel,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'VAZGEC - UYGULAMAYA DON',
                      style: TextStyle(fontSize: 18, color: Colors.black54),
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

  Widget _dots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_passwordLength, (index) {
        final filled = index < _entered.length;
        return Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? const Color(0xFF046464) : Colors.transparent,
            border: Border.all(color: const Color(0xFF046464), width: 2),
          ),
        );
      }),
    );
  }

  Widget _keypad() {
    final rows = <List<String>>[
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', '<'],
    ];

    return Column(
      children: rows.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) {
            return Padding(
              padding: const EdgeInsets.all(6),
              child: SizedBox(
                width: 108,
                height: 60,
                child: ElevatedButton(
                  onPressed: (_busy || _isLockedOut)
                      ? null
                      : () {
                          if (key == 'C') {
                            _clear();
                          } else if (key == '<') {
                            _backspace();
                          } else {
                            _append(key);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: key == 'C' || key == '<'
                        ? Colors.grey.shade200
                        : Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                  ),
                  child: key == '<'
                      ? const Icon(Icons.backspace_outlined, size: 24)
                      : Text(
                          key,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

/// Kilit gorevi dustugunde ekranin tepesinde duran ince serit.
class _LockDownBanner extends StatelessWidget {
  const _LockDownBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFB00020),
      child: SizedBox(
        height: 34,
        child: Center(
          child: Text(
            'KIOSK KILIDI DUSTU - YENIDEN KURULUYOR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------- koruma yok / serbest ekrani

class _NoProtectionScreen extends StatelessWidget {
  const _NoProtectionScreen({required this.onRetry, this.onDeveloperOverride});

  final Future<void> Function() onRetry;
  final VoidCallback? onDeveloperOverride;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFB00020),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.gpp_bad, color: Colors.white, size: 72),
              const SizedBox(height: 16),
              const Text(
                'KIOSK KORUMASI YOK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Bu uygulama yalnizca device-owner (kiosk) modunda calisir.\n'
                'Tablette cihaz sahipligi atanmamis.\n\n'
                'Yapilmasi gereken: tableti bilgisayara baglayip\n'
                'mta-kurulum klasorundeki mta-tablet-kur.bat dosyasini calistirin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 20, height: 1.5),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => onRetry(),
                icon: const Icon(Icons.refresh),
                label: const Text('YENIDEN DENE', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFB00020),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                ),
              ),
              if (onDeveloperOverride != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onDeveloperOverride,
                  child: const Text(
                    'Gelistirici modunda devam et (yalnizca debug)',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReleasedScreen extends StatelessWidget {
  const _ReleasedScreen({required this.onGoHome});

  final Future<void> Function() onGoHome;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1B5E20),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_open, color: Colors.white, size: 72),
              const SizedBox(height: 16),
              const Text(
                'KIOSK KORUMASI KALDIRILDI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cihaz sahipligi birakildi.\n'
                'Artik uygulamayi silebilir, tableti fabrika ayarlarina\n'
                'dondurebilir ve Ayarlar disina cikabilirsiniz.\n\n'
                'Tableti tekrar kiosk moduna almak icin\n'
                'mta-tablet-kur.bat bastan calistirilmalidir.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 20, height: 1.5),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => onGoHome(),
                icon: const Icon(Icons.home),
                label: const Text('ANA EKRANA DON',
                    style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1B5E20),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
