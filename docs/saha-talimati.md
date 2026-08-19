# Saha talimatı — senin fiziksel olarak yapacağın testler

Bu belge **senin işin.** Kodla yapılamayan tek şey burada: gerçek ışığı
gerçek sensörle ölçmek. Faz 5'in radyometrisi bu ölçüm olmadan kalibre
edilemez.

İki iş var:

| İş | Nerede | Süre | Ne bekliyor |
|---|---|---|---|
| **0.A.6** Doğrusallık merdiveni | İç mekân | ~30 dk | Hiçbir şey — bugün yapabilirsin |
| **0.B** Kontrollü gökyüzü çekimi | Karanlık saha | Bir gece, ~4 saat | Açık, ay'sız gece |

---

# 0.A.6 — Doğrusallık merdiveni (iç mekân, ~30 dakika)

## Neden tekrar

İlk denemede ışık kaynağı kararsızdı. Analiz aracı bunu yakaladı ve
uyardı — sinyal, poz süresiyle orantılı artmadı. Kazanç ölçümü bundan
etkilenmedi (kazanç poz süresini bilmeyi gerektirmez), ama **doğrusallık
testi bozuldu.**

Doğrusallık şu soruyu cevaplıyor: sensör iki kat ışığa iki kat sayı ile mi
cevap veriyor? Cevap "hayır" ise foton hesabının tamamı yamuk oturur.

## Tuzak: ışık kaynağı

**Kullanma:**
- LED ampul (çoğu PWM ile kısılır — gözün görmediği hızda yanıp söner)
- Telefon/tablet ekranı (yenileme frekansı + parlaklık otomatiği)
- Floresan (50 Hz şebekeyle titrer)
- Pencereden gelen gündüz ışığı (bulut geçer)

**Kullan:**
- **Eski tip akkor (filamanlı) ampul** — termal atalet titremeyi siler.
  Elinde varsa en iyisi bu.
- Yoksa: LED paneli **beyaz bir kâğıda vurdurup** kâğıdın yansımasını
  çek, ve pozları **1/60 s'den uzun** tut. Uzun poz PWM titremesini
  ortalar.
- Işığı doğrudan lense tutma; hep bir difüzörden (beyaz kâğıt, beyaz
  tişört, buzlu cam) geçir.

## Ayarlar

| Ayar | Değer | Neden |
|---|---|---|
| Format | **RAW** | JPEG ton eğrisi uygular, ölçüm biter |
| Mod | **Manuel (M)** | Otomatik hiçbir şey olmayacak |
| ISO | **1600** (tek ISO) | Doğrusallık ISO'ya bağlı değil |
| Diyafram | Sabit, ne olursa | Merdiven boyunca **değiştirme** |
| Odak | Sonsuz veya el ile | Fark etmez, ama değiştirme |
| Yüksek Işık Ton Önceliği | **KAPALI** | Açıksa efektif kazancı değiştirir |
| Uzun Poz Parazit Azaltma | **KAPALI** | Kendi karanlık karesini çıkarır, ölçümü yok eder |
| Kararma/titreme önleme | **KAPALI** | Poz süresini kendi kafasına göre oynatır |

## Merdiven

Işığı ve diyaframı sabitle. Yalnızca **poz süresini** değiştir. Her
basamakta **2 kare**.

Hedef: en kısa pozda doyumun ~%3'ü, en uzun pozda ~%80'i. Aradaki her
basamak yaklaşık iki katı olsun:

```
1/60 s  →  1/30 s  →  1/15 s  →  1/8 s  →  1/4 s  →  1/2 s  →  1 s  →  2 s
```

**Kural: 1/250 s'den kısa poz kullanma.** Mekanik perdenin zamanlama
hatası kısa pozlarda büyür ve doğrusallık testini bozar — tam da ölçmeye
çalıştığın şeyi.

Başlamadan önce tek kare çekip kontrol et:

```bash
./.venv/bin/python tools/check_flat.py <ilk-kare.CR2>
```

"merdiven başı — buradan yukarı çık" derse doğru yerdesin. "doymuş"
derse ışığı kıs veya pozu kısalt.

## Ne zaman güvenilir

Aynı basamağın iki karesi birbirine **%1 içinde** uyuşmalı. Uyuşmuyorsa
ışık kararsız — kaynağı değiştir, tekrar et. Bu kontrolü araç kendisi
yapıyor ve uyarıyor.

---

# 0.B — Kontrollü gökyüzü çekimi (bir gece)

## Ne ölçüyoruz

Üç şeyi aynı gecede:

1. **Fon parlaklığı** — Gökyüzünün kendisi kaç ADU veriyor? Faz 5'in
   birinci çıkış kriteri bunu bağımsız ölçümle (VIIRS) %15 içinde
   tutturmak.
