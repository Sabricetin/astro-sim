import 'package:astro_core/astro_core.dart';
import 'package:flutter/material.dart';

import 'camera_settings.dart';

/// Ekipman secimi ve poz degerlendirmesi.
///
/// Tasarim sisteminde (§4) accent renkleri yalnizca **bilgi anlami**
/// tasimali diye yaziyor. Burada tek renkli gosterge var ve o da poz
/// durumu: yesil guvenli, turuncu sinira yakin, kirmizi asilmis.
class CameraPanel extends StatelessWidget {
  final CameraSettings settings;
  final ValueChanged<CameraSettings> onChanged;
  final bool showFrame;
  final ValueChanged<bool> onShowFrameChanged;

  const CameraPanel({
    super.key,
    required this.settings,
    required this.onChanged,
    required this.showFrame,
    required this.onShowFrameChanged,
  });

  /// Poz durumu: NPF sinirina gore renk ve metin.
  ///
  /// Esikler: sinirin altinda yesil, %100-150 arasi turuncu (iz farkedilir
  /// ama bazi kadrajlarda kabul edilebilir), ustu kirmizi.
  ({Color color, String label}) get _status {
    final ratio = settings.exposureSeconds / settings.maxExposureSeconds;
    if (ratio <= 1.0) {
      return (color: const Color(0xFF5FD08A), label: 'Yildizlar noktasal');
    }
    if (ratio <= 1.5) {
      return (color: const Color(0xFFE0A44C), label: 'Hafif iz');
    }
    return (color: const Color(0xFFE06C6C), label: 'Belirgin iz');
  }

  @override
  Widget build(BuildContext context) {
    final fov = settings.fieldOfView;
    final status = _status;

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
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _dropdown<Camera>(
                  label: 'Govde',
                  value: settings.camera,
                  items: cameras,
                  itemLabel: (c) =>
                      '${c.name}  ${c.megapixels.toStringAsFixed(0)} MP',
                  onChanged: (c) => onChanged(settings.copyWith(camera: c)),
                ),
                _dropdown<double>(
                  label: 'Odak',
                  value: settings.focalLengthMm,
                  items: CameraSettings.focalLengths,
                  itemLabel: (f) => '${f.toStringAsFixed(0)} mm',
                  onChanged: (f) =>
                      onChanged(settings.copyWith(focalLengthMm: f)),
                ),
                _dropdown<double>(
                  label: 'Diyafram',
                  value: settings.aperture,
                  items: CameraSettings.apertures,
                  itemLabel: (a) => 'f/$a',
                  onChanged: (a) => onChanged(settings.copyWith(aperture: a)),
                ),
                FilterChip(
                  label: const Text('Dikey'),
                  selected: settings.portrait,
                  onSelected: (v) => onChanged(settings.copyWith(portrait: v)),
                ),
                FilterChip(
                  label: const Text('Cerceve'),
                  selected: showFrame,
                  onSelected: onShowFrameChanged,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 78,
                  child: Text(
                    'Poz  ${settings.exposureSeconds.toStringAsFixed(0)} s',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: settings.exposureSeconds,
                    min: 1,
                    max: 120,
                    divisions: 119,
                    onChanged: (v) =>
                        onChanged(settings.copyWith(exposureSeconds: v)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            DefaultTextStyle(
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.6,
                color: Color(0xFFBFD4E6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Kadraj   ${fov.horizontalDegrees.toStringAsFixed(1)}° x '
                    '${fov.verticalDegrees.toStringAsFixed(1)}°   '
                    '(kirpma ${settings.camera.format.cropFactor.toStringAsFixed(2)}x)',
                  ),
                  Text(
                    'NPF      ${settings.maxExposureSeconds.toStringAsFixed(1)} s   '
                    '(500 kurali ${settings.fiveHundredRule.toStringAsFixed(0)} s derdi)',
                  ),
                  Text(
                    'Olcek    ${arcsecondsPerPixel(pixelPitchMicrometers: settings.camera.pixelPitchMicrometers, focalLengthMm: settings.focalLengthMm).toStringAsFixed(1)}"/px   '
                    'piksel ${settings.camera.pixelPitchMicrometers.toStringAsFixed(2)} um',
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: status.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${status.label} — iz '
                        '${settings.trailPixels.toStringAsFixed(1)} piksel',
                        style: TextStyle(
                          color: status.color,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T> onChanged,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 10, color: Color(0xFF6B8299)),
      ),
      DropdownButton<T>(
        value: value,
        isDense: true,
        underline: const SizedBox.shrink(),
        style: const TextStyle(fontSize: 13, color: Color(0xFFDDE8F2)),
        dropdownColor: const Color(0xFF10171F),
        items: [
          for (final item in items)
            DropdownMenuItem(value: item, child: Text(itemLabel(item))),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    ],
  );
}
