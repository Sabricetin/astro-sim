import 'dart:math' as math;
import 'dart:typed_data';

import 'package:astro_core/astro_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'src/camera_panel.dart';
import 'src/camera_settings.dart';
import 'src/sky_model.dart';
import 'src/sky_painter.dart';

void main() => runApp(const AstroSimApp());

class AstroSimApp extends StatelessWidget {
  const AstroSimApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Astro Poz Simulatoru',
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(useMaterial3: true),
    home: const SkyScreen(),
  );
}

/// Hazir bakis ayari — Faz 2'nin cikis kriterini dogrulamak icin.
///
/// Zaman ve yon, hedefin gokyuzunde en yuksek oldugu ana gore secildi
/// (Gaziantep'ten hesaplandi). Amac: uygulamayi acan kisinin taniyabilecegi
/// bir goruntuyu tek dokunusla gormesi.
class ViewPreset {
  final String label;
  final DateTime utc;
  final double azimuth;
  final double altitude;
  final double fov;

  const ViewPreset(this.label, this.utc, this.azimuth, this.altitude, this.fov);
}

final presets = <ViewPreset>[
  ViewPreset('Orion', DateTime.utc(2026, 3, 15, 16), 190.1, 51.3, 60),
  ViewPreset('Buyuk Ayi', DateTime.utc(2026, 3, 15, 21), 0.6, 65.5, 70),
  ViewPreset('Genis aci (14 mm)', DateTime.utc(2026, 3, 15, 21), 180, 45, 104),
];

class SkyScreen extends StatefulWidget {
  const SkyScreen({super.key});

  @override
  State<SkyScreen> createState() => _SkyScreenState();
}

class _SkyScreenState extends State<SkyScreen> {
  static final gaziantep = Observer(
    latitudeDegrees: 37.0662,
    longitudeEastDegrees: 37.3833,
    elevationMeters: 850,
  );

  StarCatalog? _catalog;
  SkyModel? _sky;
  Float32List? _scratch;
  Object? _error;

  double _azimuth = presets.first.azimuth;
  double _altitude = presets.first.altitude;
  double _fov = presets.first.fov;
  DateTime _utc = presets.first.utc;

  bool _showConstellations = true;
  bool _showLabels = true;
  bool _showFrame = true;
  double _roll = 0;

  CameraSettings _settings = CameraSettings(
    camera: cameras.first, // Canon EOS 760D — kalibrasyonu yapilan govde
  );

  /// Ekran ortasindaki noktanin sapmasi. NPF duzeltmesi bunu kullanir:
  /// kutba yakin hedeflerde daha uzun poz verilebilir.
  double get _centerDeclination {
    final sky = _sky;
    if (sky == null) return 0;
    return horizontalToEquatorial(
      horizontal: Horizontal(
        azimuthDegrees: _azimuth,
        altitudeDegrees: _altitude,
      ),
      observer: gaziantep,
      localSiderealTimeDegrees: localMeanSiderealTimeDegrees(
        julianDay(_utc),
        gaziantep.longitudeEastDegrees,
      ),
    ).declinationDegrees;
  }