2. **Sönüm** — Aynı yıldız alçaldıkça ne kadar sönüyor? Hava kütlesi
   modelinin testi. **Asıl hedefin 24°'de durduğu için bu daha önemli.**
3. **Sensörün gecedeki davranışı** — karanlık akım, gerçek sıcaklıkta.

## Ne zaman — gerçek tarihler

Hesaplandı, Gaziantep için:

| Pencere | En iyi geceler | Ay |
|---|---|---|
| **Eylül** | 8–13 Eylül 2026 | %0–9 |
| **Ekim** | 7–13 Ekim 2026 | %0–9 |

10 Eylül yeni ay (%0). Karanlık pencere o gece **20:14 – 04:40 yerel**.

Ekim penceresi daha uzun (19:27–05:08) ve hava daha kararlı olur, ama
Vega alçalır. Eylül tercih edilir.

## Yanına al

- Fotoğraf makinesi, **tek bir lens** (gece boyunca değiştirmeyeceksin)
- Tripod, uzaktan kumanda veya 2 sn gecikmeli deklanşör
- **Yedek pil** (soğuk pili yer, üşüyen pil poz süresini etkilemez ama
  gecenin ortasında biter)
- Boş hafıza kartı (~80 RAW kare yer açar)
- **Termometre** veya sıcaklık kaydeden bir şey
- El feneri — **kırmızı** veya en kısık ayar
- Not defteri veya telefonda not

## Sahaya varınca — bunları yaz, sonra hatırlamazsın

```
Tarih / saat (başlangıç):
GPS koordinatı (ondalık derece, 5 hane):   ......  ......
Rakım (m):
Hava sıcaklığı (başlangıç):
Nem / çiy var mı:
Bulut durumu:
Lens ve diyafram:
Ufukta ışık kirliliği hangi yönde:
```

**GPS koordinatı zorunlu.** 0.C adımında VIIRS uydu verisinden o noktanın
fon parlaklığını çekeceğiz; koordinat yoksa karşılaştırma yapılamaz.
Telefonun harita uygulamasından ondalık derece olarak al (37.06621,
37.38334 gibi), "37°3'58" biçiminde değil.

## Makine ayarları — gece boyunca değişmeyecek

Aynı liste, 0.A.6'daki gibi. Ekstra olarak:

| Ayar | Değer | Neden |
|---|---|---|
| Odak | **El ile, canlı görüntüde 10× zoom ile parlak bir yıldıza** | Otomatik odak gecede çalışmaz |
| Görüntü sabitleme (IS) | **KAPALI** | Tripodda titreşim üretir |
| ISO | Yalnız **800, 1600, 3200** | Kazancı **yalnızca bunlar için ölçüldü**. Başka ISO'nun kazancı bilinmiyor, o kare çöp olur |

**Odağı bir kez yap, gece boyunca dokunma.** Odak halkasına yanlışlıkla
çarpmamak için bant yapıştır. Odak kaydıysa yıldız fotometrisi biter ve
bunu ancak evde fark edersin.

## Dizi A — Fon (yaklaşık 45 dakika, 23:00–00:00 arası)

**Nereye:** Pegasus karesi. 00:30'da **77° yükseklikte, azimut 200°**
(güney-güneybatı, neredeyse tepende). Uygulamayı aç, tarihi 10 Eylül'e
al, kaydırıcıyı 00:30'a getir — nereye bakacağını görürsün.

**Neden orası:** Galaktik enlem −31°, yani Samanyolu'ndan uzak. Fon
ölçümünde Samanyolu'nun difüz ışığı istemiyoruz; o Faz 6'nın konusu.
Ayrıca neredeyse başucu — ışık kirliliği gradyanı orada en zayıf.

**A1 — poz merdiveni** (ISO 1600 sabit, her basamakta 3 kare):

```
5 s  →  10 s  →  15 s  →  20 s  →  30 s  →  60 s
```

Bu, fonun poz süresiyle doğru orantılı arttığını doğrular. Artmıyorsa ya
ışık kirliliği değişiyor ya sensörde bir şey var.

**A2 — ISO merdiveni** (15 s sabit, her basamakta 3 kare):

```
ISO 800  →  ISO 1600  →  ISO 3200
```

Bu, 0.A'da ölçülen kazancın gökyüzünde de tuttuğunu doğrular. Üç ISO'nun
elektron cinsinden fon değeri **aynı çıkmalı** — çıkmıyorsa kazanç
ölçümünde sorun var.

Toplam: 18 + 9 = **27 kare**.

## Dizi B — Sönüm (gece boyunca, ~4 saat)

**Hedef: Vega.** Gecenin başında tepeye yakın, sonunda alçakta. Aynı
yıldız, aynı ayar — değişen tek şey havanın kalınlığı.

