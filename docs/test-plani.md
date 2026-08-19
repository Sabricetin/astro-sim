# Uygulama test planı — Faz 2, 3 ve 4

Bu belge, kodda test edilemeyen şeyler içindir: **ekranda doğru görünüyor mu.**

Sahada yapılacak *fiziksel* ölçümler ayrı bir belgede:
[`docs/saha-talimati.md`](saha-talimati.md) — özeti aşağıda D bölümünde.
Otomatik testler matematiğin doğruluğunu kanıtlıyor (317 test); buradaki
maddeler o matematiğin doğru bağlandığını ve arayüzün anlaşılır olduğunu
kontrol eder.

Her maddede **ne yapacağın**, **ne görmen gerektiği** ve **tutmazsa ne
anlama geldiği** var. Tutmayan bir madde olursa numarasını söyle yeter.

```bash
cd ~/Desktop/Sanal-Uzay/apps/app
flutter run -d macos
```

---

## A. Gökyüzü haritası (Faz 2)

### A1 — Orion tanınıyor
**Yap:** Üstteki **Orion** düğmesine bas.
**Bekle:** Ortada dikey sıralanmış üç yıldız (kuşak) ve onları çevreleyen
kum saati figürü. Sol üstte Betelgeuse, sağ altta Rigel etiketi.
**Tutmazsa:** Projeksiyon veya koordinat zincirinde hata var — bu, 45
doğrulama testinin yakalayamadığı bir bağlantı hatası olurdu.

### A2 — Çizgiler gerçekten yıldızları birleştiriyor
**Yap:** *Takım yıldızı çizgileri* anahtarını kapat, sonra aç.
**Bekle:** Çizgiler tam olarak yıldızların üzerinden geçiyor, boşluğa
gitmiyor.
**Tutmazsa:** HR numarası eşleşmesi bozuk.

### A3 — Yön göstergeleri doğru
**Yap:** Orion görünümündeyken ufuk çizgisine bak.
**Bekle:** Orion'un altında **G** (güney) yazıyor. Orion kış takımyıldızı,
Türkiye'den güneyde görünür.
**Tutmazsa:** Azimut sözleşmesi ters bağlanmış (kuzey/güney 180° kaymış).

### A4 — Büyük Ayı
**Yap:** **Büyük Ayı** düğmesi.
**Bekle:** Klasik kepçe: dört yıldızlı gövde + üç yıldızlı sap. Ufuk
çizgisinde **K** (kuzey) görünüyor.

---

## B. Kamera ve kadraj (Faz 3)

### B1 — Yol haritasının çıkış kriteri
**Yap:** **Orion** düğmesi → alt panel **Kamera** → Gövde: **Sony A7 III**
(tam kare), Odak: **14 mm**.
**Bekle:** Orion figürünün tamamı çerçeve kutusunun içinde, bol boşlukla.
**Tutmazsa:** FOV hesabı yanlış.

### B2 — Uzun odak çerçeveyi daraltıyor
**Yap:** Odağı **50 mm** yap.
**Bekle:** Kutu belirgin şekilde küçülüyor, Orion artık sığmıyor. Panelde
kadraj **39.6° × 27.0°** civarı yazıyor.

### B3 — Kırpma çarpanı gerçek
**Yap:** Odak 50 mm sabitken gövdeyi **Sony A7 III** → **Canon EOS 760D**
yap.
**Bekle:** Kutu küçülüyor. Panelde kırpma **1.61x** yazıyor ve kadraj
**25.4°** civarına düşüyor.
**Tutmazsa:** Canon APS-C ile diğer APS-C birbirine karışmış.

### B4 — Dikey çevirme
**Yap:** *Dikey* anahtarını aç.
**Bekle:** Kutu 90° dönüyor — genişlik ve yükseklik yer değiştiriyor.

