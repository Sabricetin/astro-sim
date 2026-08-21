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

### Üç kural (1. denemede üçü de ihlal edildi)

**1. En üst basamak doyuma DEĞMESİN, %85'te dursun.**
Doymuş kare doğrusalsızlık değil kırpma gösterir ve ölçümü bozar.

**2. Merdiven %60'ta bitmesin — asıl iş %60 ile %90 arasında.**
Doğrusalsızlık orada ortaya çıkar. Aşağıda temiz çıkması bir şey
kanıtlamaz.

**3. En kısa poz 1/4 s'den kısa olmasın.**
Kısa pozlarda perdenin zamanlama hatası ölçüme karışır. 1. denemede
1/15 ile 1/8 arasında %5.1'lik bir basamak çıktı ve kaynağı ayırt
edilemedi.

### Diyaframı poza göre seç, tersini değil

Merdiveni uzun pozlara oturtmak için ışığı kısman gerekiyor. En kolay
yol diyafram. Yöntem:

1. Planladığın **en uzun pozu** (2 s) çek.
2. Kontrol et:
   ```bash
   ./.venv/bin/python tools/check_flat.py <kare.CR2>
   ```
3. %85 civarıysa tamam. Yüksekse bir durak kıs, düşükse bir durak aç.

1. denemenin ışığında bu **f/16** ediyordu (f/14'ten bir 1/3 durak).

### Basamaklar

```
1/4 s → 0.4 s → 0.6 s → 0.8 s → 1 s → 1.3 s → 1.6 s → 2 s
```

Sekiz basamak, kabaca %11'den %90'a. Üstte adımlar sıklaşıyor —
doğrusalsızlığın aranacağı yer orası.

### Sırayı palindrom yap

Kareleri şu sırayla çek:

```
1/4  0.4  0.6  0.8  1  1.3  1.6  2   2  1.6  1.3  1  0.8  0.6  0.4  1/4
```

Yani merdiveni bir çık, bir in. Her basamağın iki karesi dizinin iki
ucuna düşer.

**Neden:** Böylece bir basamağın iki karesi arasındaki fark, doğrudan
**ışığın tüm çekim boyunca ne kadar kaydığını** ölçer. Ardışık çekilmiş
iki kare yalnızca o anki kararlılığı gösterir — 1. denemede tam olarak
bu yüzden ışık "kararlı" göründü ama diziler arasında %5 kayma vardı.

Ayrıca bu sıra Bulgu 3'ü de çözer: basamak poz süresini takip ediyorsa
perde, saati takip ediyorsa ışık.

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

### Ağustos — bir tek gece var, o da bu gece

| Gece | Ay | Ay'sız karanlık | Süre |
|---|---|---|---|
| **20/21 Ağustos** | %58 | **23:30 – 04:29** | **299 dk** ✅ |
| 21/22 Ağustos | %67 | 00:14 – 04:30 | 256 dk — sadece A dizisi |
| 22/23 Ağustos | %76 | 01:06 – 04:31 | 205 dk — sadece A dizisi |
| 23 Ağustos – 5 Eylül | %83–100 | yok veya çok kısa | ❌ |

Ay bu gece 23:30'da batıyor ve şafağa kadar geri gelmiyor. **299 dakika
üç dizinin tamamına yetiyor.**

26–31 Ağustos arası hiç ay'sız karanlık yok — dolunay 27 Ağustos.

### Eylül — rahat pencere

| Gece | Ay | Ay'sız karanlık | Süre |
|---|---|---|---|
| 6/7 Eylül | %22 | 20:31 – 01:37 | 306 dk |
| 7/8 Eylül | %13 | 20:30 – 02:52 | 382 dk |
| **8–13 Eylül** | %0–9 | **20:2x – 04:5x** | **457–514 dk** ✅✅ |

10 Eylül yeni ay.

### Hangisi

**Bu gece gidebilecek durumdaysan git.** 299 dakika yetiyor, üç dizi de
sığıyor ve ölçüm üç hafta erken biter — Faz 5 iskeleti kalibrasyonsuz
beklemek yerine hemen bağlanır.

**Hazır değilsen zorlama.** İlk saha çekimini gece yarısı aceleyle
yapmak, sabaha karşı "şu ayarı unuttum" demenin en kısa yolu. 8–13 Eylül
sana 8+ saat veriyor, yani hata yapıp tekrar etme payı var. Sadece üç
hafta.

Ara yol: **bu gece prova yap.** Kurulumu kur, odağı yap, birkaç deneme
karesi çek, `check_flat.py`'ye sor. Eylül'de asıl çekime hazır gidersin.

## Yanına al

- Fotoğraf makinesi, **tek bir lens** (gece boyunca değiştirmeyeceksin)
- Tripod, uzaktan kumanda veya 2 sn gecikmeli deklanşör
- **Yedek pil** (soğuk pili yer, üşüyen pil poz süresini etkilemez ama
  gecenin ortasında biter)
- Boş hafıza kartı (~80 RAW kare yer açar)
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

## Dizi A — Fon (~20 dakika)

**Nereye:** Pegasus karesi. Mersin'den o gecenin en tepe anında:

| Gece | En iyi an | Yükseklik | Azimut |
|---|---|---|---|
| 20/21 Ağustos | **01:30 – 02:00** | 78° | 164° → 197° (güney, tepende) |
| 8–13 Eylül | **00:00 – 00:30** | 77° | 170° → 200° |

**Neden orası:** Galaktik enlem −31°, yani Samanyolu'ndan uzak. Fon
ölçümünde difüz galaktik ışık istemiyoruz; o Faz 6'nın konusu. Ayrıca
neredeyse başucu — ışık kirliliği gradyanı orada en zayıf. Mersin gibi
sahil şehrinde bu ekstra önemli: alçak baktığın her yön şehir veya deniz
üstü ışığı taşır.

**A1 — poz merdiveni** (ISO 1600 sabit, her basamakta 3 kare):

```
5 s  →  10 s  →  15 s  →  20 s  →  30 s  →  60 s
```

Fonun poz süresiyle doğru orantılı arttığını doğrular.

**A2 — ISO merdiveni** (15 s sabit, her basamakta 3 kare):

```
ISO 800  →  ISO 1600  →  ISO 3200
```

0.A'da ölçülen kazancın gökyüzünde de tuttuğunu doğrular. Üç ISO'nun
**elektron cinsinden** fon değeri aynı çıkmalı — çıkmıyorsa kazanç
ölçümünde sorun var.

Toplam: 18 + 9 = **27 kare**, poz süresi toplamı ~10 dakika.

## Dizi B — Sönüm (gece boyunca, ~4 saat)

**Hedef: Vega.** Gecenin başında yüksekte, sonunda alçakta. Aynı yıldız,
aynı ayar — değişen tek şey havanın kalınlığı.

**Ayar sabit:** ISO 1600, 15 s, diyafram A dizisiyle aynı.
Her durakta **5 kare.**

### 20/21 Ağustos gecesi (Mersin)

| Yerel saat | Vega yüksekliği | Azimut | Hava kütlesi X |
|---|---|---|---|
| 23:30 | 65° | 284° | 1.11 |
| 00:00 | 59° | 286° | 1.17 |
| 00:30 | 53° | 288° | 1.25 |
| 01:00 | 47° | 290° | 1.36 |
| 02:00 | 36° | 295° | 1.69 |
| 02:30 | 31° | 298° | 1.94 |
| 03:30 | 21° | 304° | 2.83 |

Kaldıraç **1.11 → 2.83**, yani 1.72 hava kütlesi. 0.25 mag/X ile Vega bu
aralıkta **0.43 kadir** sönmeli.

01:30 durağını atladım — orası A dizisine ayrıldı (Pegasus tam tepede).

### 8–13 Eylül geceleri (Mersin)

Eylül'de Vega daha erken yükselir; gece başında 70°'nin üstünde bulursun
ve 20°'ye kadar takip edecek bol vaktin olur. Kaldıraç ~1.06 → 2.90
(1.84 hava kütlesi, **0.46 kadir**). Çizelgeyi uygulamadan okuyabilirsin:
hedefi Vega yap, tarihi seç, kaydırıcıyı oynat.

**Neden bu dizi en kıymetlisi:** Asıl hedefin (galaktik merkez) 24°'de
duruyor, yani hava kütlesi ~2.4. Sadece tepe civarında kalibre edilmiş
bir model orada sessizce yanılır. Bu dizi tam o bölgeyi ölçüyor.

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

**Karanlık kareler karanlık gökyüzü istemez** — kapak takılı olduğu için
şafak sökerken bile çekebilirsin. Ay'sız pencereyi bunlara harcama;
04:30'dan sonra rahat rahat çek. Tek şart: makine hâlâ dışarıda ve aynı
sıcaklıkta olsun, çantaya sokup ısıtma.

## Bu gecenin (20/21 Ağustos) dakika dakika planı

| Saat | İş |
|---|---|
| 22:30 | Sahada ol. Kurulum, makine ayarları, **odak** (canlı görüntü 10× zoom, Vega'ya). Odak halkasına bant. |
| 23:00 | Deneme karesi çek, histograma bak. Ay hâlâ batmakta — bu kare ölçüm değil, kontrol. |
| **23:30** | **Ay battı. B dizisi başlıyor:** Vega 65°, 5 kare. |
| 00:00 | B — Vega 59°, 5 kare |
| 00:30 | B — Vega 53°, 5 kare |
| 01:00 | B — Vega 47°, 5 kare |
| 01:30 | **A dizisi** — Pegasus tepede (78°). A1 + A2, 27 kare, ~20 dk |
| 02:00 | B — Vega 36°, 5 kare |
| 02:30 | B — Vega 31°, 5 kare |
| 03:30 | B — Vega 21°, 5 kare. **B bitti.** |
| 03:45 | **C dizisi** — kapak tak, 24 karanlık kare. Şafak sökebilir, önemi yok. |
| 04:30 | Toparlan. Son kareyi çekmeden makineyi ısıtma. |

Toplam **~86 kare**, ~5 saat saha.

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
