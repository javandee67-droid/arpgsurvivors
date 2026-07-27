# Görev Panosu

## Bulgular
### Eksikler/Hatalar
- Pause menu eksik veya sadece oyun durdurma sağlanıyor; ayrı bir resume/ayarlar/çıkış menüsü yok.
- Ana menü sahnesi sadece bir Placeholder Control düğümü içerir; Başlangıç, Seçenekler, Çıkış düğmeleri eksik.
- Oyun bitti ekranı (VSDeathScreen) var ama oyun sonu olaylarıyla tam entegrasyonu olmayabilir.
- Ses varlığı (efekt, müzik) yok; sadece AudioManager skripti var.
- Görsel efektler sınırlı: sadece boss ekran flaşı; çarpma flaşı, ekran titreşimi, parçacık efektleri, seviye-atla efektleri eksik.
- Düşman spawn sistemi var ama dengelemesi ve dalga ilerlemesi iyileştirilebilir.
- Kaydetme/yüklenme sistemi gözlemlenmedi.
- Ayarlar/Seçenekler menüsü yok (ses seviyesi, grafik kalitesi, tuş atamaları).
- Yerelleştirme/ulusallaştırma yok (tüm metin Türkçe/İngilizce karışık, ancak gerekli olmayabilir).
- Giriş yeniden bağlama sistemi yok (tuşlar sabit).
- Erişilebilirlik: yazı boyutları, kontrast iyileştirilebilir.
- Öğretici veya hoş geldin ekranı eksik.

### Oyuncuyu Oyunda Tutacak Öneriler
- Beceri ve destek gem sistemiyle sinergi ve kombinasyonları derinleştirin.
- Kritik vuruş, seviye atlama, boss spawn için görsel ve sesli geri bildirim ekleyin (ekran titreşimi, flash, parçacık, ses).
- Düşman türleri ve dalga paterni çeşitliliğiyle savaşın taze kalmasını sağlayın.
- Meta-progression sistemi ekleyin (örnek: çalıştırmalar arasında kalınan para veya kalıcı yükseltmeler).
- Günlük/haftalık zorluklar veya etkinlikler ekleyin.
- Başarım/trofü sistemi ekleyin.
- Oyuncunun skill'ini aşan zorluk ölçeği (adaptive difficulty) ekleyin.
- Loot drop sistemi ile nadrlilik ve görsel efektler ekleyin.
- Yanıtçı veya evcil hayvan sistemi ekleyin.
- Liderbord veya skor sistemi ekleyin.
- Oyun hikayesi veya lendir acquirement üzerinden kilitlenebilecek girişler ekleyin.
- Oyuncu veya silah personalizasyonu (skinler, renkler) ekleyin.
- Yeni oyun plus (New Game+) modu ekleyin zorluk ve ödül ile.
- Oyuncunun skill'ini aşan zorluk ölçeği (adaptive debt) uygula.
- Giriş yeniden bağlama sistemi ekle (ayarlar menüsünden)
- Yeni oyun plus (New Game+) modunu uygula (isteğe bağlı)
- Oyun içinde ipucu/toast sistemi göster (yeni skill essence dolu vb.)
- Pause menüsü işlevselliğini test et (resume, ayarlar, çıkış) — @BugTester
- Ayarlar menüsü değişikliklerini test et ve kalıcılığı kontrol et — @BugTester
- Ses efektlerini ve müziği test et (ses seviyesi, çalma, durdurma) — @BugTester
- Görsel efektlerini test et (flash, titreşim, parçacık) — @BugTester
- Kaydetme/yüklenme sistemini test et (oyun kaydedip yeniden yükleme) — @BugTester
- Düşman spawn sistemini test et (dalga sayısı, boss apparaître) — @BugTester
- Loot drop sistemini test et (item drop, rarity) — @BugTester
- Para/kaynak sistemi test et (kazanç, harcama, kalıcılık) — @BugTester
- Başarım/istatistik sistemini test et (artış, kaydetme) — @BugTester
- Zorluk ölçeği testi (zaman ve kill karşılığı zorluk artışı) — @BugTester
- Giriş yeniden bağlama testi (yeni tuşlarla oyun oynama) — @BugTester
- Yeni oyun plus modu testi (varsa) — @BugTester
- Menü geçişlerini ve UI etkileşimlerini test et (ana menü → oyun → pause → ayarlar → oyun) — @BugTester

