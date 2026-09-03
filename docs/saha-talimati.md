# Saha talimatı — senin fiziksel olarak yapacağın testler

> **Gece sahada bunu değil, [`saha-karti.md`](saha-karti.md)'yi kullan.**
> Burası gerekçeleri ve ayrıntıyı içeriyor; kart tek sayfa.

Bu belge **senin işin.** Kodla yapılamayan tek şey burada: gerçek ışığı
gerçek sensörle ölçmek. Faz 5'in radyometrisi bu ölçüm olmadan kalibre
edilemez.

İki iş var:

| İş | Nerede | Süre | Ne bekliyor |
|---|---|---|---|
| **0.A.6** Doğrusallık merdiveni | İç mekân | ~30 dk | Hiçbir şey — bugün yapabilirsin |
| **0.B** Kontrollü gökyüzü çekimi | Karanlık saha | Bir gece, ~4 saat | Açık, ay'sız gece |

---

# 0.A.6 — Doğrusallık merdiveni ✅ KAPANDI (22 Ağustos 2026)

Bu iş bitti, tekrar yapman gerekmiyor. Üç denemede kapandı; kayıt
`data/faz0/dogrusallik-deneme3.md` ve `docs/ilerleme.md` içinde.

Kısaca ne oldu:

| Deneme | Işık | Sonuç |
|---|---|---|
| 1 | Pencere, akşam | Üst basamak doydu, aralık %60'ta bitti |
| 2 | Pencere, akşam | Palindrom işledi, ışık 3 dk'da %16 düştü |
| 3 | **Gece, oda LED'i** | ✅ doğrusalsızlık saptanmadı |

Yol boyunca **bir araç hatası** bulundu: `sensor_ptc.py`, EXIF'teki
*gösterilen* poz süresini kullanıyordu ("0.4 s") ama makinenin gerçek
süresi farklı (0.3856 s). Düzeltildi.

Sonuç: sensör %2 içinde doğrusal. Kesin doğrulama, gökyüzünde
**Dizi A** ile yapılacak (aşağıda) — astronomik karanlıkta gökyüzü oda
LED'inden çok daha kararlı bir ışık kaynağı.

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

## Konum — Mersin Akdeniz

Planlama için kullanılan koordinat:

```
Enlem  36.80° K
Boylam 34.62° D
Rakım  ~10 m (sahil)
```

Bu, Akdeniz ilçe merkezinin kabaca ortası. **Planlama için yeterli** —
birkaç kilometre kayma yıldız yüksekliğini 0.05°'den az değiştirir.

Ama **0.C için yetmez.** VIIRS sorgusu, kameranın gerçekten durduğu
noktanın koordinatını ister; ışık kirliliği birkaç kilometrede kat kat
değişir. Sahaya varınca telefonundan **ondalık derece, 5 hane** olarak al
(`36.80412, 34.61873` gibi — `36°48'15"` biçiminde değil).

### Şehirden çıkmak şart mı

Şart değil, ama ölçümü belirgin iyileştirir. Akdeniz ilçesi şehir
merkezi — fon büyük ölçüde şehir ışığı olur. Ölçüm yine **geçerlidir**
(zaten hesabın gerçekle uyuşup uyuşmadığını test ediyoruz, karanlık
gökyüzü aramıyoruz), ama iki sorun çıkar:

1. Fon çok parlaksa yıldız sinyali gürültüde kalır, sönüm ölçümü zorlaşır.
2. Şehir ışığı **yöne göre** değişir; çerçevenin bir kenarı diğerinden
   parlak olur ve ölçüme gradyan karışır.

Toroslar'a doğru 30–45 dakika kuzeye çıkabilirsen ikisi de büyük ölçüde
düzelir. Çıkamıyorsan yine çek — **yarım ölçüm değil, sadece daha parlak
fonda bir ölçüm.** Bu kabul edilebilir; VIIRS de o parlaklığı görecek.

## Ne zaman — gerçek tarihler

Mersin için hesaplandı. Kritik olan Ay'ın yüzdesi değil, **gerçekten
ay'sız ve karanlık geçen süre** (Güneş −18°'nin altında *ve* Ay ufkun
altında).

### 8–13 Eylül 2026 — hedef pencere bu

| Gece | Ay | Ay'sız karanlık | Süre |
|---|---|---|---|
| 6/7 Eylül | %22 | 20:31 – 01:37 | 306 dk |
| 7/8 Eylül | %13 | 20:30 – 02:52 | 382 dk |
| **8/9 Eylül** | %6 | 20:29 – 04:06 | 457 dk |
| **9/10 Eylül** | %2 | 20:26 – 04:50 | 504 dk |
| **10/11 Eylül** | **%0** | **20:25 – 04:52** | **506 dk** |
| **11/12 Eylül** | %1 | 20:24 – 04:52 | 508 dk |
| **12/13 Eylül** | %4 | 20:21 – 04:53 | 512 dk |
| 13/14 Eylül | %9 | 20:20 – 04:54 | 514 dk |

