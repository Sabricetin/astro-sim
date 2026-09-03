# SAHA KARTI — Faz 0.B

Tek sayfa. Ayrıntı için `saha-talimati.md`, ama gece bunu kullan.

---

## ÇANTA

☐ Makine + **EF-S 18-55** ☐ Tripod ☐ **Yedek pil** ☐ Boş kart (3.5 GB)
☐ Kırmızı fener ☐ Not defteri ☐ Telefon (GPS + saat)

---

## SAHADA İLK İŞ — bunları yaz

```
Tarih/saat  ..................
GPS (5 hane) ....... , .......   ← 0.C bunsuz yapılamaz
Rakım ....  Sıcaklık ....  Nem/çiy ....
Bulut ..............  Işık kirliliği yönü ..........
```

---

## MAKİNE — bir kez ayarla

| | |
|---|---|
| Format | **RAW** |
| Mod | **M** |
| Odak | **18 mm**, zoom halkasına **BANT** |
| Odaklama | El ile, canlı görüntü 10× zoom, Vega'ya → **BANT** |
| IS (sabitleme) | **KAPALI** |
| **Uzun Poz Parazit Azaltma** | **KAPALI** ← en kritik |
| Yüksek Işık Ton Önceliği | **KAPALI** |
| ISO | yalnız **800 / 1600 / 3200** |

---

## GECE PLANI (10 Eylül; 11'inde 4 dk, 12'sinde 8 dk erken)

| Saat | İş |
|---|---|
| 20:45 | Kurulum, GPS yaz |
| 21:00 | Odak + bant |
| 21:15 | **B ayarını bul** (aşağı bak) |
| **21:41** | B — Vega 70° |
| 22:32 | B — 60° |
| 23:24 | B — 50° |
| **00:22** | **A dizisi** (Pegasus tepede 78°) |
| 00:18 | B — 40° |
| 01:13 | B — 30° |
| 01:42 | B — 25° |
| **02:11** | B — 20° · **B bitti** |
| 02:25 | **C dizisi** (kapak takılı) |

Karanlık **04:51**'e kadar — payın bol.

---

## DİZİ B — sönüm · **f/22, 1 s, ISO 1600**

Her durakta **5 kare.** Ayarı gece boyunca **değiştirme.**

**Başlamadan ayarı doğrula:**
```
python tools/check_star.py <kare.CR2>
```
DOYMUS → pozu kısalt (1/2 s, 1/4 s) · %40–70 → **başla** · sönük → f/16

---

## DİZİ A — fon · **f/3.5, ISO 1600** · Pegasus

**A1** poz merdiveni, **palindrom**, her basamak 3 kare:
```
5 10 15 20 30 60 · 60 30 20 15 10 5
```
**A2** ISO merdiveni, 15 s sabit, 3'er kare: **800 · 1600 · 3200**

---

## DİZİ C — karanlık · gecenin **SONUNDA**

Kapak **takılı**, vizör kapalı. 3'er kare:
```
ISO 1600: 5 10 15 20 30 60 s
ISO 800: 15 s    ISO 3200: 15 s
```
Şafak sökebilir, önemi yok. **Makineyi ısıtma** — dışarıda kalsın.

---

## SESSİZCE BOZAN ŞEYLER

1. **Parazit azaltma açık** → C dizisi anlamsız
2. **Çiy** → lense yandan fener tut, kontrol et
3. **Odak/zoom kayması** → bant
4. **Yanlış ISO** → 800/1600/3200 dışı kare çöp
5. **Dizi ortasında diyafram değişimi** → o dizi geçersiz

---

## DÖNÜNCE

```
data/faz0b/A1-fon-poz/   A2-fon-iso/   B-sonum/   C-karanlik/

./.venv/bin/python tools/analyze_field_night.py \
  --root data/faz0b --lat <ENLEM> --lon <BOYLAM> --elev <RAKIM>
```

---

## BULUT ÇIKARSA

**Yarım ölçüm getirme.** A bittiyse kullanılır; **B yarım kaldıysa
çöptür** — sönüm eğrisi tam kaldıraç olmadan anlamsız.

Yedek geceler: **8–17 Eylül** arası hepsi uygun (400+ dk).
