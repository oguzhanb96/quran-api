# Misbah — yayın (Google Play) hazırlığı

## 1. Android imzalama

1. `android/key.properties.example` dosyasını `android/key.properties` olarak kopyalayın.
2. Play Console için bir **upload keystore** oluşturun ve yolu / şifreleri `key.properties` içine yazın.
3. `storeFile` yolunu depoya eklemeyin; `.gitignore` içinde `*.jks` ve `key.properties` tutulmalıdır.

Release derlemesi:

```bash
flutter build appbundle
```

`key.properties` yoksa sürüm **debug** anahtarı ile imzalanır (yalnızca yerel test).

## 2. Uygulama kimliği

- **Android:** `app.misbah.companion` (`android/app/build.gradle.kts`)
- **iOS:** Xcode’da `PRODUCT_BUNDLE_IDENTIFIER` = `app.misbah.companion`

## 3. Play Console

- **Gizlilik politikası:** yayınlanmış bir URL (web sayfası) gereklidir; uygulama içinde de erişilebilir olmalıdır.
- **Veri güvenliği (Data safety):** konum, ağ istekleri, Firebase vb. beyanları doldurun.
- **Hedef API:** Flutter’ın `targetSdk` değerini kullanın; güncel Flutter ile genelde politika karşılanır.

## 4. Sürüm numarası

`pubspec.yaml` içinde `version: major.minor.patch+buildNumber` — `buildNumber` her Play yüklemesinde artırılmalıdır.