### B5 — NPF sınırı ve renk kodu
**Yap:** Gövde **Canon EOS 760D**, odak **14 mm**, diyafram **f/2.8**.
Panelde `NPF ~15.0 s` yazmalı. Poz kaydırıcısını sırayla **10 s**, **18 s**,
**30 s** yap.
**Bekle:**

| Poz | Gösterge | İz |
|---|---|---|
| 10 s | 🟢 yeşil, "Yıldızlar noktasal" | ~2.7 px |
| 18 s | 🟠 turuncu, "Hafif iz" | ~4.9 px |
| 30 s | 🔴 kırmızı, "Belirgin iz" | ~8.2 px |

**Tutmazsa:** NPF veya iz hesabı bozuk.

### B6 — 500 kuralının iyimserliği
**Yap:** Aynı ayarda panele bak.
**Bekle:** `500 kurali 36 s derdi` yazıyor — NPF'nin iki katından fazla.
Bu, yol haritasının "500 kuralı yalan söyler" iddiasının ekrandaki hali.

### B7 — Diyafram ve odak etkisi
**Yap:** Diyaframı **f/1.4** yap, sonra **f/5.6**.
**Bekle:** f/1.4'te NPF kısalıyor (~11 s), f/5.6'da uzuyor (~22 s).

---

## C. Zaman ve plan (Faz 4)

> **Önce şunu bil:** Kaydırıcıyı oynattığında **Plan panelindeki pencere ve
> Ay yüzdesi DEĞİŞMEZ.** Bu doğru davranış — pencere *gecenin* özelliği,
> anın değil. Değişmesi gereken tek yer **"şu an"** satırı ve grafikteki
> dikey imleç.

### Grafiği okumak (önce bunu oku, C6 buna dayanıyor)

Grafik dört şeyi üst üste bindiriyor. Soldan sağa akan eksen zaman:

