# Kendi ufkunu ölçmek — 15 dakika, gündüz

Uygulamadaki **Ufuk** sekmesi sekiz yönde engel açısı istiyor. Bu belge
onları nasıl ölçeceğini anlatıyor.

## Neden gerekli

Hedefin 20°'ye çıkması yetmez, **önündeki tepeyi de aşması** gerekir.
Ölçülmüş bir örnek: Mersin'den galaktik merkez, düz ufukta 165 dakikalık
pencere. Güneyde 23°'lik bir tepe varsa **106 dakika** — 59 dakika, yani
gecenin üçte birinden fazlası kayboluyor.

Bunu bilmeden sahaya gidersen o 59 dakikayı bekleyerek geçirirsin.

## Ne zaman ölçülür

**Gündüz.** Karanlıkta tepe hattını göremezsin. Ölçüm bir kez yapılır,
o konum için geçerli kalır.

> **Not:** Bu ölçüm telefonla yapılıyor ama telefonda *bu uygulamanın*
> çalışmasına gerek yok — telefon burada sadece eğim ölçer. Ölçtüğün
> sekiz sayıyı sonra bilgisayardaki uygulamaya gireceksin.
> (Uygulamayı yine de telefonda açmak istersen:
> [`telefonda-calistirma.md`](telefonda-calistirma.md))

## Ne gerekiyor

- Telefon
- Bir eğim ölçer uygulaması — iPhone'da **Pusula** uygulamasının ikinci
  sayfası, Android'de "clinometer" veya "eğim ölçer" arayınca çıkan
  ücretsiz uygulamalardan biri
- Pusula (aynı uygulamalarda genelde var)

Telefonun eğim ölçeri ±1–2° hassasiyette. Bu iş için fazlasıyla yeterli;
ufuk açısını daha hassas bilmek sonucu değiştirmiyor.

## Ölçüm

**Çekim yapacağın noktada dur.** Birkaç yüz metre öteden ölçmek işe
yaramaz; tepe açısı mesafeye göre değişir.

Her yön için:

1. Pusulayla o yöne dön (K = 0°, KD = 45°, D = 90°, GD = 135°,
   G = 180°, GB = 225°, B = 270°, KB = 315°)
2. Telefonu **dikey** tut, üst kenarını o yöndeki **en yüksek engelin
   tepesine** nişanla
3. Eğim ölçerin gösterdiği açıyı yaz

| Yön | Azimut | Açı |
|---|---|---|
| K | 0° | |
| KD | 45° | |
| D | 90° | |
| GD | 135° | |
| G | 180° | |
| GB | 225° | |
| B | 270° | |
| KB | 315° | |

**Engel yoksa 0 yaz.** Deniz veya düz ova gören yönler 0'dır.

## Neyi ölçeceksin

**En yüksek engel** — o yöndeki ufku kapatan en yüksek şey. Tepe, bina,
ağaç, duvar, hepsi sayılır.

Uydu yükseklik verisi (DEM) sadece araziyi bilir; **ağacı ve binayı
göremez.** Bu yüzden gözle ölçüm çoğu zaman daha doğrudur — ve uygulama
şimdilik zaten onu istiyor.

## Doğruluk için üç not

**Yakındaki nesne uzaktakinden önemlidir.** 50 metredeki 10 metrelik bir
ağaç 11° yapar; 5 kilometredeki 300 metrelik bir tepe 3.4°. Ağaç daha
çok engel.

**Ara yönlerde tepe varsa en yakın sekizliğe yaz.** Örneğin 200°'de
büyük bir tepe varsa, hem G (180°) hem GB (225°) değerini yükselt.
Uygulama arasını doğrusal dolduruyor; iki noktayı da yükseltmek tepeyi
daha doğru temsil eder.

**Kuzeydeki engel çoğu hedefi etkilemez.** Türkiye'den bakınca ilginç
hedeflerin çoğu güneyde. Yine de kuzeyi de ölç: kutup yakını hedefler
(M81, M82, Ejder) için önemli.

## Girdikten sonra

Uygulamada **Ufuk** sekmesine gir, sekiz değeri kaydırıcılarla ayarla,
**"Ufku hesaba kat"** anahtarını aç.

Sonra:

- **Gökyüzü haritasında** arazi silueti görünür, altı kararır
- **Plan sekmesinde** "Ufuk 59 dk götürüyor" satırı çıkar
- Hedef eşiği geçmiş ama tepe hâlâ kapatıyorsa saat aralığı yazılır

## Birden fazla konum ölçersen

Her konumun ufku ayrı. Şimdilik uygulama tek profil tutuyor; konum
değiştirdiğinde değerleri yeniden girmen gerekiyor.

İki konumu karşılaştırmanın pratik yolu: her ikisi için değerleri gir,
**"Ufuk kaç dk götürüyor"** satırını not et. Aradaki fark, o gece o
konumu seçmenin bedeli.