  double _fovAtGestureStart = 0;
  double _rollAtGestureStart = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final catalog = await SkyModel.loadCatalog();
      setState(() {
        _catalog = catalog;
        _scratch = Float32List(catalog.length * 2);
        _sky = SkyModel.compute(
          catalog: catalog,
          utc: _utc,
          observer: gaziantep,
        );
      });
    } catch (e) {
      setState(() => _error = e);
    }
  }

  /// Zaman degisince gokyuzu yeniden hesaplanir — panlamada DEGIL.
  void _setTime(DateTime utc) {
    final catalog = _catalog;
    if (catalog == null) return;
    setState(() {
      _utc = utc;
      _sky = SkyModel.compute(catalog: catalog, utc: utc, observer: gaziantep);
    });
  }

  void _applyPreset(ViewPreset p) {
    setState(() {
      _azimuth = p.azimuth;
      _altitude = p.altitude;
      _fov = p.fov;
    });
    if (p.utc != _utc) _setTime(p.utc);
  }

  void _pan(Offset delta, Size size) {
    // Piksel basina derece: yatay gorus alani ekran genisligine yayilir.
    final degreesPerPixel = _fov / size.width;
    setState(() {
      // Yuksekte azimut cemberleri sikisir: basucuna yakin 1 derece azimut,
      // ufuktakinden cok daha kisa bir yay demektir. Bolmezsek surukleme
      // yukari ciktikca asiri hizlanir. Kirpma, tam basucunda sonsuza
      // gitmesini engelliyor.
      final altitudeFactor =
          1.0 / math.cos(toRadians(_altitude)).clamp(0.15, 1.0);
      _azimuth = normalizeDegrees(
        _azimuth - delta.dx * degreesPerPixel * altitudeFactor,
      );
      _altitude = (_altitude + delta.dy * degreesPerPixel).clamp(-89.0, 89.0);
    });
  }

  void _zoom(double factor) {
    setState(() => _fov = (_fov * factor).clamp(2.0, 140.0));
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Katalog yuklenemedi:\n$_error\n\n'
              'Uretmeyi denedin mi?\n'
              './.venv/bin/python tools/build_star_catalog.py',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final sky = _sky;
    final scratch = _scratch;
    if (sky == null || scratch == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                _zoom(event.scrollDelta.dy > 0 ? 1.08 : 1 / 1.08);
              }
            },
            child: GestureDetector(
              onScaleStart: (_) {
                _fovAtGestureStart = _fov;
                _rollAtGestureStart = _roll;
              },
              onScaleUpdate: (d) {
                if (d.rotation != 0.0) {
                  // T3.4: iki parmakla dondurme -> kamera roll'u.
                  setState(
                    () => _roll = normalizeDegreesSigned(
                      _rollAtGestureStart + toDegrees(d.rotation),
                    ),
                  );
                }
                if (d.scale != 1.0) {
                  setState(
                    () =>
                        _fov = (_fovAtGestureStart / d.scale).clamp(2.0, 140.0),
                  );
                } else if (d.rotation == 0.0) {
                  _pan(d.focalPointDelta, size);
                }
              },
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: SkyPainter(
                        sky: sky,
                        centerAzimuthDegrees: _azimuth,
                        centerAltitudeDegrees: _altitude,
                        horizontalFovDegrees: _fov,
                        scratch: scratch,
                        rollDegrees: _roll,
                        showConstellations: _showConstellations,
                        showLabels: _showLabels,
                        frame: _showFrame
                            ? _settings.copyWith(
                                targetDeclinationDegrees: _centerDeclination,
                              )
                            : null,
                      ),
                    ),
                  ),
                  _overlay(sky),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _overlay(SkyModel sky) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final p in presets)
                FilledButton.tonal(
                  onPressed: () => _applyPreset(p),
                  child: Text(p.label),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Takim yildizi cizgileri'),
                selected: _showConstellations,
                onSelected: (v) => setState(() => _showConstellations = v),
              ),
              FilterChip(
                label: const Text('Yildiz adlari'),
                selected: _showLabels,
                onSelected: (v) => setState(() => _showLabels = v),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xCC0B1018),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: DefaultTextStyle(
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.5,
                  color: Color(0xFFBFD4E6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${_utc.toIso8601String()}Z'),
                    Text(
                      'bakis  Az ${formatDms(_azimuth, decimals: 0)}  '
                      'Alt ${formatDms(_altitude, decimals: 0)}',
                    ),
                    Text(
                      'FOV    ${_fov.toStringAsFixed(1)}°  '
                      '(~${_equivalentFocalLength(_fov).toStringAsFixed(0)} mm tam kare)',
                    ),
                    Text('yildiz ${sky.starCount}'),
                    const Text(
                      'surukle: bakis   kaydir/kistir: zoom',
                      style: TextStyle(color: Color(0xFF6B8299)),
                    ),
                    const Text(
                      'Orion: kum saati figuru, ortada uc yildizli kusak',
                      style: TextStyle(color: Color(0xFF6B8299)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          CameraPanel(
            settings: _settings.copyWith(
              targetDeclinationDegrees: _centerDeclination,
            ),
            onChanged: (s) => setState(() => _settings = s),
            showFrame: _showFrame,
            onShowFrameChanged: (v) => setState(() => _showFrame = v),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: () =>
                    _setTime(_utc.subtract(const Duration(hours: 1))),
                icon: const Icon(Icons.fast_rewind),
                tooltip: '-1 saat',
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: () => _setTime(_utc.add(const Duration(hours: 1))),
                icon: const Icon(Icons.fast_forward),
                tooltip: '+1 saat',
              ),
            ],
          ),
        ],
      ),
    ),
  );

  /// Yatay gorus alanindan esdeger tam kare odak uzunlugu, mm.
  ///
  /// Rectilinear lens bagintisi: FOV = 2 * atan(yari_sensor / odak).
  /// Tam karede yari genislik 18 mm.
  double _equivalentFocalLength(double fovDegrees) =>
      18.0 / math.tan(toRadians(fovDegrees / 2));
}