10 Eylül yeni ay. Kalın yazılan dört gece de rahat rahat yetiyor —
hangisinde hava açıksa o.

### Yedek: 7–13 Ekim 2026

Aynı şekilde ay'sız. Vega Ekim'de daha erken alçalır, yani Dizi B'nin
duraklarını daha erken yakalarsın. Eylül kaçarsa buradan devam.

## Yanına al

- Fotoğraf makinesi ve **EF-S 18-55mm** kit lens — gece boyunca
  **18 mm**'de kalacak, zoom halkasına da bant yapıştır
- Tripod, uzaktan kumanda veya 2 sn gecikmeli deklanşör
- **Yedek pil** (soğuk pili yer, üşüyen pil poz süresini etkilemez ama
  gecenin ortasında biter)
- Boş hafıza kartı (**~92 RAW kare ≈ 3.5 GB**)
- ~~Termometre~~ **gerekmiyor** — aşağıdaki nota bak
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

## Sıcaklık: termometre gerekmiyor

Canon her karenin EXIF'ine **sensör sıcaklığını** yazıyor. Senin 0.A
karelerinde kontrol ettim, orada duruyor ve kare kare değişiyor
(çekim boyunca 30 °C'den 32 °C'ye çıkmış — makine ısınıyor).

```bash
exiftool -s3 -CameraTemperature IMG_1234.CR2
# 32 C
```

Bu **hava sıcaklığından daha iyi** bir veri: karanlık akımı belirleyen şey
havanın değil, sensörün sıcaklığı. Termometre alsan bile yanlış şeyi
ölçmüş olurdun.

Bütün geceyi tek komutla dökmek için:

```bash
exiftool -T -FileName -CameraTemperature -ISO -ExposureTime *.CR2
```

**Senden istenen tek şey:** makineyi çekim arasında çantaya sokup
ısıtma. Dışarıda bırak ki ortam sıcaklığına gelsin.

**GPS koordinatı zorunlu.** 0.C adımında VIIRS uydu verisinden o noktanın
fon parlaklığını çekeceğiz; koordinat yoksa karşılaştırma yapılamaz.
Telefonun harita uygulamasından ondalık derece olarak al (37.06621,
37.38334 gibi), "37°3'58" biçiminde değil.

## Ekipman — senin gerçek donanımın

Bu plan **Canon EOS 760D + EF-S 18-55mm f/3.5-5.6** için hesaplandı.
Başka lens varsayımı yok.

