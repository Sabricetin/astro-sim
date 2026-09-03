# Panorama lisansı — araştırma ve karar (3 Eylül 2026)

Yol haritası 6.1'de *"ESO veya NASA kaynaklı panorama, CC BY-NC olanları
alma"* yazıyordu. Araştırınca sorunun **iki ayrı soru** olduğu çıktı.

## Soru aslında iki tane

| | Ne için | Ne gerekiyor |
|---|---|---|
| **Görsel katman** | Kullanıcı Samanyolu'nu görsün, kadraj kursun | Güzel bir panorama |
| **Radyometrik katman** | SNR hesabına difüz parlaklık girsin | **Kalibre edilmiş** yüzey parlaklığı |

Bunları karıştırmak asıl tuzak. Sanatsal bir panorama ikinci iş için
**kullanılamaz** — o görüntü gerilmiş, renk düzeltmesi görmüş, gradyanı
temizlenmiş. Piksel değerinden mag/arcsec²'ye savunulabilir bir eşleme
yok. Kullanmak, yasakladığımız şeyin ta kendisi olurdu: uydurma sabit.

---

## Görsel katman — ESO temiz ✅

**ESO Milky Way panorama** (eso0932a, ESO/S. Brunier), 6000×3000,
equirectangular, galaktik düzlem yatay.

ESO'nun telif sayfasından doğrudan doğrulandı:

> Creative Commons Attribution 4.0 International

- **Ticari kullanım açıkça izinli** ("may on a non-exclusive basis be
  reproduced without fee")
- Şart: atıf net ve okunur olacak, metni değiştirilmeyecek
- Yasak: ESO'nun ürünü onayladığı izlenimi vermek
- Not: 800 megapikselllik **orijinal** CC kapsamında değil, fotoğrafçıdan
  ayrıca izin gerekiyor. Bize gereken 6000×3000 sürüm kapsamda.

Galaktik koordinatlarda olması bizim için **avantaj** — dönüşüm zaten
var (T6.2).

**Kalan tek risk lisans değil, performans:** yol haritasının uyardığı
shader meselesi. Bir günlük prototip hâlâ gerekli.

---

## Radyometrik katman — burası karışık

### GAMBONS — bilimsel olarak tam istediğimiz şey

*GAia Map of the Brightness Of the Natural Sky* (Masana ve ark. 2021,
MNRAS 501, 5443). Gaia DR2 + Hipparcos'tan türetilmiş, **kalibre
edilmiş** doğal gökyüzü parlaklığı:

- V bandı, **mag/arcsec²** — doğrudan bizim birimimiz
- HEALPix çözünürlük 8 → 786.432 piksel, ortalama 0.052 deg²
- Yıldız ışığı + difüz galaktik ışık + zodyak ışığı + hava parıltısı
- Konuma ve zamana göre üretilebiliyor

**Ama lisansı yayınlanmamış.** Site "freely downloaded" diyor; bu bir
*izin metni* değil. BSC5 ile aynı kategori: kısıt yok ama açık bir
hak devri de yok. Ticari dağıtımdan önce yazarlara sorulmalı.

### Kendi kurmamız — Leinert 1998

*The 1997 reference of diffuse night sky brightness* (Leinert ve ark.,
A&AS 127, 1) difüz gökyüzünün bütün bileşenlerini **tablo halinde**
veriyor: yıldız ışığı, difüz galaktik ışık, zodyak ışığı, hava
parıltısı.

Yayınlanmış bir modeli denklem ve tablolarından yeniden kurmak standart
uygulama; makalenin telifi bunu engellemiyor (atıf gerekiyor). Hava
parıltısı kısmını **zaten yaptık** (T6.6, van Rhijn).

### En sağlam yol: hibrit

Sıfır noktasında yaptığımızın aynısı.

> **Mutlak ölçek senin ölçümünden, yöne göre değişim modelden.**

Faz 0.B zaten senin gökyüzünün fon parlaklığını ölçüyor — o değer,
ölçüldüğü yöndeki her şeyi (yıldız ışığı, zodyak, hava parıltısı,
şehir) içinde taşıyor. Modelden gereken tek şey **oran**: başka bir
yöne bakınca fon kaç kat değişir.

Bu yaklaşımın üç faydası:

1. Mutlak kalibrasyon dışarıdan gelmiyor → lisans sorunu küçülüyor
   (oran için tablo yeterli, tam harita gerekmiyor)
2. Senin gökyüzünün gerçek şehir parlaması ölçüme dahil
3. Zincirin geri kalanıyla aynı disiplin: **ölçülebilen ölçülür,
   ölçülemeyen modellenir ve kaynağı yazılır**

---

## Karar

| | |
|---|---|
| **Görsel katman** | ✅ **ESO panorama, CC BY 4.0.** Atıf: "ESO/S. Brunier". Karar verildi. |
| **Radyometrik katman** | Leinert 1998'den **oran modeli** kur; mutlak ölçek 0.B ölçümünden gelsin |
| **GAMBONS** | Açık madde — ticari dağıtımdan önce yazarlara lisans sorulacak. Cevap olumluysa daha iyi bir seçenek. |

**Açık maddeler listesine eklendi** (BSC5'in yanına):
GAMBONS lisansı — yalnızca kullanılırsa.

---

## Kaynaklar

- [ESO Milky Way panorama (eso0932a)](https://www.eso.org/public/images/eso0932a/)
- [ESO telif politikası](https://www.eso.org/public/outreach/copyright/)
- [GAMBONS makalesi (MNRAS 501, 5443)](https://academic.oup.com/mnras/article/501/4/5443/6056493)
- [GAMBONS sitesi](https://gambons.fqa.ub.edu/)
- [Leinert ve ark. 1998, A&AS 127, 1](https://aas.aanda.org/articles/aas/abs/1998/01/ds1449/ds1449.html)
