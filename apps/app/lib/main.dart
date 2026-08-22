import 'dart:math' as math;
import 'dart:typed_data';

import 'package:astro_core/astro_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'src/calibration_panel.dart';
import 'src/camera_panel.dart';
import 'src/night_panel.dart';
import 'src/report_panel.dart';
import 'src/camera_settings.dart';
import 'src/site.dart';
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

/// Alt paneldeki sekmeler.
enum _Tab { camera, plan, report, calibration }

class SkyScreen extends StatefulWidget {
  const SkyScreen({super.key});

  @override
  State<SkyScreen> createState() => _SkyScreenState();
}

class _SkyScreenState extends State<SkyScreen> {
  /// Secili gozlem yeri. Varsayilan Mersin — arac sabit bir sehre kilitli
  /// kalirsa baska sehirdeki kullaniciya sessizce yanlis gokyuzu gosterir.
  Site _site = sites.first;
  Observer get observer => _site.observer;

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

  /// Alt panelde kamera mi plan mi gorunuyor.
  _Tab _tab = _Tab.camera;

  /// Secili hedef. Galaktik merkez katalogda yok — projenin baslik hedefi
  /// oldugu icin elle ekleniyor.
  static final galacticCenter = Equatorial.fromHours(
    rightAscensionHours: 17 + 45 / 60 + 40.0 / 3600,
    declinationDegrees: -(29 + 28.0 / 3600),
  );
  Equatorial _target = galacticCenter;
  String _targetName = 'Galaktik merkez';

  /// Hedefin V kadiri. Difuz hedeflerde (galaktik merkez) yok — o zaman
  /// yildiz sinyali hesaplanamaz ve rapor bunu acikca soyler.
  double? _targetMagnitude;

  /// Sahadan gelen olcum defteri. Yuklenmediginde rapor eksikleri
  /// listeliyor; yuklendikce zincirin daha buyuk kismi aciliyor.
  LoadedCalibration? _calibration;
  NightPlan? _plan;

  /// Gosterim icin yerel saat farki; hesap hep UTC.
  Duration get _localOffset => _site.utcOffset;

  void _recomputePlan() {
    _plan = planNight(target: _target, observer: observer, aroundUtc: _utc);
  }

  /// Konum degisince gokyuzu de plan da bastan hesaplanir. Kisayol yok:
  /// atTime yalnizca zaman degisimi icin gecerli, gozlemci sabit
  /// varsayiyor.
  void _selectSite(Site site) {
    final catalog = _catalog;
    if (catalog == null) return;
    setState(() {
      _site = site;
      _sky = SkyModel.compute(
        catalog: catalog,
        utc: _utc,
        observer: site.observer,
      );
      _recomputePlan();
    });
  }