## Yapılacak (todo)
- [ ] Pause menüsü UI oluştur (Resume, Ayarlar, Çıkış) — @UI
- [ ] Ana menü UI'yi tamamla (Başlangıç, Seçenekler, Çıkış, opsiyonel Krediler) — @UI
- [ ] Ayarlar menüsü UI oluştur (ses sliderları, grafik kalitesi, tuş atamaları, dil) — @UI
- [ ] Oyun bitti ekranını iyileştir (yeniden dene, ana menüye dön) — @UI
- [ ] Görsel efekt prefab'/scene'leri oluştur: çarpma flaşı, ekran titreşimi, vuruş parçacıkları, seviye-atla parçacıkları, boss flaşı gelişmişi — @UI (veya @Code ise prefab kodluysa)
- [ ] Bildirim/toast sistemi UI oluştur (yeni skill, essences dolu, yeni biyom) — @UI
- [ ] Basit eğitim/ipucu sistemi overlay oluştur — @UI
- [ ] Basit kaydetme/yüklenme sistemi uygula (oyuncu ilerlemesi, para, kilitlenen yetenekler) — @Code
- [ ] Düşman spawn sistemini dengele ve dalga ilerlemesini iyileştir (zaman ve kill temelli zorluk) — @Code
- [ ] Loot drop sistemi ekle (nesne rarity, görsel efekt) — @Code
- [ ] Para/kaynak sistemi ekle (çalıştırmalar arasında kalır) — @Code
- [ ] Başarım/istatistik sistemi ekle (basit) — @Code
- [ ] Oyuncunun skill'ini aşan zorluk ölçeği (adaptive debt) uygula — @Code
- [ ] Giriş yeniden bağlama sistemi ekle (ayarlar menüsünden) — @Code
- [ ] Yeni oyun plus (New Game+) modunu uygula (isteğe bağlı) — @Code
- [ ] Oyun içinde ipucu/toast sistemi göster (yeni skill essence dolu vb.) — @Code
- [ ] Pause menüsü işlevselliğini test et (resume, ayarlar, çıkış) — @BugTester [BugTester inceliyor]
- [ ] Ayarlar menüsü değişikliklerini test et ve kalıcılığı kontrol et — @BugTester
- [ ] Ses efektlerini ve müziği test et (ses seviyesi, çalma, durdurma) — @BugTester
- [ ] Görsel efektlerini test et (flash, titreşim, parçacık) — @BugTester
- [ ] Kaydetme/yüklenme sistemini test et (oyun kaydedip yeniden yükleme) — @BugTester
- [ ] Düşman spawn sistemini test et (dalga sayısı, boyor) — @BugTester
- [ ] Loot drop sistemini test et (item drop, rarity) — @BugTester
- [ ] Para/kaynak sistemi test et (kazanç, harcama, kalıcılık) — @BugTester
- [ ] Başarım/istatistik sistemini test et (artış, kaydetme) — @BugTester
- [ ] Zorluk ölçeği testi (zaman ve kill karşılığı zorluk artışı) — @BugTester
- [ ] Giriş yeniden bağlama testi (yeni tuşlarla oyun oynama) — @BugTester
- [ ] Yeni oyun plus modu testi (varsa) — @BugTester
- [ ] Menü geçişlerini ve UI etkileşimlerini test et (ana menü → oyun → pause → ayarlar → oy

## Devam Ediyor (in-progress)
- [ ] Ana menü sahnesi (Start/Options/Quit) oluştur — @UI [UI çalışıyor]
- [ ] Ayarlar menüsü için ses, grafik, tuş kaydetme/yükleme sistemini uygula — @Code [Code çalışıyor]
- [ ] Ses yöneticisine gerçek ses efektleri ve müziği yükleme/ çalma işlevini ekle (placeholder sesler de olabilir) — @Code [Code çalışıyor]
- [ ] Pause menüsü işlevselliği: oyunu durdur/devam et, ayarlar uygula, çıkış yap — @Code [Code çalışıyor]
- [ ] Oyun menülerinde navigasyon ve tuş etkileşimlerini test et — @BugTester [BugTester inceliyor]
- [ ] Görsel efekt sistemini uygula: ekran titreşimi (kamera sallama), çarpma flaşı (beyaz flash), parçacık sistemleri (hit, level-up, boss) — @Code [Code çalışıyor]

## Tamamlandı (done)
- [x] VSSkillSelectionUI: Zaten mevcuttu, çalışıyor (Main.gd'de kullanılıyor) — @Code
- [x] VSSupportSelectionUI: Zaten mevcuttu, çalışıyor (Main.gd'de kullanılıyor) — @Code
- [x] VSPassiveSelectionUI: Zaten mevcuttu, çalışıyor (Main.gd'de kullanılıyor) — @Code
- [x] AudioManager: Script oluşturuldu, autoload'e eklendi — @Code
- [x] Pause menüsü işlevselliği: oyunu durdur/devam et, ayarlar uygula, çıkış yap — @Code
- [x] Ses yöneticisine gerçek ses efektleri ve müziği yükleme/ çalma işlevini ekle (placeholder sesler de olabilir) — @Code