**Ayar sabit:** ISO 1600, 15 s, diyafram A dizisiyle aynı.
Her durakta **5 kare.**

| Yerel saat | Vega yüksekliği | Azimut | Hava kütlesi X |
|---|---|---|---|
| 21:30 | 70° | 283° | 1.06 |
| 22:22 | 60° | 285° | 1.16 |
| 23:14 | 50° | 289° | 1.31 |
| 00:07 | 40° | 293° | 1.55 |
| 01:03 | 30° | 298° | 2.00 |
| 01:31 | 25° | 301° | 2.36 |
| 02:01 | 20° | 304° | 2.91 |

Kaldıraç 1.06'dan 2.91'e, yani **1.84 hava kütlesi fark.** 0.25 mag/X
tipik değeriyle Vega bu aralıkta **0.46 kadir** sönmeli — rahatça
ölçülebilir bir büyüklük.

**Her durakta sıcaklığı da not et.** Karanlık akım sıcaklıkla değişir
(kabaca her 6 °C'de iki katı); gece 8–10 °C soğursa bu ölçülebilir hale
gelir.

A dizisini B'nin duraklarının arasına sıkıştırabilirsin — 23:14 ile
00:07 arasında ~40 dakika boşluk var, A dizisi oraya sığar.

Toplam: 7 × 5 = **35 kare**.

## Dizi C — Karanlık kareler (gecenin SONUNDA, ~20 dakika)

Lens kapağı takılı, vizör kapalı (Canon'da vizör perdesi vardır; yoksa
bantla). Gecenin sonunda çek ki **sıcaklık ölçüm anındakiyle aynı olsun.**

Kullandığın her ISO/poz kombinasyonu için **3'er kare**:

```
ISO 1600: 5, 10, 15, 20, 30, 60 s
ISO 800:  15 s
ISO 3200: 15 s
```

Toplam: **24 kare.** Bunlar karanlık akımı ve amp glow'u ölçer;
ışıklı karelerden çıkarılacak.

**Bitirmeden önce son sıcaklığı yaz.**

## Genel toplam: ~86 kare, ~4 saat

---

## Sessizce ölçümü bozan şeyler

Bunlar hata mesajı vermez, sadece sonucu yanlış yapar:

**1. Çiy.** Lensin önü buğulanır, sinyal düşer, sen fark etmezsin. Gece
ortasında lense el fenerini yandan tutup kontrol et. Nem varsa lens
ısıtıcısı veya arada bir kurulama şart.

**2. Uzun Poz Parazit Azaltma açık kalması.** Makine her karenin ardından
kendi karanlık karesini çekip çıkarır. Hem süreyi ikiye katlar hem de
C dizisini anlamsız kılar — çıkarılmış bir şeyi tekrar çıkaramazsın.
**En kritik ayar bu.**

**3. Odak kayması.** Bant yapıştır.

**4. Ufuk ışığı çerçeveye girmesi.** Alçak duraklarda (25°, 20°)
şehir ışığı çerçevenin kenarına girebilir. Ölçümü **karenin
merkezinden** yapacağız, ama yine de kontrol et.

**5. Vinyetleme.** Lens kenarları merkezden karanlıktır. Bu yüzden
ölçüm merkezden yapılacak — sen bir şey yapma, sadece hedefi
**ortala.**

**6. ISO'yu yanlışlıkla değiştirmek.** 0.A'da yalnız 800/1600/3200
ölçüldü. ISO 400'de çekilen kare kullanılamaz.

---

## Dönünce

Kareleri şu düzende ver:

```
data/faz0b/
  A1-fon-poz/       ISO1600_05s_1.CR2 ...
  A2-fon-iso/       ISO0800_15s_1.CR2 ...
  B-sonum/          21-30_alt70_1.CR2 ...
  C-karanlik/       dark_ISO1600_15s_1.CR2 ...
  saha-notlari.md   yukarıdaki formu doldurulmuş hâli
```

Sonra **0.C**: GPS koordinatını VIIRS'e sorup o noktanın bağımsız fon
parlaklığını çekeceğiz. Bunu ben yapacağım, senden sadece koordinat
lazım.

Sonra **0.D**: hesabın ne dediğiyle sensörün ne gördüğünü yan yana
koyacağız. Faz 5'in kalibrasyonu tam olarak bu karşılaştırmadan çıkacak.

---

## Gece iptal olursa

Bulut çıkarsa **yarım ölçüm getirme.** Eksik dizi, tam dizi gibi
görünüp analizde sessizce yanlış sonuç verir. A dizisi bittiyse o
kullanılabilir; B dizisi yarım kaldıysa çöptür — sönüm eğrisi tam
kaldıraç olmadan anlamsız.

Ekim penceresi yedek: 7–13 Ekim.
