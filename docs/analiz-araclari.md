# Analiz araçları — sahadan dönünce ne çalıştıracaksın

Hepsi çekimden **önce** yazıldı ve sentetik veriyle doğrulandı. Dönünce
beklemen gerekmiyor.

## Tek komut

```bash
cd ~/Desktop/Sanal-Uzay
./.venv/bin/python tools/analyze_field_night.py \
  --root data/faz0b --lat 36.80412 --lon 34.61873 --elev 12
```

Koordinatları **sahada not ettiğin gerçek değerlerle** değiştir.

Bu komut üç aracı sırayla çalıştırır ve sonunda Faz 5'in beklediği
kalibrasyon defterini basar.

## Klasör düzeni

```
data/faz0b/
  A1-fon-poz/     poz merdiveni (palindrom)
  A2-fon-iso/     ISO merdiveni
  B-sonum/        Vega, 70°'den 20°'ye
  C-karanlik/     kapak takılı, gece sonu
```

## Araçlar tek tek ne yapıyor

| Araç | Girdi | Çıktı |
|---|---|---|
| `analyze_darks.py` | Dizi C | **I_d** — karanlık akım, e⁻/px/s |
| `analyze_sky.py` | Dizi A | **fon** e⁻/px/s + doğrusallık + ISO çapraz kontrolü |
| `analyze_extinction.py` | Dizi B | **k** — sönüm katsayısı + **FWHM** yan ürün |
| `identify_stars.py` | herhangi bir kare | **hangi yıldız hangisi** — katalogla eşleştirir |
| `analyze_field_night.py` | hepsi | hepsini tek defterde toplar |

### Yıldız tanıma niye gerekli

Fotometri bir yıldızın kaç ADU verdiğini söyler, ama sıfır noktası için
o yıldızın **gerçek kadiri** lazım. *"Kullanıcı Vega'yı ortaladı"*
varsayımı Vega doyduğunda çöküyor — o zaman başka bir yıldız ölçülüyor
ve kimliği bilinmiyor.

Bu **sıfırdan plate solve değil.** Aracın elinde zaten çok şey var:
nereye bakıldığı, ne zaman, nereden, hangi ölçekte. Bilinmeyen tek şey
**dönme açısı**. O yüzden hızlı ve güvenilir.

Tek başına da kullanılabilir:

```bash
./.venv/bin/python tools/identify_stars.py kare.CR2 \
  --ra 279.235 --dec 38.784 --focal 18 --pixel-pitch 3.72
```

Sıra tesadüf değil: karanlık akım önce ölçülür, çünkü fon hesabı onu
çıkarmak için kullanır.

## Araçların kendi sınavları

Her biri sentetik veriyle doğrulandı — bilinen bir değer konup geri
kazanılabildiği gösterildi:

```bash
./.venv/bin/python tools/test_starphot.py      # fotometri çekirdeği
./.venv/bin/python tools/test_extinction.py    # k geri kazanımı
./.venv/bin/python tools/test_field_tools.py   # I_d ve fon
./.venv/bin/python tools/test_identify.py      # yıldız tanıma
./.venv/bin/python tools/test_ptc_math.py      # kazanç
./.venv/bin/python tools/test_drift_correction.py
```

Doğrulanan değerler:

| Ölçüm | Sentetik testte hata |
|---|---|
| Sönüm katsayısı k | < 0.005 kadir/X |
| PSF FWHM | %0.02 |
| Karanlık akım | %1.2 |
| Gökyüzü fonu | %0.05 |
| Yıldız akışı | %0.3 |
| Yıldız tanıma | 14 senaryo, **0 yanlış eşleştirme** |

Gerçek gökyüzünde "doğru cevap" yok — o yüzden araçların doğruluğu
ancak burada sınanabilir.

## Araçlar neyi yakalar

Sessizce yanlış sonuç vermek yerine uyarırlar:

- Hedef **doymuş** → o kare atılır (fotometri geçersiz olurdu)
- **İnce bulut** geçmiş → sağlam uydurma (soft_l1) onu yutar, sapkın
  kare işaretlenir
- **Hava kütlesi kaldıracı** küçük → k belirsizliği büyür, uyarır
- **Uzun Poz Parazit Azaltma açık kalmış** → karanlık akım ~0 çıkar,
  yakalanır
- **Sıcak piksel** oranı yüksek → Faz 5'te maske gerektiğini söyler
- **ISO'lar arası fon ayrışıyor** → Faz 0.A'daki kazanç ölçümü
  gökyüzünde sınavı geçemedi demektir
- **Ölçülmemiş ISO** → o kare kullanılmaz, atlanır

## Bu araçların yapmadığı şey

Fon parlaklığını **kadir/arcsec²'ye çevirmezler.** O dönüşüm QE ve T
gerektirir; ikisi de henüz ölçülmedi. Araçlar aletin gördüğünü verir,
mutlak ölçek Faz 0.D'de bağlanır.

Uydurma bir dönüşüm katsayısı koymaktansa dönüşümü hiç yapmamak doğru —
projenin baştan beri kuralı bu.
