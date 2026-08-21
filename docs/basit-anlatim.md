# Bu proje ne yapıyor — sade anlatım

Teknik terim kullanmadan, baştan.

## Amaç

Bir hesap makinesi. Sen soruyorsun:

> *"10 Eylül gecesi Mersin'den, 14 mm lensle, 20 saniye poz versem
> ne çıkar?"*

Program cevap veriyor: yıldızlar iz bırakır mı, hedef gürültünün üstüne
çıkar mı, kare ne kadar dolar, kırpma olur mu.

**Amaç güzel bir görüntü üretmek değil, gitmeden önce ne çıkacağını
bilmek.** Sahada işe yarayan şey bu.

## Neden zor

Cevap verebilmek için programın **senin makineni** tanıması gerekiyor —
kutunun üstünde yazan değil, gerçekte nasıl davrandığı.

Fırın gibi düşün: tarif "180 derece" diyor ama senin fırının 180
dediğinde gerçekten 180 mi? Önce fırını ölçmen lazım.

## Ölçülmesi gereken beş şey

| Kod | Ne demek | Niye bilinmiyor |
|---|---|---|
| **k** | Hava ışığı ne kadar yutuyor | Sahil ≠ dağ başı, her gece farklı |
| **ZP** | Bilinen bir ışık makinede kaç sayı ediyor | Senin makinene ve lensine özel |
| **FWHM** | Yıldız kaç piksel görünüyor | Lensin keskinliğine bağlı |
| **I_d** | Makine karanlıkta kendi kendine ne üretiyor | Isıya ve sensöre bağlı |
| **μ_sky** | Senin gökyüzün ne kadar parlak | Şehre uzaklığa bağlı |

Bunlar bilinmeden hesap yapılamaz. **Uydurulursa cevap da uydurma
olur.** Projenin baştan beri tek kuralı bu: uygulama, ölçülmemiş bir
sayıyla hesap yapmayı **reddediyor**. Uygulamayı açınca "Rapor"
sekmesinde neyin eksik olduğunu ve nereden geleceğini görüyorsun.

## Nasıl ölçülüyor

**İç mekânda (bitti):** Makinenin ışığı sayıya çevirme oranı ve kendi
gürültüsü. Kapak takılı kareler + düzgün aydınlatılmış bir kâğıt.

**Bir gece dışarıda (8–13 Eylül):** Kalan beş şeyin beşi de.

Püf nokta şu: **parlaklığı zaten bilinen bir yıldız** kullanmak. Vega'nın
parlaklığı katalogda yazıyor. Fotoğrafını çekiyorsun, makine "şu kadar
sayı" diyor. Aradaki oran senin makinenin çevrim katsayısı — yani **ZP**.

Aynı fotoğraftaki **gökyüzünün** kaç sayı verdiğine de bakıyorsun.
Yıldızla karşılaştırınca gökyüzünün parlaklığı çıkıyor — yani **μ_sky**
de bedavaya geliyor.

Vega'yı gece boyunca alçalırken takip edince, ne kadar söndüğünden
**k** çıkıyor.

Yani **tek gece, tek yıldız, beş ölçüm.**

## Neden uydu verisi kullanmıyoruz

Kullanacaktık. VIIRS diye bir uydu şehir ışıklarını ölçüyor. Ama uydu
**yukarı çıkan** ışığı görüyor, biz ise **yerden yukarı bakınca**
görüneni istiyoruz. Farklı şeyler; arada bir çevrim var ve o çevrim
±%25 şaşıyor.

Kendi karendeki yıldız çok daha doğru — üstelik bedava.

## Şu an neredeyiz

| | |
|---|---|
| İç mekân ölçümleri | ✅ bitti |
| Gökyüzü haritası, kadraj, gece planı | ✅ bitti |
| Işık hesabının iskeleti | ✅ yazıldı |
| Kalibrasyon | ⏸ **6 şeyden 0'ı** — bir gece çekim bekliyor |

O gece çekim yapılınca **6'dan 5'i** kapanıyor.

## "Bu sadece senin makinene mi çalışıyor?"

Hayır. Ve sandığından iyi.

**Programın büyük kısmı hiç kalibrasyon istemiyor.** Kadraj, yıldız izi,
gece penceresi, Ay hesabı, yıldız haritası — hepsi her kullanıcı için
bugün çalışıyor. Bir planlama aracının değerinin çoğu zaten burada.

**Ölçülenlerin çoğu kişiye değil, makine MODELİNE özel.** Bir Canon
760D ölçümü, dünyadaki bütün 760D'ler için geçerli. Kazanç, gürültü,
çevrim katsayısı — hepsi bir kez ölçülür, herkes kullanır.

Gerçekten kişisel olan tek şey **k** (havanın ışığı yutması), çünkü o
hem yere hem o geceye bağlı.

**Yeni bir kullanıcı için üç kademe:**

| Kademe | Ne yapar | Ne kazanır |
|---|---|---|
| 1 | Listeden makinesini seçer | Kadraj, iz, gece planı — tamamı |
| 2 | Bilinen bir yıldıza **tek kare** çeker | Işık hesabı da kalibre olur |
| 3 | Bir gece tam ölçüm | En yüksek doğruluk |

Kademe 2 otuz saniyelik iş. Çoğu kullanıcı 1 veya 2'de durur.

**Peki senin ölçümün niye bu kadar ayrıntılı?** Çünkü fiziğin doğru
kurulduğunu bilmek için en az bir makineyi baştan sona ölçmek gerekiyor.
Seninki o makine. Başkasının verisine güvenebilmemiz için önce tam
ölçülmüş bir sistemde doğrulanmış olması lazım.

## Bir de şu oldu

Işık hesabı yazılınca ilk işi kendi çekim planımızdaki hatayı bulmak
oldu: planlanan ayarla **Vega patlayacaktı**.

"Patlamak" = sensör dolup taşıyor. Güneşe doğru çekilen fotoğrafta
göğün bembeyaz çıkması gibi — bembeyaz bir alandan "ne kadar parlaktı"
öğrenemezsin.

Bütün kareler öyle çıkacaktı ve gece boşa gidecekti. Ayarlar
düzeltildi, sahada kontrol edebileceğin bir araç eklendi.

Hesap, daha bir tek kalibrasyon almadan kendini ödedi.
