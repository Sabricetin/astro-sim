# Astro Poz Simülatörü

**Gitmeden önce pozunu doğrula.** Konum, tarih ve kamera ayarlarını gir; o gökyüzünden ne çıkacağını fiziksel olarak öğren — çerçeveye ne sığacağını, yıldızların iz bırakıp bırakmayacağını, hedefin gürültünün üstüne çıkıp çıkmayacağını.

## Ne değil

Stellarium klonu değil. Yıldız haritası zaten var ve çözülmüş bir problem. Buradaki iş harita değil, **kestirim**: bu ekipmanla, bu gökyüzünden, bu ayarlarla çektiğinde elinde ne olacak?

Aracın çıktısı güzel bir görüntü değil, bir rapor:

> Galaktik merkez: 23° yükseklik, hava kütlesi 2.5, sönüm 0.63 mag.
> SNR ≈ 4.2. Yıldız izi 2.1 px. Fon histogramın %38'ini dolduruyor.
> Parlak yıldızlarda kırpma yok.

Sahada işe yarayan şey bu.

## Neden kestirim zor

Çünkü ışık hesabı gerçek fizik istiyor: kadirden foton akısına, atmosferik sönümden sensör kazancına, gökyüzü fon parlaklığından okuma gürültüsüne kadar zincirin her halkası doğru olmak zorunda. Bir halka uydurma sayı içeriyorsa çıktı da uydurma olur.

Bu yüzden proje, arayüz yazmadan önce **sensörü ölçmekle** başladı.

## Durum

| Faz | Konu | Durum |
|---|---|---|
| 0.A | Sensör karakterizasyonu | ✅ Bitti |
| 0.B | Kontrollü gökyüzü çekimi | ⏸ Açık gece bekliyor |
| 0.C | Bağımsız fon parlaklığı (VIIRS) | ⏸ |
| 0.D | Hesap vs gerçek karşılaştırması | ⏸ |
| 1 | Zaman ve koordinat | ✅ Bitti |
| 2 | Gökyüzü haritası | ✅ Bitti |
| 3–9 | Kamera, radyometri, ufuk, ürünleşme | ⬜ |

Ayrıntılı plan: [`yol-haritasi.md`](yol-haritasi.md)

### Faz 1 — doğrulama matrisi

5 yıldız × 3 konum × 3 zaman = 45 nokta, bağımsız bir kaynakla (astropy /
ERFA / SOFA) karşılaştırıldı. Tolerans 0.1°, **en kötü sapma 0.0075°** —
kullanılan pay %7.5.

### Faz 2 — gökyüzü haritası

8404 yıldız (BSC5), 110 Messier nesnesi, 8 takım yıldızı figürü.
Çıkış kriteri gözle doğrulandı: ekranda Orion tanınıyor.

### Ölçülmüş sensör verisi — Canon EOS 760D

Foton transfer eğrisiyle ölçüldü (uydurma değil, hesaplanmış değil — ölçülmüş):

| ISO | Kazanç (e⁻/ADU) | Okuma gürültüsü | Doyum |
|---|---|---|---|
| 800 | 0.2473 | 2.57 e⁻ | 3.292 e⁻ |
| 1600 | 0.1265 | 2.04 e⁻ | 1.683 e⁻ |
| 3200 | 0.0655 | 1.69 e⁻ | 871 e⁻ |

Üç ISO'nun taban ISO'ya götürülmüş dolum kapasitesi %5.7 içinde uyuşuyor — bağımsız ölçümlerin aynı fiziksel büyüklüğe yakınsaması. Kalan belirsizlik ve referans karşılaştırması: [`data/faz0/referans-karsilastirma.md`](data/faz0/referans-karsilastirma.md)

## Yapı

```
packages/astro_core/   saf Dart hesap çekirdeği — Flutter bağımlılığı YOK
  lib/src/time/          Julian Day, LST
  lib/src/coords/        RA/Dec ↔ Alt/Az, kırılma, presesyon
  lib/src/radiometry/    foton, gürültü, SNR        ← projenin kalbi
apps/                  Flutter arayüz (henüz boş)
tools/                 kalibrasyon ve analiz scriptleri (Python)
data/faz0/             ölçüm sonuçları (RAW kareler repoda değil)
docs/                  çekim talimatları, ajan takımı
```

Hesap kodunun Flutter'dan ayrı tutulmasının sebebi: testleri hızlı çalışsın ve arayüzden bağımsız taşınabilir olsun.

## Çalıştırma

**Dart tarafı** (hesap çekirdeği):

```bash
cd packages/astro_core
dart pub get
dart test
```

**Python tarafı** (kalibrasyon araçları):

```bash
python3 -m venv .venv
./.venv/bin/pip install rawpy numpy matplotlib
./.venv/bin/python tools/test_ptc_math.py        # araç doğrulaması
```

Kendi gövdeni ölçmek istersen: [`docs/faz0-cekim-talimati.md`](docs/faz0-cekim-talimati.md)

## Kararlar

Baştan verilip geri dönülmeyen kararlar ve gerekçeleri yol haritasında. Özet:

- **Dart / Flutter** — web + iOS + Android tek kod tabanı
- **Yale Bright Star (BSC5)** yıldız kataloğu — HYG'nin CC BY-SA share-alike yükü olmadan aynı kapsam
- **Her şey içeride UTC** — yerel saat sadece ekranda
- **Sihirli sayı yasak** — her sabitin yanında birimi ve kaynağı
- **Gnomonik projeksiyon** — normal lensin gerçek davranışı bu
- **NPF kuralı**, 500 kuralı değil — 500 piksel yoğunluğunu yok sayar

## Lisans

Henüz lisans dosyası yok; telif hakkı saklıdır. Kod okunabilir ama yeniden kullanım için izin gerekir.
