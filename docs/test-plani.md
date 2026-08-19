# Uygulama test planı — Faz 2, 3 ve 4

Bu belge, kodda test edilemeyen şeyler içindir: **ekranda doğru görünüyor mu.**
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

### C1 — Zaman kaydırıcısı gökyüzünü döndürüyor
**Yap:** Alt paneldeki kaydırıcıyı sürükle.
**Bekle:** Yıldızlar dönüyor, akıcı — takılma yok.
**Tutmazsa:** `SkyModel.atTime` kısayolu devrede değil.

### C2 — "Şu an" göstergesi kaydırıcıyı takip ediyor
**Yap:** Alt panelde **Plan** sekmesine geç. Kaydırıcıyı oynat.
**Bekle:** Üç şey **birlikte** değişiyor:
- Grafikteki **beyaz dikey çizgi** kayıyor
- Mavi eğri üzerindeki **nokta** yukarı/aşağı gidiyor
- "**şu an**" satırındaki hedef yüksekliği, Ay yüksekliği ve ceza değişiyor

**Tutmazsa:** Söyle — bu tam olarak senin bulduğun eksiklikti, yeni eklendi.

### C3 — Pencere değişmiyor (doğru davranış)
**Yap:** Kaydırıcıyı gece boyunca oynat.
**Bekle:** Üstteki `Pencere 21:38 – 00:19` satırı **sabit kalıyor.**
Bu doğru: gece boyunca pencere aynı pencere.

### C4 — Galaktik merkez 24°'yi geçmiyor
**Yap:** Hedef: **Galaktik merkez**. Tarihi **15 Temmuz 2026**'ya getir
(gün ok tuşlarıyla).
**Bekle:** Grafikte mavi eğrinin tepesi **24° çizgisinin hemen altında**.
**Neden önemli:** Projenin temel kısıtı bu. Yol haritasının "bu bir düşük
yükseklik projesi" iddiasının ekrandaki kanıtı.

### C5 — Ay evresi cezayı değiştiriyor
**Yap:** Hedef Galaktik merkezken tarihi **15 Temmuz** → **25 Temmuz**
yap (10 kez ileri gün).
**Bekle:**

| Tarih | Ay | Ceza | Karar |
|---|---|---|---|
| 15 Temmuz | %3 dolu | 0.0 kadir | 🟢 sorun değil |
| 25 Temmuz | %88 dolu | ~4.1 kadir | 🔴 çekilemez |

**Tutmazsa:** Ay efemerisi veya Krisciunas-Schaefer modeli yanlış bağlanmış.

### C6 — Karanlık bandı mantıklı
**Yap:** Grafiğe bak.
**Bekle:** Koyu bant gecenin ortasında, yeşil pencere onun içinde kalıyor —
yeşil bandın karanlık bandın dışına taşan kısmı olmamalı.

### C7 — Farklı hedef, farklı eğri
**Yap:** Hedefi **M31** (Andromeda Galaksisi) yap.
**Bekle:** Eğri çok daha yükseğe çıkıyor (M31 sapması +41°, Gaziantep
enlemi 37° — neredeyse başucundan geçiyor). Pencere uzuyor.

### C8 — Ulaşılamaz hedef
**Yap:** Hedefi **M7** yap (en güneydeki Messier nesnesi).
**Bekle:** Eğrinin tepesi ~18°, yani 20° eşiğinin altında. Panel
"Hedef bu gece eşik yüksekliğinin üzerine çıkmıyor" diyor, yeşil pencere
yok.
**Neden önemli:** Doğmak görünür olmak değil — bu ayrım Faz 5 ve 7'nin
temeli.

---

## Notlar

- Tüm saatler ekranda **yerel** (UTC+3), hesapta UTC. Yol haritası kuralı:
  "yerel saat sadece ekranda".
- Konum şu an **Gaziantep'e sabit**. Konum seçimi Faz 7'de gelecek.
- Kırılma (refraksiyon) haritada uygulanmıyor; Faz 7'de ufuk profiliyle
  birlikte gelecek. 24°'de etkisi 2.25 yay dakikası — bu görüntüde fark
  edilmez.
