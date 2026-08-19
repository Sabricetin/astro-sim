/// Astro poz simulatorunun hesap cekirdegi.
///
/// Bu paket saf Dart'tir; Flutter'a bagimli degildir. Boylece testleri
/// hizli calisir ve hesap kodu arayuzden bagimsiz tasinabilir.
///
/// Birim sozlesmesi — paket bastan sona bunlara uyar:
///  - Acilar disariya **derece** cinsinden verilir; radyan sadece hesabin
///    icinde yasar.
///  - Boylam **dogu pozitif** (GPS sozlesmesi, Meeus'un bati-pozitifi degil).
///  - Azimut **kuzey tabanli**, doguya artar (pusula sozlesmesi, Meeus'un
///    guney tabanlisi degil).
///  - Zaman her yerde **UTC**; yerel saat sadece arayuzde.
library;

export 'src/catalog/star_catalog.dart';
export 'src/coords/horizontal.dart';
export 'src/coords/precession.dart';
export 'src/coords/refraction.dart';
export 'src/coords/types.dart';
export 'src/math/angles.dart';
export 'src/optics/gnomonic.dart';
export 'src/time/julian_day.dart';
export 'src/time/sidereal_time.dart';
