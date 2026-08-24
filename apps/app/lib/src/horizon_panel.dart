import 'package:astro_core/astro_core.dart';
import 'package:flutter/material.dart';

/// T7.4 — Ufuk profili duzenleyici.
///
/// Sekiz ana yonde tepe acisi girilir, aradaki azimutlar
/// interpolasyonla dolar. Sekiz nokta cogu yer icin yeterli; daha
/// sik olcum, olcumun kendi belirsizliginin (birkac derece) altina
/// inmiyor.
///
/// **Neden elle giriliyor:** uydu yukseklik verisi (DEM) agaclari,
/// binalari ve duvari goremez. Sahada gozle olculen ufuk cogu zaman
/// daha dogru — ve internet gerektirmiyor.
class HorizonPanel extends StatelessWidget {
  /// Sekiz yonun yukseklikleri, derece. Sirasi [directions] ile ayni.
  final List<double> altitudes;
  final ValueChanged<List<double>> onChanged;

  /// Ufkun plan hesabina katilip katilmadigi.
  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;

  const HorizonPanel({
    super.key,
    required this.altitudes,
    required this.onChanged,
    required this.enabled,
    required this.onEnabledChanged,
  });

  /// Sekiz ana yon: ad ve azimut.
  static const directions = <(String, double)>[
    ('K', 0.0),
    ('KD', 45.0),
    ('D', 90.0),
    ('GD', 135.0),
    ('G', 180.0),
    ('GB', 225.0),
    ('B', 270.0),
    ('KB', 315.0),
  ];

  static const flat = <double>[0, 0, 0, 0, 0, 0, 0, 0];

  /// Girilen degerlerden profil kurar.
  static Horizon buildHorizon(List<double> altitudes) {
    if (altitudes.every((a) => a.abs() < 1e-9)) return Horizon.flat();
    return Horizon.fromPoints({
      for (var i = 0; i < directions.length; i++)
        directions[i].$2: altitudes[i],
    }, source: 'elle olculdu (8 yon)');
  }

  @override
  Widget build(BuildContext context) {
    final horizon = buildHorizon(altitudes);
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
            Row(
              children: [
                Switch(
                  value: enabled,
                  onChanged: onEnabledChanged,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Ufku hesaba kat',
                    style: TextStyle(fontSize: 12, color: Color(0xFFDDE8F2)),
                  ),
                ),
                TextButton(
                  onPressed: () => onChanged(List<double>.from(flat)),
                  child: const Text('Sifirla'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Her yonde en yuksek engelin acisini gir. Olcum talimati:\n'
              'docs/ufuk-olcumu.md',
              style: TextStyle(
                fontSize: 10,
                height: 1.5,
                fontFamily: 'monospace',
                color: Color(0xFF6B8299),
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < directions.length; i++) _row(i),
            const SizedBox(height: 8),
            _summary(horizon),
          ],
        ),
      ),
    );
  }

  Widget _row(int i) {
    final (name, azimuth) = directions[i];
    final value = altitudes[i];
    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(
            name,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Color(0xFFDDE8F2),
            ),
          ),
        ),
        SizedBox(
          width: 42,
          child: Text(
            '${azimuth.toStringAsFixed(0)}°',
            style: const TextStyle(fontSize: 10, color: Color(0xFF6B8299)),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 45,
            divisions: 90,
            onChanged: (v) {
              final next = List<double>.from(altitudes);
              next[i] = v;
              onChanged(next);
            },
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            '${value.toStringAsFixed(1)}°',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: value > 0
                  ? const Color(0xFFE0A44C)
                  : const Color(0xFF44586B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summary(Horizon horizon) {
    if (horizon.isFlat) {
      return const Text(
        'Duz ufuk — hicbir yon engelli degil.',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          color: Color(0xFF6B8299),
        ),
      );
    }
    final (alt, az) = horizon.highest;
    final name = directions
        .reduce((a, b) => (a.$2 - az).abs() < (b.$2 - az).abs() ? a : b)
        .$1;
    return DefaultTextStyle(
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 11,
        height: 1.5,
        color: Color(0xFFBFD4E6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('En yuksek engel ${alt.toStringAsFixed(1)}°, $name yonunde'),
          Text(
            'Gokyuzunun %${(horizon.blockedSkyFraction * 100).toStringAsFixed(1)}\'i kapali',
          ),
        ],
      ),
    );
  }
}
