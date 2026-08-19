import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

import 'reference_matrix.g.dart';

/// T1.7 — Faz 1'in cikis kriteri.
///
/// 5 yildiz x 3 konum x 3 zaman = 45 nokta, bagimsiz bir kaynakla
/// (astropy / ERFA / SOFA) karsilastirilir. Tolerans **0.1 derece**.
///
/// Neden bu test butun oteki testlerden onemli: diger testler kodun kendi
/// icinde tutarli oldugunu gosterir. Bu test, kodun *gercekten dogru*
/// oldugunu gosterir. Bir formulu bastan sona yanlis uygulamis olsaydik
/// gidis-donus testleri yine gecerdi — bu gecmezdi.
void main() {
  /// Yol haritasindaki tolerans.
  const toleranceDegrees = 0.1;

  /// Bizim zincirimiz: J2000 katalog konumu -> presesyon -> Alt/Az.
  /// Kirilma UYGULANMAZ; astropy tarafinda da pressure=0.
  Horizontal compute(ReferenceRow row) {
    final utc = DateTime.parse('${row.utcIso}Z');
    final j2000Position = Equatorial(
      rightAscensionDegrees: row.raJ2000Degrees,
      declinationDegrees: row.decJ2000Degrees,
    );
    final ofDate = precessFromJ2000At(j2000Position: j2000Position, utc: utc);
    return equatorialToHorizontalAt(
      equatorial: ofDate,
      observer: Observer(
        latitudeDegrees: row.latitudeDegrees,
        longitudeEastDegrees: row.longitudeEastDegrees,
        elevationMeters: row.elevationMeters,
      ),
      utc: utc,
    );
  }

  /// Gokyuzu uzerindeki gercek ayrim. Ayri ayri yukseklik/azimut farkindan
  /// daha dogru bir olcut: basucuna yakinda azimut farki buyur ama gercek
  /// ayrim kucuk kalir.
  double separation(ReferenceRow row, Horizontal ours) =>
      angularSeparationDegrees(
        ours.azimuthDegrees,
        ours.altitudeDegrees,
        row.expectedAzimuthDegrees,
        row.expectedAltitudeDegrees,
      );

  test('matris beklenen boyutta ve dusuk yukseklik ornegi iceriyor', () {
    expect(referenceMatrix, hasLength(45));
    // Kirilma kodunun sessizce yanlis olmadigini kanitlayan tek nokta
    // dusuk yukseklikteki orneklerdir; matris onlarsiz eksiktir.
    final low = referenceMatrix.where(
      (r) => r.expectedAltitudeDegrees > 0 && r.expectedAltitudeDegrees < 10,
    );
    expect(low, isNotEmpty, reason: '10 derece alti ornek yok');
  });

  group('45 nokta, tolerans 0.1 derece', () {
    for (final row in referenceMatrix) {
      test('$row', () {
        final ours = compute(row);
        final d = separation(row, ours);
        expect(
          d,
          lessThan(toleranceDegrees),
          reason:
              'ayrim ${(d * 3600).toStringAsFixed(1)} yay saniyesi\n'
              '  bizim   : Alt ${formatDms(ours.altitudeDegrees)} '
              'Az ${formatDms(ours.azimuthDegrees)}\n'
              '  referans: Alt ${formatDms(row.expectedAltitudeDegrees)} '
              'Az ${formatDms(row.expectedAzimuthDegrees)}',
        );
      });
    }
  });

  test('en kotu sapma toleransin cok altinda (pay raporu)', () {
    var worst = 0.0;
    ReferenceRow? worstRow;
    for (final row in referenceMatrix) {
      final d = separation(row, compute(row));
      if (d > worst) {
        worst = d;
        worstRow = row;
      }
    }

    // Kalan sapma bilerek atlanan terimlerden gelir: nutasyon (~17 yay
    // saniyesi) ve yillik aberasyon (~20). Toplami 0.01 derecenin altinda
    // kalmali. Bu esik asilirsa atlanan bir sey daha vardir.
    expect(
      worst,
      lessThan(0.02),
      reason:
          'en kotu: $worstRow -> ${(worst * 3600).toStringAsFixed(1)} yay saniyesi',
    );

    // ignore: avoid_print
    print(
      'T1.7 en kotu sapma: ${(worst * 3600).toStringAsFixed(1)} yay saniyesi '
      '(${(worst / toleranceDegrees * 100).toStringAsFixed(1)}% tolerans) — $worstRow',
    );
  });

  test('presesyon atlanirsa matris GECMEZ (testin gercekten test ettigi)', () {
    // Bu testin amaci: dogrulama matrisinin bos bir tore olmadigini
    // kanitlamak. Presesyonu cikarirsak 26 yillik kayma (~0.36 derece)
    // toleransi asmali. Asmiyorsa matris zayif demektir.
    var failures = 0;
    for (final row in referenceMatrix) {
      final utc = DateTime.parse('${row.utcIso}Z');
      final withoutPrecession = equatorialToHorizontalAt(
        equatorial: Equatorial(
          rightAscensionDegrees: row.raJ2000Degrees,
          declinationDegrees: row.decJ2000Degrees,
        ),
        observer: Observer(
          latitudeDegrees: row.latitudeDegrees,
          longitudeEastDegrees: row.longitudeEastDegrees,
        ),
        utc: utc,
      );
      if (separation(row, withoutPrecession) >= toleranceDegrees) failures++;
    }
    expect(
      failures,
      greaterThan(referenceMatrix.length ~/ 2),
      reason:
          'presesyonsuz sadece $failures/${referenceMatrix.length} nokta '
          'basarisiz — matris presesyonu yeterince zorlamiyor',
    );
  });
}
