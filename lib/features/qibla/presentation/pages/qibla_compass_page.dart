import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../../core/localization/app_language.dart';
import '../../../../core/widgets/app_side_panel.dart';

class QiblaCompassPage extends StatefulWidget {
  const QiblaCompassPage({super.key});

  @override
  State<QiblaCompassPage> createState() => _QiblaCompassPageState();
}

class _QiblaCompassPageState extends State<QiblaCompassPage>
    with TickerProviderStateMixin {
  StreamSubscription<MagnetometerEvent>? _magnetometerSub;
  StreamSubscription<AccelerometerEvent>? _accelerometerSub;
  Timer? _uiTimer;

  double _smoothedHeading = 0;
  double _qiblaBearing = 0;

  final ValueNotifier<double> _headingNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<bool> _isAlignedNotifier = ValueNotifier<bool>(false);
  String _status = '';
  AccelerometerEvent? _latestAccel;
  MagnetometerEvent? _latestMag;
  bool _isInitializing = false;
  DateTime _lastHapticAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _lastAlignedSignal = false;
  bool _hasReceivedSensorData = false;
  String _baseReadyText = '';
  bool _lastAlignedPaint = false;
  double _lastPaintedHeading = 0;
  bool _needsPermission = false;

  late AnimationController _pulseController;
  late AnimationController _glowController;

  static const _kaabaLatitude = 21.4225;
  static const _kaabaLongitude = 39.8262;
  static const _fallbackLatitude = 41.0082;
  static const _fallbackLongitude = 28.9784;
  static const _lowPassAlpha = 0.18;
  static const _minTiltForAccuracy = 3.0;
  static const _uiTickInterval = Duration(milliseconds: 8);
  static const _headingUpdateThresholdDeg = 0.5;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _status = '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_initCompass(requestPermission: false));
        _startUiTimer();
      }
    });
  }

  void _startUiTimer() {
    _uiTimer?.cancel();
    _uiTimer = Timer.periodic(_uiTickInterval, (_) {
      if (!mounted) return;
      _tickUi();
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _pulseController.dispose();
    _glowController.dispose();
    _stopSensors();
    _headingNotifier.dispose();
    _isAlignedNotifier.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    _uiTimer?.cancel();
    _uiTimer = null;
    _stopSensors();
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    if (!_isInitializing && !_hasReceivedSensorData && !_needsPermission) {
      unawaited(_initCompass(requestPermission: false));
    }
    if (_uiTimer == null && !_needsPermission) {
      _startUiTimer();
    }
  }

  void _stopSensors() {
    _magnetometerSub?.cancel();
    _accelerometerSub?.cancel();
    _magnetometerSub = null;
    _accelerometerSub = null;
  }

  Future<void> _initCompass({bool requestPermission = false}) async {
    if (_isInitializing) return;
    _isInitializing = true;
    final ctx = context;
    if (!ctx.mounted) {
      _isInitializing = false;
      return;
    }
    final preparingText = AppText.of(ctx, 'qiblaPreparing');
    final readyText = AppText.of(ctx, 'qiblaReadyRotate');
    try {
      _stopSensors();
      _setStatus(preparingText);
      setState(() => _needsPermission = false);

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      double latitude = _fallbackLatitude;
      double longitude = _fallbackLongitude;

      if (!serviceEnabled) {
        _setStatus('$preparingText • GPS');
      }

      if (serviceEnabled) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied && requestPermission) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          setState(() => _needsPermission = true);
          _setStatus(AppText.of(ctx, 'qiblaPermissionRequiredShort'));
          _isInitializing = false;
          return;
        }

        try {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 8),
              distanceFilter: 0,
            ),
          );
          latitude = position.latitude;
          longitude = position.longitude;
        } catch (_) {
          final last = await Geolocator.getLastKnownPosition();
          if (last != null) {
            latitude = last.latitude;
            longitude = last.longitude;
          }
        }
      }

      _qiblaBearing = _calculateBearing(
        latitude,
        longitude,
        _kaabaLatitude,
        _kaabaLongitude,
      );
      _baseReadyText = readyText;
      _setStatus(readyText);
      _accelerometerSub = accelerometerEventStream().listen((e) {
        _latestAccel = e;
      });
      _magnetometerSub = magnetometerEventStream().listen((e) {
        _latestMag = e;
      });
    } catch (_) {
      if (!mounted) return;
      _qiblaBearing = _calculateBearing(
        _fallbackLatitude,
        _fallbackLongitude,
        _kaabaLatitude,
        _kaabaLongitude,
      );
      _baseReadyText = AppText.of(context, 'qiblaReadyRotate');
      _setStatus(_baseReadyText);
    } finally {
      _isInitializing = false;
    }
  }

  void _setStatus(String status) {
    if (!mounted) return;
    if (_status == status) return;
    setState(() => _status = status);
  }

  void _tickUi() {
    final accel = _latestAccel;
    final mag = _latestMag;
    if (accel == null || mag == null) return;

    _hasReceivedSensorData = true;

    double headingRaw =
        (math.atan2(mag.x, mag.y) * 180 / math.pi + 360) % 360;
    headingRaw = (360 - headingRaw) % 360;

    final isFlat = accel.z.abs() > _minTiltForAccuracy;
    if (!isFlat) {
      _setStatus(AppText.of(context, 'qiblaKeepFlat'));
      return;
    }
    _setStatus(_baseReadyText);

    final corrected = (headingRaw + 360) % 360;
    final diff = _normalizeAngle(corrected - _smoothedHeading);
    _smoothedHeading = (_smoothedHeading + diff * _lowPassAlpha + 360) % 360;

    final delta = _angleDistance(_smoothedHeading, _qiblaBearing);
    final isAlignedNow = delta <= 5;

    if (!_lastAlignedSignal && isAlignedNow) {
      final now = DateTime.now();
      if (now.difference(_lastHapticAt).inMilliseconds >= 800) {
        HapticFeedback.lightImpact();
        _lastHapticAt = now;
      }
    }
    _lastAlignedSignal = isAlignedNow;

    final headingDelta = _angleDistance(_lastPaintedHeading, _smoothedHeading);
    final headingChanged = headingDelta >= _headingUpdateThresholdDeg;
    final alignedChanged =
        _isAlignedNotifier.value != isAlignedNow ||
        _lastAlignedPaint != isAlignedNow;

    if (mounted && (headingChanged || alignedChanged)) {
      _lastPaintedHeading = _smoothedHeading;
      _lastAlignedPaint = isAlignedNow;
      _headingNotifier.value = _smoothedHeading;
      _isAlignedNotifier.value = isAlignedNow;
    }
  }

  double _normalizeAngle(double deg) {
    while (deg > 180) {
      deg -= 360;
    }
    while (deg < -180) {
      deg += 360;
    }
    return deg;
  }

  double _calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final p1 = _degToRad(lat1);
    final p2 = _degToRad(lat2);
    final dLon = _degToRad(lon2 - lon1);
    final y = math.sin(dLon) * math.cos(p2);
    final x =
        math.cos(p1) * math.sin(p2) -
        math.sin(p1) * math.cos(p2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  double _degToRad(double degree) => degree * math.pi / 180;

  double _angleDistance(double from, double to) {
    final delta = (to - from).abs() % 360;
    return delta > 180 ? 360 - delta : delta;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Arka plan gradyanı
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [const Color(0xFF020617), const Color(0xFF0A1628)]
                      : [const Color(0xFFFBF9F5), const Color(0xFFEFF6F2)],
                ),
              ),
            ),
          ),

          // İçerik
          SafeArea(
            child: Column(
              children: [
                // AppBar
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.menu_rounded, color: scheme.onSurface),
                        onPressed: () => AppSidePanel.open(context),
                      ),
                      Expanded(
                        child: Text(
                          AppText.of(context, 'qibla'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoSerif(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                Expanded(
                  child: _needsPermission
                      ? _buildPermissionDenied(scheme)
                      : _buildCompassBody(isDark, scheme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied(ColorScheme scheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off_rounded,
                size: 40,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppText.of(context, 'qiblaPermissionHeadline'),
              style: GoogleFonts.notoSerif(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              AppText.of(context, 'qiblaLocationHint'),
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                color: scheme.onSurfaceVariant,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _initCompass(requestPermission: true),
              icon: const Icon(Icons.location_on_rounded),
              label: Text(
                AppText.of(context, 'grantLocation'),
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompassBody(bool isDark, ColorScheme scheme) {
    final size = MediaQuery.sizeOf(context);
    final compassSize = (size.width * 0.72).clamp(220.0, 340.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        children: [
          // Başlık kartı
          _buildHeaderCard(isDark, scheme).animate().fade(duration: 500.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 32),

          // Pusula
          AnimatedBuilder(
            animation: Listenable.merge([
              _headingNotifier,
              _isAlignedNotifier,
              _pulseController,
              _glowController,
            ]),
            builder: (context, _) {
              final heading = _headingNotifier.value;
              final isAligned = _isAlignedNotifier.value;
              final pulse = _pulseController.value;
              final glow = _glowController.value;

              return _buildCompass(
                heading: heading,
                isAligned: isAligned,
                pulse: pulse,
                glow: glow,
                compassSize: compassSize,
                isDark: isDark,
                scheme: scheme,
              );
            },
          ),

          const SizedBox(height: 32),

          // Durum kartı
          _buildStatusCard(isDark, scheme).animate().fade(duration: 500.ms, delay: 200.ms),

          const SizedBox(height: 16),

          // Bilgi kartları
          _buildInfoCards(isDark, scheme).animate().fade(duration: 500.ms, delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(bool isDark, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF064E3B), Color(0xFF065F46)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF064E3B).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.mosque_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppText.of(context, 'qiblaCompassTitle'),
                  style: GoogleFonts.notoSerif(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppText.of(context, 'qiblaReadyRotate'),
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    color: Color(0xFF6EE7B7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              AppText.of(context, 'labelMecca'),
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompass({
    required double heading,
    required bool isAligned,
    required double pulse,
    required double glow,
    required double compassSize,
    required bool isDark,
    required ColorScheme scheme,
  }) {
    final alignColor = isAligned ? const Color(0xFF10B981) : const Color(0xFFD97706);
    final glowRadius = isAligned ? (20 + glow * 20) : 0.0;

    return SizedBox(
      width: compassSize + 60,
      height: compassSize + 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dış glow halkası (hizalandığında)
          if (isAligned)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: compassSize + 40,
              height: compassSize + 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3 + glow * 0.2),
                    blurRadius: glowRadius,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),

          // Pusula çemberi
          Container(
            width: compassSize,
            height: compassSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              border: Border.all(
                color: isAligned
                    ? const Color(0xFF10B981).withValues(alpha: 0.6 + pulse * 0.4)
                    : scheme.outlineVariant.withValues(alpha: 0.3),
                width: isAligned ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Arka plan radyal gradyan
                  Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          alignColor.withValues(alpha: isAligned ? 0.08 : 0.04),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.7],
                      ),
                    ),
                  ),

                  // Derece çizgileri
                  for (int i = 0; i < 360; i += 10)
                    Transform.rotate(
                      angle: i * math.pi / 180,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          margin: const EdgeInsets.only(top: 10),
                          width: (i % 90 == 0) ? 3 : (i % 30 == 0) ? 2 : 1,
                          height: (i % 90 == 0) ? 16 : (i % 30 == 0) ? 10 : 6,
                          decoration: BoxDecoration(
                            color: scheme.onSurface.withValues(
                              alpha: (i % 90 == 0)
                                  ? 0.8
                                  : (i % 30 == 0)
                                  ? 0.4
                                  : 0.15,
                            ),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),

                  // Yön harfleri (dönen)
                  Transform.rotate(
                    angle: -heading * math.pi / 180,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 28,
                          left: 0,
                          right: 0,
                          child: Text(
                            'N',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 28,
                          left: 0,
                          right: 0,
                          child: Text(
                            'S',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: scheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 28,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Text(
                              'W',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: scheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 28,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Text(
                              'E',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: scheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Kıble iğnesi
                  Transform.rotate(
                    angle: (_qiblaBearing - heading) * math.pi / 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // İğne gövdesi
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            margin: EdgeInsets.only(top: compassSize * 0.08),
                            width: 6,
                            height: compassSize * 0.36,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  alignColor,
                                  alignColor.withValues(alpha: 0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                BoxShadow(
                                  color: alignColor.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Cami ikonu (üst)
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            margin: const EdgeInsets.only(top: 8),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: alignColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: alignColor.withValues(alpha: 0.5),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.mosque_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Merkez nokta
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: alignColor,
                        width: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Hizalandı etiketi
          if (isAligned)
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      AppText.of(context, 'qiblaFacingChip'),
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(bool isDark, ColorScheme scheme) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isAlignedNotifier,
      builder: (context, isAligned, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isAligned
                ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.1)
                : (isDark ? const Color(0xFF0F172A) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isAligned
                  ? const Color(0xFF10B981).withValues(alpha: 0.4)
                  : scheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isAligned
                      ? const Color(0xFF10B981).withValues(alpha: 0.2)
                      : scheme.primaryContainer.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAligned
                      ? Icons.check_circle_rounded
                      : Icons.explore_rounded,
                  color: isAligned ? const Color(0xFF10B981) : scheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAligned
                          ? AppText.of(context, 'qiblaAligned')
                          : AppText.of(context, 'qiblaCompassActive'),
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isAligned
                            ? const Color(0xFF10B981)
                            : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _status,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              ValueListenableBuilder<double>(
                valueListenable: _headingNotifier,
                builder: (context, heading, _) {
                  final delta = _angleDistance(heading, _qiblaBearing);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${delta.toStringAsFixed(0)}°',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: scheme.primary,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCards(bool isDark, ColorScheme scheme) {
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            icon: Icons.location_on_rounded,
            label: AppText.of(context, 'locationInfoLabel'),
            value: AppText.of(context, 'locationAutoMode'),
            color: const Color(0xFF3B82F6),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoCard(
            icon: Icons.navigation_rounded,
            label: AppText.of(context, 'qiblaAngle'),
            value: '${_qiblaBearing.toStringAsFixed(1)}°',
            color: const Color(0xFFD97706),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoCard(
            icon: Icons.speed_rounded,
            label: AppText.of(context, 'qiblaSensitivityShort'),
            value: AppText.of(context, 'accuracyLevelHigh'),
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