| Ne | Anlamı |
|---|---|
| **Mavi eğri** | Hedefin yüksekliği. Tepe noktası o gecenin en iyi anı. |
| **Koyu mavi bant** | Gökyüzünün gerçekten karanlık olduğu saatler (Güneş −18°'nin altında). Alacakaranlık bu bandın dışında kalır. |
| **Yeşil bant** | Çekim penceresi. |
| **Yeşil yatay çizgi** | 20° eşiği — altında hava kütlesi 3'ü aşar. |
| **Turuncu eğri** | Ay'ın yüksekliği. |
| **Beyaz dikey çizgi** | Kaydırıcının bulunduğu an. |

### C1 — Zaman kaydırıcısı gökyüzünü döndürüyor
**Yap:** Alt paneldeki kaydırıcıyı sürükle.
**Bekle:** Yıldızlar dönüyor, akıcı — takılma yok.

### C2 — "Şu an" göstergesi kaydırıcıyı takip ediyor
**Yap:** Alt panelde **Plan** sekmesine geç. Kaydırıcıyı oynat.
**Bekle:** Üç şey **birlikte** değişiyor:
- Grafikteki **beyaz dikey çizgi** kayıyor
- Mavi eğri üzerindeki **nokta** yukarı/aşağı gidiyor
- "**şu an**" satırındaki hedef yüksekliği, Ay yüksekliği ve ceza değişiyor

### C3 — Pencere değişmiyor (doğru davranış)
**Yap:** Kaydırıcıyı gece boyunca oynat.
**Bekle:** Üstteki `Pencere ...` satırı **sabit kalıyor.** Gece boyunca
pencere aynı penceredir.

---

> **C4'ten C8'e kadar tarihi 15 Temmuz 2026'da tut.** Tarihe tıklayınca
> takvim açılıyor; oradan seç. Hedefleri değiştirerek ilerleyeceğiz,
> böylece karşılaştırma adil olur: aynı gece, farklı hedef.

### C4 — Galaktik merkez 24°'yi geçmiyor
**Yap:** Tarih **15 Temmuz 2026**, hedef **Galaktik merkez**.
**Bekle:** Mavi eğrinin tepesi **23.9°** — yeşil 20° çizgisinin hemen
üstünde, ucu ucuna.
**Neden önemli:** Projenin temel kısıtı bu. "Bu bir düşük yükseklik
projesi" iddiasının ekrandaki kanıtı.

### C5 — Ay evresi cezayı değiştiriyor
**Yap:** Hedef Galaktik merkezken tarihe tıkla, takvimden sırayla şu
tarihleri seç. Her seferinde renkli noktalı Ay cümlesine bak.

| Tarih | Ay | Ceza | Nokta | Karar |
|---|---|---|---|---|
| 15 Temmuz | %3 | 0.0 kadir | 🟢 | sorun degil |
| 19 Temmuz | %35 | 0.6 kadir | 🟠 | dikkat |
| 21 Temmuz | %55 | **1.4 kadir** | 🟠 | **dikkat** |
| 23 Temmuz | %73 | 2.6 kadir | 🔴 | cekilemez |
| 25 Temmuz | %88 | 4.1 kadir | 🔴 | cekilemez |

**Bekle:** Nokta yeşil → turuncu → kırmızı geçişini yapıyor, ceza
tırmanıyor. Renk 0.5 ve 1.5 kadirde değişiyor (fon farkının gözle ayırt
edilebilir olmaya başladığı ve difüz hedefleri bitirdiği eşikler).
**Not:** 21 Temmuz sınıra çok yakın: gerçek değer 1.4499, yani 1.5'in
**altında** — turuncu doğru. Kırmızıyı ilk 23 Temmuz'da görürsün.
**Tutmazsa:** Ay efemerisi veya Krisciunas-Schaefer modeli yanlış bağlanmış.

### C6 — Karanlık bandı ve pencere tutarlı
**Yap:** Tarihi **15 Temmuz**'a geri al. Grafiğe bak.
**Bekle:** Yeşil bant, koyu mavi bandın **içinde** kalıyor — dışına taşan
hiçbir parçası yok.
**Neden:** Çekim penceresi iki koşulun *kesişimi*: hedef 20°'nin üstünde
**ve** gökyüzü karanlık. Yeşilin koyu bandın dışına taşması, alacakaranlıkta
çekim öneriliyor demek olurdu — mantık hatası.

### C7 — Yüksek hedef, uzun pencere
**Yap:** Aynı gece (15 Temmuz), hedefi **M13** yap (Herkül Küresel Kümesi).
**Bekle:** Eğri neredeyse **başucuna** çıkıyor (~89°), pencere ~356 dk.
Galaktik merkezin 23.9°'sine göre dramatik fark.
**Neden:** M13'ün sapması +36.5°, Gaziantep'in enlemi 37.1° — neredeyse tam
tepeden geçiyor. Aynı gece, aynı yer, tamamen farklı sonuç.

### C8 — Ulaşılamaz hedef
**Yap:** Aynı gece, hedefi **M7** yap (en güneydeki Messier nesnesi).
**Bekle:** Eğrinin tepesi **18.1°** — yeşil 20° çizgisinin **altında**
kalıyor. Yeşil bant hiç yok. Panel "eşik yüksekliğinin üzerine çıkmıyor"
diyor.
**Neden önemli:** M7 doğuyor ama kullanılabilir değil. Doğmak görünür
olmak değildir — bu ayrım Faz 5 (radyometri) ve Faz 7'nin (ufuk profili)
temeli.

### C9 — Hedef listesi çalışıyor
**Yap:** Hedef listesini aç, birkaç farklı Messier nesnesi seç.
**Bekle:** Listede her satır **kendi adını** gösteriyor (M1, M2, M3 …),
seçince uygulama çökmüyor, grafik yeniden çiziliyor.
**Not:** Burada gerçek bir hata vardı ve düzeltildi — bütün satırlar aynı
değeri taşıdığı için seçim yapınca uygulama çöküyordu.

## D. Sahada yapılacak fiziksel testler

Bu bölüm ekranda değil, **dışarıda** yapılır. Ayrıntılı talimat:
[`docs/saha-talimati.md`](saha-talimati.md). Aşağısı sadece "ne var, ne
bekliyor" özeti.

### D1 — Doğrusallık merdiveni (0.A.6) · iç mekân, ~30 dk · ⏸ bekliyor
**Yap:** Kararlı ışık kaynağı (tercihen akkor ampul), ISO 1600 sabit,
poz 1/60 s'den 2 s'ye ikişer katlanarak, her basamakta 2 kare.
**Bekle:** Sinyal poz süresiyle doğru orantılı artıyor; aynı basamağın
iki karesi %1 içinde uyuşuyor.
**Neden tekrar:** İlk denemede ışık kararsızdı, araç bunu yakaladı.
Kazanç ölçümü etkilenmedi ama doğrusallık testi bozuldu.
**Engeli yok — bugün yapılabilir.**

### D2 — Kontrollü gökyüzü çekimi (0.B) · saha, bir gece ~4 saat · ⏸ açık gece bekliyor
**Ne zaman:** 8–13 Eylül 2026 (10 Eylül yeni ay) veya yedek olarak
7–13 Ekim. Karanlık pencere 10 Eylül'de 20:14–04:40 yerel.

**Üç dizi:**

| Dizi | Hedef | Ayar | Kare |
|---|---|---|---|
| **A** Fon | Pegasus karesi (00:30'da 77°, az 200°) | ISO 1600 poz merdiveni + 15 s ISO merdiveni | 27 |
| **B** Sönüm | Vega, 70°'den 20°'ye | ISO 1600, 15 s sabit, 7 durak | 35 |
| **C** Karanlık | Kapak takılı, gecenin sonunda | Kullanılan her kombinasyon | 24 |

**Bekle:** A'da fon poz süresiyle orantılı; üç ISO'nun elektron cinsinden
fon değeri aynı. B'de Vega 1.06'dan 2.91 hava kütlesine inerken ~0.46
kadir sönüyor.

**En kritik ayar:** *Uzun Poz Parazit Azaltma KAPALI.* Açık kalırsa makine
kendi karanlık karesini çıkarır ve C dizisi anlamsızlaşır.

**Zorunlu kayıt:** GPS koordinatı, ondalık derece, 5 hane. D3 onsuz
yapılamaz.

### D3 — VIIRS fon parlaklığı (0.C) · masa başı · ⏸ D2'nin koordinatını bekliyor
**Kim yapar:** Ben. Senden sadece koordinat lazım.
**Bekle:** O noktanın uydu ölçümlü fon parlaklığı, mag/arcsec².

### D4 — Hesap-gerçek karşılaştırması (0.D) · masa başı · ⏸ D2 + D3
**Bekle:** Hesabın dediği fon ile sensörün gördüğü fon **%15 içinde**,
ve hata yükseklik boyunca sistematik eğilim göstermiyor.
**Neden ikincisi daha zor ve daha değerli:** Asıl hedefin 24°'de duruyor.
Sadece zenit yakınında kalibre edip düşük yüksekliğe güvenilmez.

**Faz 5'in kalibrasyonu tam olarak bu adımdan çıkıyor.** D2 gelene kadar
radyometri iskeleti sayı üretmeyi reddedecek.

## Notlar

- Tüm saatler ekranda **yerel** (UTC+3), hesapta UTC. Yol haritası kuralı:
  "yerel saat sadece ekranda".
- Konum şu an **Gaziantep'e sabit**. Konum seçimi Faz 7'de gelecek.
- Kırılma (refraksiyon) haritada uygulanmıyor; Faz 7'de ufuk profiliyle
  birlikte gelecek. 24°'de etkisi 2.25 yay dakikası — bu görüntüde fark
  edilmez.
