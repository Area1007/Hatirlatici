# Hatırlatıcı

Flutter ile geliştirilmiş, Türkçe arayüzlü bir hatırlatıcı uygulaması. Klasik hatırlatıcı oluşturmanın yanında Gemini destekli doğal dil girişiyle hızlı hatırlatıcı oluşturmayı destekler.

## Özellikler

- Normal ve AI ile hızlı hatırlatıcı oluşturma
- Tarih, saat, tekrar ve öncelik seçenekleri
- Yerel bildirimler
- Özel listeler
- Takvim görünümü
- İstatistikler
- Açık/koyu tema desteği
- Android ve iOS desteği
- Render üzerinde çalışan ayrı Gemini backend'i

## Gereksinimler

- Flutter SDK
- Dart (Flutter ile birlikte gelir)
- Android için Android Studio/SDK
- iOS için macOS + Xcode

## Kurulum

```bash
git clone <repo-url>
cd <repo-folder>
flutter pub get
flutter run
```

## AI servisi

Uygulama şu yayınlanmış backend adresini kullanır:

```text
https://hatirlatici-backend.onrender.com
```

Backend kaynak kodu ayrı bir repoda tutulmalıdır. API anahtarı mobil uygulamaya gömülmemiştir.

## Launcher icon ve splash

Gerekirse yeniden üretmek için:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Not

`build/`, `.dart_tool/`, IDE önbellekleri ve yerel/generated dosyalar Git'e dahil edilmez.
