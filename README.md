# fd-djkabin

FiveM için tam senkronize DJ kabini scripti. YouTube ve doğrudan ses linklerinden müzik çalar; sunucudaki herkes aynı saniyede aynı müziği duyar, geç katılanlar da mevcut saniyeden devam eder.

**Framework:** QBCore · ESX · Qbox · Standalone (otomatik algılanır)

## Özellikler

- 🎵 **Müzik:** YouTube linki veya doğrudan ses (mp3/ogg) URL'i çalma
- 🔁 **Gerçek zamanlı senkron:** Geç katılan / reconnect olan / interior değiştiren oyuncular doğru saniyeden devam eder (drift düzeltmeli)
- 🎚️ **DJ kontrolleri:** Play, Pause, Stop, Seek (progress bar'a tıkla), Volume, Repeat, Shuffle — tamamı NUI'dan
- 📃 **Playlist sistemi:** Oluştur / sil / düzenle, şarkı ekle-çıkar, tek tıkla sıraya yükle (MySQL'de kalıcı)
- ⏭️ **Queue:** Şarkı bitince otomatik olarak sıradaki başlar; DJ başında durmak zorunda değil
- 📍 **Sınırsız booth:** Config'ten veya oyun içinden istediğin kadar DJ noktası; her biri bağımsız (kendi sesi, playlisti, efektleri)
- 💾 **Kalıcılık:** Booth'lar, playlistler, konumlar ve ayarlar restart sonrası korunur (oxmysql)
- 🔐 **Yetki:** Booth başına job + minimum grade (`jobs = { ['bahama'] = 0 }`), `public` booth veya sadece admin (ace)
- ✨ **Efektler:** Laser (renk + hız), Smoke, Club Lights (hız), Particles, Spot Light — herkes görür
- 📡 **3 ses yayılım algoritması:** linear / quadratic / exponential (booth başına seçilir)
- 📺 **Streamer mode:** `/streamermode` — müzik susar, efektler kalır (Twitch/Kick telif koruması)
- 🔊 **Soundboard:** Air Horn, Applause, Siren vb.; config'ten kendi seslerini ekleyebilirsin
- 🌐 **TR + EN locale**

## Kurulum

1. `sql/install.sql` dosyasını veritabanında çalıştır (script ilk açılışta tabloları kendisi de oluşturur).
2. Kaynağı `resources/fd-djkabin` olarak koy.
3. `server.cfg`:
   ```cfg
   ensure oxmysql
   ensure fd-djkabin
   add_ace group.admin fd-djkabin.admin allow
   ```
4. `shared/config.lua` içinden booth'ları, yetkileri ve soundboard'u düzenle.

> NUI derlenmiş halde (`web/dist`) repo'da mevcut; ekstra build gerekmez. UI'ı değiştireceksen: `cd web && npm install && npm run build`.

## Kullanım

- Booth yakınında **E** (veya ox_target varsa target menüsü) → DJ paneli açılır.
- **`/djbooth create <isim>`** — bulunduğun yere booth kur (admin)
- **`/djbooth delete <id>`** / **`/djbooth move <id>`** / **`/djbooth list`**
- **`/streamermode`** — müziği kendin için kapat/aç (tercih kalıcıdır)

## Yapılandırma

`shared/config.lua`:

- `Config.Locale` — `'tr'` veya `'en'`
- `Config.Booths` — sabit booth'lar: konum, `jobs` (job → min grade), `public`, ses ayarları, panel vurgu rengi
- `Config.BoothDefaults` — oyun içinden oluşturulan booth'ların varsayılanları
- `Config.Effects` — efekt renkleri, hızları, partikül asset'leri
- `Config.Soundboard` — ses efekti listesi (dış URL veya `web/public/sfx/` içi dosya)
- `Config.Attenuation` — ses yayılım algoritmaları

## Nasıl çalışıyor?

- Sunucu her booth için otoriter state tutar (şarkı, başlangıç zamanı, sıra, efektler). Değişiklikler herkese yayınlanır; bağlanan oyuncu tam state ister.
- Müzik client tarafında NUI içinde çalınır (YouTube IFrame API / HTML5 Audio). Client her 250 ms mesafeye göre sesi hesaplar; ±2 sn sapmada otomatik seek ile düzeltir.
- Şarkı süresi player'dan sunucuya raporlanır; süre dolunca sunucu sıradakini başlatır — DJ çevrimdışı olsa bile müzik devam eder.
- Boşta neredeyse hiç CPU kullanmaz: efekt döngüsü aktif efekt yokken 750 ms uyur, menzil dışı player'lar yok edilir.
