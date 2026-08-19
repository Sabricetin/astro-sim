import 'package:astro_core/astro_core.dart';

/// Gozlem yeri.
///
/// Faz 7'nin tam konum secimi (harita, ufuk profili, VIIRS) daha sonra
/// gelecek. Buradaki liste o zamana kadar yetecek kadari: kullanicinin
/// gercekten bulundugu yeri secebilmesi. Sabit bir sehre kilitli arac,
/// baska sehirdeki kullaniciya sessizce yanlis gokyuzu gosterir — ve
/// yanlis oldugu hicbir yerde yazmaz.
class Site {
  final String name;
  final double latitudeDegrees;

  /// Dogu pozitif. Meeus bati pozitif kullanir; donusum astro_core'un
  /// sinirinda yapiliyor, burada her zaman dogu pozitif.
  final double longitudeEastDegrees;
  final double elevationMeters;

  /// UTC'ye gore yerel saat farki. Yalnizca **gosterim** icin; hesap
  /// her zaman UTC.
  final Duration utcOffset;

  const Site({
    required this.name,
    required this.latitudeDegrees,
    required this.longitudeEastDegrees,
    required this.elevationMeters,
    this.utcOffset = const Duration(hours: 3),
  });

  Observer get observer => Observer(
    latitudeDegrees: latitudeDegrees,
    longitudeEastDegrees: longitudeEastDegrees,
    elevationMeters: elevationMeters,
  );

  /// Ondalik derece, 5 hane — VIIRS sorgusunun istedigi bicim.
  String get coordinateText =>
      '${latitudeDegrees.toStringAsFixed(5)}, '
      '${longitudeEastDegrees.toStringAsFixed(5)}';

  Site copyWith({
    String? name,
    double? latitudeDegrees,
    double? longitudeEastDegrees,
    double? elevationMeters,
  }) => Site(
    name: name ?? this.name,
    latitudeDegrees: latitudeDegrees ?? this.latitudeDegrees,
    longitudeEastDegrees: longitudeEastDegrees ?? this.longitudeEastDegrees,
    elevationMeters: elevationMeters ?? this.elevationMeters,
    utcOffset: utcOffset,
  );
}

/// Hazir konumlar. Rakim gercek degerlere yakin tutuldu — hava kutlesi
/// ve sonum hesabi Faz 5'te bunu kullanacak.
const sites = <Site>[
  Site(
    name: 'Mersin (Akdeniz)',
    latitudeDegrees: 36.80,
    longitudeEastDegrees: 34.62,
    elevationMeters: 10,
  ),
  Site(
    name: 'Gaziantep',
    latitudeDegrees: 37.0662,
    longitudeEastDegrees: 37.3833,
    elevationMeters: 850,
  ),
  Site(
    name: 'Ankara',
    latitudeDegrees: 39.9334,
    longitudeEastDegrees: 32.8597,
    elevationMeters: 890,
  ),
  Site(
    name: 'Istanbul',
    latitudeDegrees: 41.0082,
    longitudeEastDegrees: 28.9784,
    elevationMeters: 40,
  ),
  Site(
    name: 'Izmir',
    latitudeDegrees: 38.4237,
    longitudeEastDegrees: 27.1428,
    elevationMeters: 25,
  ),
  Site(
    name: 'Antalya',
    latitudeDegrees: 36.8969,
    longitudeEastDegrees: 30.7133,
    elevationMeters: 30,
  ),
  Site(
    name: 'Erzurum',
    latitudeDegrees: 39.9043,
    longitudeEastDegrees: 41.2769,
    elevationMeters: 1890,
  ),
];