| | |
|---|---|
| Odak | **18 mm** (gece boyunca sabit) |
| Kadraj | 63.6° × 45.0° |
| Ölçek | 42.6″/piksel |
| En açık diyafram (18 mm'de) | f/3.5 |
| NPF sınırı (f/3.5, 18 mm) | ~13–17 s |

**Zoom halkasına da bant yapıştır.** 18 mm'den kayarsa ölçek değişir ve
bütün hesap kayar — bunu ancak evde fark edersin.

## Makine ayarları

Aynı liste, 0.A.6'daki gibi. Ekstra olarak:

| Ayar | Değer | Neden |
|---|---|---|
| Odak | **El ile, canlı görüntüde 10× zoom ile parlak bir yıldıza** | Otomatik odak gecede çalışmaz |
| Görüntü sabitleme (IS) | **KAPALI** | Tripodda titreşim üretir |
| ISO | Yalnız **800, 1600, 3200** | Kazancı **yalnızca bunlar için ölçüldü**. Başka ISO'nun kazancı bilinmiyor, o kare çöp olur |

**Odağı bir kez yap, gece boyunca dokunma.** Odak halkasına yanlışlıkla
çarpmamak için bant yapıştır. Odak kaydıysa yıldız fotometrisi biter ve
bunu ancak evde fark edersin.

### Neyin sabit kaldığı, neyin değiştiği

| | |
|---|---|
| **Gece boyunca sabit** | lens, odak, IS kapalı, parazit azaltma kapalı |
| **Diziye göre değişir** | **diyafram**, poz süresi, ISO |

Dizi B **f/22**'de çekilir (parlak yıldız doymasın diye), Dizi A
**f/3.5**'te. Bu **kasıtlı** ve araçlar bunu biliyor:
sıfır noktası bir diyaframdan diğerine matematiksel olarak taşınıyor
(`ZP(N) = ZP_ref + 5·log10(N_ref/N)`).

Senden istenen tek şey: **hangi dizinin hangi diyaframla çekildiği
EXIF'te doğru olsun** — otomatik oluyor, sen bir şey yapma. Sadece bir
dizinin *ortasında* diyaframı değiştirme; araçlar o durumda sonucu
geçersiz sayar ve uyarır.

## Dizi A — Fon (~20 dakika)

**Nereye:** Pegasus karesi. Mersin'den o gecenin en tepe anında:

| En iyi an | Yükseklik | Azimut |
|---|---|---|
| **00:00 – 00:45** | 78° | güney, neredeyse tam tepende |

10 Eylül'de en tepe an **00:22**, azimut 180° (tam güney).

**Neden orası:** Galaktik enlem −31°, yani Samanyolu'ndan uzak. Fon
ölçümünde difüz galaktik ışık istemiyoruz; o Faz 6'nın konusu. Ayrıca
neredeyse başucu — ışık kirliliği gradyanı orada en zayıf. Mersin gibi
sahil şehrinde bu ekstra önemli: alçak baktığın her yön şehir veya deniz
üstü ışığı taşır.

**Ayar:** 18 mm, **f/3.5** (sonuna kadar açık), ISO 1600.

**A1 — poz merdiveni** (ISO 1600 sabit, her basamakta 3 kare):

```
5 s  →  10 s  →  15 s  →  20 s  →  30 s  →  60 s
```

Fonun poz süresiyle doğru orantılı arttığını doğrular.

> **A1'in ikinci görevi: doğrusallık.** Bu merdiven aynı zamanda 0.A.6'nın
> laboratuvar testinin yerini alıyor. Astronomik karanlıkta gökyüzü, oda
> LED'inden çok daha kararlı bir kaynak; üstelik ölçüm asıl kullanılacak
> sinyal seviyelerinde ve asıl poz sürelerinde yapılmış oluyor.
>
> **Bu yüzden A1'i palindrom sırada çek:**
> `5 10 15 20 30 60 · 60 30 20 15 10 5`
> 27 yerine 33 kare olur, ama karşılığında gökyüzü fonunun gece boyunca
> ne kadar kaydığını da ölçmüş olursun.

**A2 — ISO merdiveni** (15 s sabit, her basamakta 3 kare):

```
ISO 800  →  ISO 1600  →  ISO 3200
```

0.A'da ölçülen kazancın gökyüzünde de tuttuğunu doğrular. Üç ISO'nun
**elektron cinsinden** fon değeri aynı çıkmalı — çıkmıyorsa kazanç
ölçümünde sorun var.

Toplam: 24 + 9 = **33 kare**, poz süresi toplamı ~15 dakika.

## Dizi B — Sönüm (gece boyunca, ~4 saat)

**Hedef: Vega.** Gecenin başında yüksekte, sonunda alçakta. Aynı yıldız,
aynı ayar — değişen tek şey havanın kalınlığı.

### ⚠️ Bu dizi FARKLI ayarla çekilir

Dizi A'nın ayarını buraya taşıma. Sebebi hesaplandı:

> **Vega, 18 mm f/3.5 15 s ISO 1600'de dolum kapasitesini kat kat aşıyor.**

Doymuş yıldızın fotometrisi anlamsızdır — sinyali artmaz, o yüzden
sönüm hiç ölçülemez. Planlanan ayarla çekseydin Dizi B'nin **tek bir
karesi bile kullanılamazdı.**

Geniş açıda bu sezgiye aykırı: 18 mm'de ölçek 42.6″/piksel, yani yıldızın
tüm ışığı bir-iki piksele iniyor. Teleskopta yayılan ışık burada
yığılıyor.

### Ayarı sen bulacaksın — tahmin yok

Diyaframı kısıp pozu kısaltacaksın, ama ne kadar? QE ve T henüz
ölçülmediği için hesap ±2 kat belirsiz. O yüzden ölçerek bul:

1. Vega'yı ortala, odağı yap.
2. **f/22, 1 s, ISO 1600** ile tek kare çek.
3. Sor:
   ```bash
   ./.venv/bin/python tools/check_star.py <kare.CR2>
   ```

| Sonuç | Yap |
|---|---|
| DOYMUS | pozu kısalt (1/2 s, sonra 1/4 s) |
| %40–70 | **tamam, diziye başla** |
| çok sönük | f/16'ya aç |

Hesap f/22 ve 1 s'de tepe pikselin dolumun **%69**'unda kalacağını
söylüyor — tam hedefte. Ama QE ve T henüz ölçülmediği için tahmin
±2 kat belirsiz; o yüzden ölçerek doğruluyorsun.

**Neden f/22 gibi çok kısık bir diyafram:** Vega parlak, geniş açı
ışığı tek piksele yığıyor ve sensörün kapasitesi küçük. Kısmaktan başka
yol yok. Bu dizi *fotoğraf* değil *ölçüm* — görüntü kalitesi önemsiz.

Bulduğun ayarı **gece boyunca değiştirme** — sönüm ölçümü akış
*oranlarına* bakıyor, sabit bir ayar tüm sistematikleri götürüyor.

### Yine de doyarsa

Analiz aracı en parlak yıldız doymuşsa **bir sonraki sıraya geçiyor**
ve aynı fiziksel yıldızı tüm karelerde takip ediyor (bağıl parlaklık
sırası kare kare değişmez). Yani tek bir parlak yıldızın doyması gecenizi
bitirmez — ama merkezdeki yıldızların *hepsi* doyarsa hiçbir şey
yapamaz.

### FWHM buradan değil, Dizi A'dan

Kısılmış diyaframda yıldız haksız yere keskin çıkar. Faz 5'in istediği
PSF genişliği **asıl çekim diyaframındaki** değer, yani Dizi A'nın.
Araçlar bunu kendileri hallediyor; senin bir şey yapman gerekmiyor.

Her durakta **5 kare.**

### Durak çizelgesi — 10/11 Eylül gecesi (Mersin)

| Yerel saat | Vega yüksekliği | Azimut | Hava kütlesi X |
|---|---|---|---|
| 21:41 | 70° | 283° | 1.06 |
| 22:32 | 60° | 286° | 1.15 |
| 23:24 | 50° | 289° | 1.30 |
| 00:18 | 40° | 293° | 1.56 |
| 01:13 | 30° | 298° | 2.00 |
| 01:42 | 25° | 301° | 2.37 |
| 02:11 | 20° | 304° | 2.91 |

Kaldıraç **1.06 → 2.91**, yani 1.85 hava kütlesi. Ölçmeye çalıştığımız
sönüm bu aralıkta yaklaşık **0.5 kadir** — rahatça görülebilir bir fark.

Başka bir gece seçersen çizelge kayar; uygulamadan okuyabilirsin
(hedefi Vega yap, tarihi seç, kaydırıcıyı oynat).

**Neden bu dizi en kıymetlisi:** Asıl hedefin (galaktik merkez) 24°'de
duruyor, yani hava kütlesi ~2.4. Sadece tepe civarında kalibre edilmiş
bir model orada sessizce yanılır. Bu dizi tam o bölgeyi ölçüyor.

Toplam: 7 × 5 = **35 kare**.

### Dizi B ayar özeti

| | |
|---|---|
| Odak | **18 mm** |
| Diyafram | **f/22** (ölçerek doğrula) |
| Poz | **1 s** |
| ISO | 1600 |
| Her durakta | 5 kare |

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

**Karanlık kareler karanlık gökyüzü istemez** — kapak takılı olduğu için
şafak sökerken bile çekebilirsin. Ay'sız pencereyi bunlara harcama;
04:30'dan sonra rahat rahat çek. Tek şart: makine hâlâ dışarıda ve aynı
sıcaklıkta olsun, çantaya sokup ısıtma.

## Gecenin dakika dakika planı (10/11 Eylül örneği)

| Saat | İş |
|---|---|
| 20:45 | Sahada ol. Kurulum. GPS koordinatını yaz. |
| 21:00 | **Odak**: canlı görüntü, 10× zoom, Vega'ya. Odak halkasına bant. |
| 21:15 | Dizi B ayarını bul: **f/22, 1 s** tek kare → `check_star.py` → %40–70 olana kadar pozu oynat. |
| **21:41** | **B başlar:** Vega 70°, 5 kare |
| 22:32 | B — Vega 60°, 5 kare |
| 23:24 | B — Vega 50°, 5 kare |
| **00:00** | **A dizisi** — Pegasus tepede (78°). Ayarı A'ya çevir: **f/3.5**, ISO 1600. 33 kare, ~15 dk |
| 00:18 | B — Vega 40°, 5 kare (ayarı B'ye geri al) |
| 01:13 | B — Vega 30°, 5 kare |
| 01:42 | B — Vega 25°, 5 kare |
| **02:11** | B — Vega 20°, 5 kare. **B bitti.** |
| 02:25 | **C dizisi** — kapak tak, 24 karanlık kare. ~20 dk |
| 02:50 | Toparlan. Son kareyi çekmeden makineyi ısıtma. |

Toplam **~92 kare**, ~6 saat saha. Karanlık 04:52'ye kadar sürüyor,
yani bol payın var.

**Dikkat:** Dizi A ve Dizi B **farklı diyaframla** çekiliyor. Geçişlerde
ayarı değiştirmeyi unutma — ama Dizi B'nin ayarını her seferinde
**aynı** değere döndür.

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

**Analiz hazır — beklemeyeceksin.** Tek komut:

```bash
./.venv/bin/python tools/analyze_field_night.py \
  --root data/faz0b --lat <ENLEM> --lon <BOYLAM> --elev <RAKIM>
```

Ayrıntı: [`analiz-araclari.md`](analiz-araclari.md)

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

Ekim penceresi yedek: 7–13 Ekim 2026.
