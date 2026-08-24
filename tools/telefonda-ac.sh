#!/usr/bin/env bash
# Uygulamayi telefonda acmak icin tek komut.
#
# Derler, yerel aga servis eder ve acilacak adresi yazar. Telefon ile
# bilgisayarin AYNI Wi-Fi'da olmasi gerekiyor (veya telefonun kisisel
# erisim noktasina bagli olmak).
#
# Kullanim:  ./tools/telefonda-ac.sh
# Durdurma:  Ctrl+C

set -euo pipefail
cd "$(dirname "$0")/.."

PORT=8080
APP=apps/app

echo "==> Derleniyor (ilk sefer 1-2 dakika surebilir)..."
( cd "$APP" && flutter build web --release )

IP="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true)"
if [ -z "$IP" ]; then
  echo "! Yerel ag adresi bulunamadi. Wi-Fi acik mi?"
  echo "  Kabloyla baglisan: System Settings > Network'ten IP adresini bak."
  exit 1
fi

cat <<INFO

==> Hazir.

    Telefonun tarayicisinda su adresi ac:

        http://$IP:$PORT

    Telefon ve bilgisayar ayni agda olmali.
    Durdurmak icin Ctrl+C.

INFO

cd "$APP/build/web"
python3 -m http.server "$PORT" --bind 0.0.0.0
