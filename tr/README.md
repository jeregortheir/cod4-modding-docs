# 🗺️ VLCT Deathrun - Map Yapımcıları için Rehber

**CoD4 Deathrun** map yapımcıları için savunmacı GSC scripting rehberi. Sunucu çökmelerini önleyen kalıplar, tarifler ve hayatta kalma kuralları.

> **Yeni misin?** Aşağıdaki [Hızlı Başlangıç](#hizli-baslangic-5-adim) ile başla, sonra [Temel Bilgiler](/en/fundamentals.md) (İngilizce) oku - ilk tuzağını yazmak için yeterli.

---

## Hızlı Başlangıç (5 adım)

Sıfırdan çalışan bir haritaya en hızlı yol:

1. **Şablon dosyasını kopyala**
   `maps\mp\_TEMPLATE_FOR_MAPPERS.gsc` → `maps\mp\mp_dr_İSMİN.gsc`

2. **Aç.** `main()` fonksiyonuna kaydır. **İstemediğin** özellikler için `thread` satırlarını sil (örn. haritanda sniper odası yoksa `thread combat_room_sniper();` satırını kaldır). `maps\mp\_load::main();` satırını üstte bırak.

3. **Tuttuğun her özellik için,** bu rehberdeki bölümünü bul ve Radiant `targetname` stringlerini (`getEnt("...")` içindeki değerler) Radiant'ta koyduğun şeyle eşleşecek şekilde düzenle.

4. **`.bsp` dosyanı derle** Radiant'ta (`Compile > BSP + Light + Link`). `linkMap` çalıştığında `.gsc` dosyan `.ff` içine pişirilir.

5. **Test:** sunucu konsolunda `/map mp_dr_İSMİN`. Her testten sonra `qconsole.log` dosyasında `script runtime error` ara.

---

## Bu rehber neden var

CoD4 GSC motorunun keskin kenarları var - tek korunmasız bir satır:

* **Tüm sunucuyu** çökerebilir (örn. `setmovespeed()` gibi var olmayan bir builtin çağırmak)
* Dakikada binlerce hata spam edebilir (örn. activator takımında kimse yokken `level.activ.X` erişimi)
* Haritanı sessizce bozabilir (örn. Radiant'ta tekrar eden `targetname` → `getEnt` undefined döner)

> 🌐 Türkçe çeviri hâlâ yapım aşamasında. [Discord'da yardım et](https://vlct.mxme.pro/discord).

> 👉 Tam içerik: [English version](/en/)
