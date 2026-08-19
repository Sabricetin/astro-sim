/// Astro poz simulatorunun hesap cekirdegi.
///
/// Bu paket saf Dart'tir; Flutter'a bagimli degildir. Boylece testleri
/// hizli calisir ve hesap kodu arayuzden bagimsiz tasinabilir.
///
/// Birim sozlesmesi:
///  - Acilar disariya **derece** cinsinden verilir; radyan sadece hesabin
///    icinde yasar.
///  - Boylam **dogu pozitif**.
///  - Zaman her yerde **UTC**; yerel saat sadece arayuzde.
library;

export 'src/math/angles.dart';
export 'src/time/julian_day.dart';
export 'src/time/sidereal_time.dart';