  void _selectTarget(Equatorial target, String name, {double? magnitude}) {
    setState(() {
      _target = target;
      _targetName = name;
      _targetMagnitude = magnitude;
      _recomputePlan();
    });
  }

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
      observer: observer,
      localSiderealTimeDegrees: localMeanSiderealTimeDegrees(
        julianDay(_utc),
        observer.longitudeEastDegrees,
      ),
    ).declinationDegrees;
  }

  /// Hedefin su anki yuksekligi. Rapor hava kutlesini bundan hesapliyor.
  double get _targetAltitude => equatorialToHorizontal(
    equatorial: _target,
    observer: observer,
    localSiderealTimeDegrees: localMeanSiderealTimeDegrees(
      julianDay(_utc),
      observer.longitudeEastDegrees,
    ),
  ).altitudeDegrees;

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
          observer: observer,
        );
        _recomputePlan();
      });
    } catch (e) {
      setState(() => _error = e);
    }
  }

  /// Zaman degisince gokyuzu yeniden hesaplanir — panlamada DEGIL.
  ///
  /// Ayni gun icinde kaliniyorsa presesyon tekrarlanmaz ([SkyModel.atTime]);
  /// zaman kaydiricisi bu sayede akici kaliyor.
  void _setTime(DateTime utc, {bool recomputePlan = true}) {
    final catalog = _catalog;
    final sky = _sky;
    if (catalog == null) return;
    setState(() {
      final sameDay =
          sky != null &&
          sky.utc.year == utc.year &&
          sky.utc.month == utc.month &&
          sky.utc.day == utc.day;
      _utc = utc;
      _sky = sameDay
          ? sky.atTime(utc)
          : SkyModel.compute(catalog: catalog, utc: utc, observer: observer);
      if (recomputePlan) _recomputePlan();
    });
  }

  /// Takvimden tarih secimi. Gunun saatini korur — kullanici gece
  /// yarisina ayarladigi saati her tarih degisiminde yeniden bulmak
  /// zorunda kalmasin.
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _utc,
      firstDate: DateTime.utc(2000),
      lastDate: DateTime.utc(2050),
    );
    if (picked == null || !mounted) return;
    _setTime(
      DateTime.utc(
        picked.year,
        picked.month,
        picked.day,
        _utc.hour,
        _utc.minute,
      ),
    );
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
          _timeSlider(),
          const SizedBox(height: 8),
          Row(
            children: [
              SegmentedButton<_Tab>(
                segments: const [
                  ButtonSegment(value: _Tab.camera, label: Text('Kamera')),
                  ButtonSegment(value: _Tab.plan, label: Text('Plan')),
                  ButtonSegment(value: _Tab.report, label: Text('Rapor')),
                  ButtonSegment(
                    value: _Tab.calibration,
                    label: Text('Kalibrasyon'),
                  ),
                ],
                selected: {_tab},
                showSelectedIcon: false,
                onSelectionChanged: (v) => setState(() => _tab = v.first),
              ),
              if (_tab == _Tab.plan || _tab == _Tab.report) ...[
                const SizedBox(width: 12),
                Expanded(child: _targetSelector()),
                const SizedBox(width: 12),
                _siteSelector(),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (_tab == _Tab.calibration)
            CalibrationPanel(
              loaded: _calibration,
              onChanged: (c) => setState(() => _calibration = c),
            )
          else if (_tab == _Tab.report)
            ReportPanel(
              settings: _settings,
              targetName: _targetName,
              altitudeDegrees: _targetAltitude,
              declinationDegrees: _target.declinationDegrees,
              vMagnitude: _targetMagnitude,
              // Messier katalogunda B-V yok; yildiz kataloguna baglanmasi
              // Faz 6'nin isi. Simdilik null, rapor bunu eksik sayiyor.
              colorIndexBV: null,
              calibration: _calibration?.calibration ?? CalibrationSet.empty,
              onChanged: (s) => setState(() => _settings = s),
            )
          else if (_tab == _Tab.plan && _plan != null)
            NightPanel(
              plan: _plan!,
              targetName: _targetName,
              currentUtc: _utc,
              localOffset: _localOffset,
            )
          else
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
                    _setTime(_utc.subtract(const Duration(days: 1))),
                icon: const Icon(Icons.keyboard_double_arrow_left),
                tooltip: '-1 gun',
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                onPressed: () =>
                    _setTime(_utc.subtract(const Duration(hours: 1))),
                icon: const Icon(Icons.chevron_left),
                tooltip: '-1 saat',
              ),
              const SizedBox(width: 4),
              // Tarihe basinca takvim acilir. Ay evresinin plani nasil
              // degistirdigini gormek icin hafta atlamak gerekiyor; bunu
              // +1 gun dugmesine on kez basarak yapmak test edilebilir
              // bir davranis degil.
              TextButton(
                onPressed: _pickDate,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '${_utc.year}-${_utc.month.toString().padLeft(2, '0')}-'
                  '${_utc.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Color(0xFFDDE8F2),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton.filledTonal(
                onPressed: () => _setTime(_utc.add(const Duration(hours: 1))),
                icon: const Icon(Icons.chevron_right),
                tooltip: '+1 saat',
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                onPressed: () => _setTime(_utc.add(const Duration(days: 1))),
                icon: const Icon(Icons.keyboard_double_arrow_right),
                tooltip: '+1 gun',
              ),
            ],
          ),
        ],
      ),
    ),
  );

  /// T4.1 — dakika hassasiyetinde zaman kaydiricisi.
  ///
  /// Gunun ortasina gore -12 / +12 saat. Kaydirdikca yildizlar donuyor;
  /// gokyuzunun gercekten hareket ettigini gormek, aracin dogru
  /// calistigina dair en hizli sezgisel kontrol.
  Widget _timeSlider() {
    final dayStart = DateTime.utc(_utc.year, _utc.month, _utc.day);
    final minutes = _utc.difference(dayStart).inMinutes.toDouble();
    return Row(
      children: [
        SizedBox(
          width: 116,
          child: Text(
            '${_utc.add(_localOffset).hour.toString().padLeft(2, '0')}:'
            '${_utc.add(_localOffset).minute.toString().padLeft(2, '0')} yerel',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        Expanded(
          child: Slider(
            value: minutes,
            min: 0,
            max: 1439,
            divisions: 1439,
            onChanged: (v) => _setTime(
              dayStart.add(Duration(minutes: v.round())),
              // Plan gece boyunca ayni; her dakikada yeniden hesaplamak
              // gereksiz ve kaydiriciyi tutuklastirir.
              recomputePlan: false,
            ),
            onChangeEnd: (_) => setState(_recomputePlan),
          ),
        ),
      ],
    );
  }

  /// Konum secimi. Faz 7'ye kadar hazir sehir listesi yeterli.
  ///
  /// Koordinat metni de gosteriliyor: 0.C'deki VIIRS sorgusu ondalik
  /// derece istiyor ve kullanicinin sahada hangi noktayi kullandigini
  /// bilmesi gerekiyor.
  Widget _siteSelector() => Tooltip(
    message:
        'Konum: ${_site.coordinateText}  ·  ${_site.elevationMeters.toStringAsFixed(0)} m',
    child: DropdownButton<String>(
      value: _site.name,
      isDense: true,
      underline: const SizedBox.shrink(),
      style: const TextStyle(fontSize: 13, color: Color(0xFFDDE8F2)),
      dropdownColor: const Color(0xFF10171F),
      icon: const Icon(Icons.place_outlined, size: 16),
      items: [
        for (final site in sites)
          DropdownMenuItem(value: site.name, child: Text(site.name)),
      ],
      onChanged: (name) {
        if (name == null) return;
        _selectSite(sites.firstWhere((s) => s.name == name));
      },
    ),
  );

  /// Hedef secimi: galaktik merkez + Messier katalogu.
  Widget _targetSelector() => DropdownButton<String>(
    value: _targetName,
    isExpanded: true,
    isDense: true,
    underline: const SizedBox.shrink(),
    style: const TextStyle(fontSize: 13, color: Color(0xFFDDE8F2)),
    dropdownColor: const Color(0xFF10171F),
    items: [
      const DropdownMenuItem(
        value: 'Galaktik merkez',
        child: Text('Galaktik merkez'),
      ),
      for (final m in messierCatalog)
        DropdownMenuItem(
          value: m.designation,
          child: Text(
            '${m.designation}  ${messierTypeNames[m.type] ?? m.type}'
            '${m.magnitude != null ? "  ${m.magnitude}" : ""}',
          ),
        ),
    ],
    onChanged: (name) {
      if (name == null) return;
      if (name == 'Galaktik merkez') {
        _selectTarget(galacticCenter, name);
        return;
      }
      final m = messierCatalog.firstWhere((o) => o.designation == name);
      _selectTarget(
        Equatorial(
          rightAscensionDegrees: m.rightAscensionDegrees,
          declinationDegrees: m.declinationDegrees,
        ),
        name,
        magnitude: m.magnitude,
      );
    },
  );

  /// Yatay gorus alanindan esdeger tam kare odak uzunlugu, mm.
  ///
  /// Rectilinear lens bagintisi: FOV = 2 * atan(yari_sensor / odak).
  /// Tam karede yari genislik 18 mm.
  double _equivalentFocalLength(double fovDegrees) =>
      18.0 / math.tan(toRadians(fovDegrees / 2));
}
