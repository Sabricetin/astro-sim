import 'package:astro_core/astro_core.dart';
import 'package:flutter/material.dart';

import 'camera_settings.dart';

/// T5 — Poz raporu.
///
/// Yol haritasinin "aracin ciktisi guzel bir goruntu degil, bir rapor"
/// dedigi ekran. Bugun cumlenin **geometrik yarisi** kuruluyor; digeri
/// olcum bekliyor.
///
/// Tasarim karari: eksik kismi bos birakmak ya da "0.0" gostermek
/// yerine **neyin eksik oldugunu ve nereden gelecegini** yaziyoruz.
/// Bos alan kullaniciya "arac bozuk" dedirtir; "k olculmedi, 0.B Dizi
/// B'den gelecek" ise durumu dogru anlatir ve ne yapmasi gerektigini
/// soyler.
class ReportPanel extends StatelessWidget {
  final CameraSettings settings;
  final String targetName;

  /// Hedefin su anki yuksekligi.
  final double altitudeDegrees;

  /// Hedefin sapmasi — iz hesabinda kullaniliyor.
  final double declinationDegrees;

  /// Hedefin V kadiri. Galaktik merkez gibi difuz hedeflerde yok.
  final double? vMagnitude;

  final double? colorIndexBV;
  final ValueChanged<CameraSettings> onChanged;

  const ReportPanel({
    super.key,
    required this.settings,
    required this.targetName,
    required this.altitudeDegrees,
    required this.declinationDegrees,
    required this.onChanged,
    required this.vMagnitude,
    required this.colorIndexBV,
  });

  static const _mono = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    height: 1.55,
    color: Color(0xFFBFD4E6),
  );

  MeasuredSensorProfile? get _sensor =>
      measuredProfileFor(cameraName: settings.camera.name, iso: settings.iso);

  @override
  Widget build(BuildContext context) {
    final sensor = _sensor;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE60B1018),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _isoRow(),
            const SizedBox(height: 10),
            if (sensor == null) _noSensorProfile() else ..._report(sensor),
          ],
        ),
      ),
    );
  }

  Widget _isoRow() => Row(
    children: [
      const Text(
        'ISO',
        style: TextStyle(fontSize: 10, color: Color(0xFF6B8299)),
      ),
      const SizedBox(width: 8),
      SegmentedButton<int>(
        segments: [
          for (final iso in measuredIsoValues)
            ButtonSegment(value: iso, label: Text('$iso')),
        ],
        selected: {settings.iso},
        showSelectedIcon: false,
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11)),
        ),
        onSelectionChanged: (v) => onChanged(settings.copyWith(iso: v.first)),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          _sensor == null
              ? 'olculmemis'
              : 'kazanc ${_sensor!.gain.value.toStringAsFixed(4)} e-/ADU  '
                    '±%${((_sensor!.gain.relativeUncertainty ?? 0) * 100).toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 10,
            fontFamily: 'monospace',
            color: Color(0xFF6B8299),
          ),
        ),
      ),
    ],
  );

  /// Olculmemis govde/ISO icin hesap yapilmaz.
  Widget _noSensorProfile() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(Icons.block, size: 14, color: Color(0xFFE06C6C)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${settings.camera.name} @ ISO ${settings.iso} icin '
              'olculmus sensor verisi yok',
              style: const TextStyle(
                color: Color(0xFFE06C6C),
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      const Text(
        'Kazanc ve okuma gurultusu olculmeden radyometri hesabi\n'
        'yapilamaz. Ara degeri interpolasyonla uretmek, olculmus\n'
        'sayilarla uydurma sayilari ayirt edilemez hale getirir.\n\n'
        'Olculmus: Canon EOS 760D @ ISO 800 / 1600 / 3200 (Faz 0.A)',
        style: _mono,
      ),
    ],
  );

  List<Widget> _report(MeasuredSensorProfile sensor) {
    final report = buildExposureReport(
      targetName: targetName,
      vMagnitude: vMagnitude ?? 0,
      altitudeDegrees: altitudeDegrees,
      declinationDegrees: declinationDegrees,
      focalLengthMm: settings.focalLengthMm,
      fNumber: settings.aperture,
      exposureSeconds: settings.exposureSeconds,
      sensor: sensor,
      pixelPitchMicrometers: settings.camera.pixelPitchMicrometers,
      colorIndexBV: colorIndexBV,
    );

    return [
      const _SectionLabel('HESAPLANAN'),
      const SizedBox(height: 4),
      DefaultTextStyle(
        style: _mono,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [for (final line in report.statements) Text(line)],
        ),
      ),
      if (vMagnitude == null) ...[
        const SizedBox(height: 6),
        const Text(
          'Bu hedefin V kadiri yok (difuz), yildiz sinyali hesaplanamaz.',
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'monospace',
            color: Color(0xFF6B8299),
          ),
        ),
      ],
      const SizedBox(height: 12),
      _SectionLabel('OLCUM BEKLEYEN  (${report.missing.length})'),
      const SizedBox(height: 6),
      for (final q in report.missing) _missingRow(q),
      const SizedBox(height: 8),
      _progress(report),
    ];
  }

  Widget _missingRow(MissingQuantity q) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Tooltip(
      message: q.why,
      textStyle: const TextStyle(fontSize: 11, color: Color(0xFFDDE8F2)),
      decoration: BoxDecoration(
        color: const Color(0xF0121A24),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 5, right: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFE0A44C),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(
            width: 58,
            child: Text(
              q.symbol,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Color(0xFFE0A44C),
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${q.name}\n${q.comesFrom}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                height: 1.4,
                color: Color(0xFF8FA5B8),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  /// Kac halkanin tamamlandigi. Kalibrasyon geldikce dolacak.
  Widget _progress(ExposureReport report) {
    const total = 7;
    final done = total - report.missing.length;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: done / total,
              minHeight: 5,
              backgroundColor: const Color(0xFF1B2733),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF5FD08A)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$done / $total halka',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: Color(0xFF6B8299),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 10,
      letterSpacing: 1.2,
      color: Color(0xFF6B8299),
    ),
  );
}
