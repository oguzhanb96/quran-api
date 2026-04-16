import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _QiblaCompassPageState extends State<QiblaCompassPage> {
  StreamSubscription<MagnetometerEvent>? _magnetometerSub;
  StreamSubscription<AccelerometerEvent>? _accelerometerSub;
  Timer? _uiTimer;

  double _smoothedHeading = 0;
  double _qiblaBearing = 0;
  
  final ValueNotifier<double> _headingNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<bool> _isAlignedNotifier = ValueNotifier<bool>(false);
  String _status = '';
  final double _offset = 0;
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
    _status = 'Hazırlanıyor...';
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
    _stopSensors();
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
        
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          setState(() => _needsPermission = true);
          _setStatus('Konum izni gerekli');
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
      
      _qiblaBearing = _calculateBearing(latitude, longitude, _kaabaLatitude, _kaabaLongitude);
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
      _qiblaBearing = _calculateBearing(_fallbackLatitude, _fallbackLongitude, _kaabaLatitude, _kaabaLongitude);
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

    double headingRaw = (math.atan2(mag.x, mag.y) * 180 / math.pi + 360) % 360;
    
    headingRaw = (360 - headingRaw) % 360;

    final isFlat = accel.z.abs() > _minTiltForAccuracy;
    
    if (!isFlat) {
      _setStatus(AppText.of(context, 'qiblaKeepFlat'));
      return;
    }
    _setStatus(_baseReadyText);

    final corrected = (headingRaw + _offset + 360) % 360;
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
    final alignedChanged = _isAlignedNotifier.value != isAlignedNow || _lastAlignedPaint != isAlignedNow;

    if (mounted && (headingChanged || alignedChanged)) {
      _lastPaintedHeading = _smoothedHeading;
      _lastAlignedPaint = isAlignedNow;
      _headingNotifier.value = _smoothedHeading;
      _isAlignedNotifier.value = isAlignedNow;
    }
  }

  double _normalizeAngle(double deg) {
    while (deg > 180) { deg -= 360; }
    while (deg < -180) { deg += 360; }
    return deg;
  }

  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final p1 = _degToRad(lat1);
    final p2 = _degToRad(lat2);
    final dLon = _degToRad(lon2 - lon1);
    final y = math.sin(dLon) * math.cos(p2);
    final x = math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  double _degToRad(double degree) => degree * math.pi / 180;

  double _angleDistance(double from, double to) {
    final delta = (to - from).abs() % 360;
    return delta > 180 ? 360 - delta : delta;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF95D3BA) : const Color(0xFF003527);
    final secondaryColor = isDark ? const Color(0xFFFFDCC3) : const Color(0xFF904D00);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => AppSidePanel.open(context),
        ),
        title: Text(
          'Kıble',
          style: GoogleFonts.notoSerif(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: scheme.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            _buildCompassInterface(primaryColor, secondaryColor, scheme, isDark),
            if (_needsPermission)
              Positioned(
                top: 0, left: 0, right: 0, bottom: 0,
                child: Container(
                  color: scheme.surface.withValues(alpha: 0.95),
                  child: _buildPermissionDenied(primaryColor, scheme),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDenied(Color primaryColor, ColorScheme scheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_rounded, size: 64, color: primaryColor.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            Text(
              'Kıble Yönü Hesaplama',
              style: GoogleFonts.notoSerif(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Hesaplamak için konum izni gereklidir. Arka planda izlenmez ve asla kaydedilmez.',
              style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14, color: scheme.onSurfaceVariant, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _initCompass(requestPermission: true),
              icon: const Icon(Icons.location_on),
              label: Text(AppText.of(context, 'grantLocation'), style: const TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF002117) : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompassInterface(Color primaryColor, Color secondaryColor, ColorScheme scheme, bool isDark) {
    final size = MediaQuery.sizeOf(context);
    final compassSize = (size.width * 0.7).clamp(200.0, 320.0);
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Text(
            'Kibleyi Bul',
            style: GoogleFonts.notoSerif(
              fontSize: 28,
              fontWeight: FontWeight.bold, 
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8, 
                height: 8, 
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706), 
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Pusulayı yatay tutup telefonu çevirin',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans', 
                  fontSize: 14, 
                  fontWeight: FontWeight.w600, 
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 28),
          
          AnimatedBuilder(
            animation: Listenable.merge([_headingNotifier, _isAlignedNotifier]),
            builder: (context, _) {
              final heading = _headingNotifier.value;
              final isAligned = _isAlignedNotifier.value;
              return SizedBox(
                height: compassSize,
                width: compassSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFD97706).withValues(alpha: isAligned ? 0.24 : 0.08),
                        Colors.transparent,
                      ],
                      stops: const [0.18, 0.72],
                    ),
                  ),
                ),
                
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.2)),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(48),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                  ),
                ),
                
                Container(
                  width: compassSize,
                  height: compassSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 2),
                    boxShadow: [
                      BoxShadow(color: primaryColor.withValues(alpha: 0.1), blurRadius: 24, offset: const Offset(0, 12)),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (int i = 0; i < 360; i += 15)
                        Transform.rotate(
                          angle: i * math.pi / 180,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              margin: const EdgeInsets.only(top: 8),
                              width: (i % 90 == 0) ? 3 : 1,
                              height: (i % 90 == 0) ? 12 : 8,
                              color: scheme.onSurface.withValues(alpha: (i % 90 == 0) ? 0.8 : 0.3),
                            ),
                          ),
                        ),
                      Transform.rotate(
                        angle: -heading * math.pi / 180,
                        child: Stack(
                          children: [
                            Positioned(top: 24, left: 0, right: 0, child: Text('N', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryColor))),
                            Positioned(bottom: 24, left: 0, right: 0, child: Text('S', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: scheme.onSurface.withValues(alpha: 0.5)))),
                            Positioned(left: 24, top: 0, bottom: 0, child: Center(child: Text('W', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: scheme.onSurface.withValues(alpha: 0.5))))),
                            Positioned(right: 24, top: 0, bottom: 0, child: Center(child: Text('E', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: scheme.onSurface.withValues(alpha: 0.5))))),
                          ],
                        ),
                      ),
                      
                      Transform.rotate(
                        angle: (_qiblaBearing - heading) * math.pi / 180,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            margin: const EdgeInsets.only(top: 36),
                            width: 8,
                            height: compassSize * 0.4,
                            decoration: BoxDecoration(
                              color: secondaryColor,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [BoxShadow(color: secondaryColor.withValues(alpha: 0.5), blurRadius: 8)],
                            ),
                          ),
                        ),
                      ),
                      
                      Transform.rotate(
                        angle: (_qiblaBearing - heading) * math.pi / 180,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.mosque, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                      
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
          }),
          
          const SizedBox(height: 28),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0B513D).withValues(alpha: 0.2) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0B513D) : const Color(0xFFB0F0D6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_circle_outline, color: isDark ? const Color(0xFFB0F0D6) : const Color(0xFF0B513D)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pusula Kalibre Edildi', 
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans', 
                            fontWeight: FontWeight.bold, 
                            color: primaryColor,
                          ),
                        ),
                        Text(
                          'Hassasiyet: Yüksek', 
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans', 
                            fontSize: 12, 
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}
