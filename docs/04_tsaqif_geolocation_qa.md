# Panduan Presentasi: Tsaqif Kanz Ahmad
## Topik: Validasi Geolocation Mobile & QA

---

## 1. Gambaran Umum Tanggung Jawab

Kamu bertanggung jawab atas **dua hal penting**: (1) implementasi validasi GPS/geolocation di sisi mobile yang memastikan kurir benar-benar berada di lokasi tujuan sebelum bisa menandai pengiriman sebagai selesai, dan (2) penyusunan dokumen QA Test Cases untuk seluruh fitur mobile app ini.

**Kata kunci yang harus kamu kuasai:** geolocator, Geolocator.distanceBetween(), geofence, location permission, LocationAccuracy, maxDeliveryDistanceMeters, PodProgressStep.validatingDistance, GeofenceValidationScreen, QA Test Cases, test scenario matrix.

---

## 2. Poin Utama yang Harus Dibicarakan saat Presentasi

### 2.1 Alur Validasi Geolocation
1. Kurir tap "Antar Paket" → kamera terbuka (Rusdiyanto) → foto diambil.
2. Setelah konfirmasi foto → **`PodService._lockCourierPosition()`** dipanggil.
3. Sistem minta izin akses lokasi (`permission_handler`).
4. Jika izin ditolak → proses berhenti dengan pesan yang jelas.
5. Jika izin diberikan → `Geolocator.getCurrentPosition()` mengambil koordinat GPS kurir dengan akurasi tinggi (`LocationAccuracy.high`).
6. **`PodService._validateDistance()`** menghitung jarak antara posisi kurir dan koordinat tujuan paket.
7. Jika jarak > 250 meter → `PodFailure('Anda berada terlalu jauh dari lokasi pengiriman')` dilempar → UI tampilkan error, pengiriman dibatalkan.
8. Jika jarak ≤ 250 meter → lanjut ke upload foto.

### 2.2 Integrasi Hardware GPS
- Package `geolocator` mengakses GPS chip perangkat secara langsung.
- `LocationAccuracy.high` berarti menggunakan GPS + WiFi + Cellular triangulation.
- Ini lebih akurat dibanding `LocationAccuracy.low` yang hanya menggunakan network.
- Koordinat GPS kurir juga disertakan dalam payload pengiriman ke backend sebagai data audit.

### 2.3 Konfigurasi Radius via Environment Variable
- Radius maksimum 250 meter dikonfigurasi via `--dart-define=MAX_DELIVERY_DISTANCE_METERS=250`.
- Nilai ini bisa diubah tanpa recompile app — cukup ubah env var.
- Ini fleksibel untuk berbagai kondisi operasional (area padat vs jarang).

### 2.4 Halaman Geofence Validation
- Ada halaman khusus `GeofenceValidationScreen` di `lib/screens/geofence_validation_screen.dart` yang menampilkan validasi geolocation secara visual.
- Halaman ini dapat diakses dari Task Detail via route `/tasks/:id/geofence`.

### 2.5 QA Test Cases
- Kamu juga bertanggung jawab menyusun **Dokumen Skenario Pengujian** (QA Test Matrix) yang mencakup semua fitur mobile.
- Test cases mencakup: positive cases (happy path), negative cases (error handling), dan edge cases (batas kondisi).

---

## 3. Struktur Folder dan File

```
lib/
├── screens/
│   └── geofence_validation_screen.dart  ← UI visual validasi geofence
│
├── features/
│   └── tasks/
│       └── data/
│           └── pod_service.dart         ← _lockCourierPosition() + _validateDistance()
│                                           ← Langkah GPS dalam alur POD
│
├── core/
│   └── config/
│       └── app_env.dart                 ← maxDeliveryDistanceMeters (env var config)
│
└── router/
    └── app_router.dart                  ← Route /tasks/:id/geofence
```

**File utama yang berisi logika geolocation:**
- `lib/features/tasks/data/pod_service.dart` — method `_lockCourierPosition()` dan `_validateDistance()`
- `lib/core/config/app_env.dart` — konfigurasi `maxDeliveryDistanceMeters`
- `lib/screens/geofence_validation_screen.dart` — UI validasi geofence

---

## 4. Package Utama yang Digunakan

| Package | Versi | Fungsi |
|---|---|---|
| `geolocator` | `^14.0.2` | Mendapatkan koordinat GPS real-time dengan berbagai level akurasi |
| `geocoding` | `^3.0.0` | Konversi koordinat GPS → alamat teks (reverse geocoding) |
| `url_launcher` | `^6.3.2` | Buka Google Maps dengan koordinat tujuan untuk navigasi |

---

## 5. Penjelasan Kode Detail

### 5.1 `AppEnv.maxDeliveryDistanceMeters` — Konfigurasi Radius
**File:** `lib/core/config/app_env.dart`

```dart
class AppEnv {
  // Dibaca dari --dart-define=MAX_DELIVERY_DISTANCE_METERS=250
  static const maxDeliveryDistanceMeters = int.fromEnvironment(
    'MAX_DELIVERY_DISTANCE_METERS',
    defaultValue: 250, // default: 250 meter jika tidak diset
  );
  
  // Contoh env var lainnya yang relevan
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://nekologistic.lauraneval.dev',
  );
}
```

**Poin presentasi:** "Konfigurasi 250 meter ini tidak hardcoded di dalam kode, melainkan dibaca dari environment variable saat kompilasi. Tim operasional bisa mengubah radius pengiriman tanpa perlu developer merubah kode dan rebuild app."

---

### 5.2 `_lockCourierPosition` — Ambil GPS dengan Permission Check
**File:** `lib/features/tasks/data/pod_service.dart`

```dart
Future<Position> _lockCourierPosition() async {
  // Cek izin lokasi terlebih dahulu
  LocationPermission permission = await Geolocator.checkPermission();
  
  if (permission == LocationPermission.denied) {
    // Minta izin ke user
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw PodFailure('Izin lokasi diperlukan untuk menyelesaikan pengiriman');
    }
  }
  
  if (permission == LocationPermission.deniedForever) {
    // User pilih "jangan tanya lagi" → arahkan ke Settings
    throw PodFailure(
      'Izin lokasi ditolak permanen. '
      'Buka Pengaturan aplikasi untuk mengaktifkannya.'
    );
  }
  
  // Ambil posisi GPS dengan akurasi tinggi
  return await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high, // GPS chip + WiFi + Cellular
      timeLimit: Duration(seconds: 15), // timeout 15 detik
    ),
  );
}
```

**Poin presentasi:** "Ada tiga skenario permission yang ditangani: (1) izin belum diminta → minta dulu, (2) izin ditolak sementara → bisa minta lagi, (3) izin ditolak permanen → arahkan ke Settings OS karena kita tidak bisa minta lagi secara programatik."

---

### 5.3 `_validateDistance` — Geofence Check
**File:** `lib/features/tasks/data/pod_service.dart`

```dart
Future<void> _validateDistance(
  CourierBagPackage packageItem,
  Position courierPosition,
) async {
  // Jika paket tidak punya koordinat, lewati validasi (tidak semua paket punya GPS)
  if (packageItem.latitude == null || packageItem.longitude == null) {
    return; // validasi dilewati — tidak melempar error
  }
  
  // Hitung jarak menggunakan formula Haversine (jarak di permukaan bumi)
  final distanceMeters = Geolocator.distanceBetween(
    courierPosition.latitude,   // lat kurir
    courierPosition.longitude,  // lng kurir
    packageItem.latitude!,      // lat tujuan
    packageItem.longitude!,     // lng tujuan
  );
  
  // Cek apakah dalam radius yang diizinkan
  if (distanceMeters > AppEnv.maxDeliveryDistanceMeters) {
    throw PodFailure(
      'Anda berada ${distanceMeters.toStringAsFixed(0)} meter dari '
      'lokasi pengiriman. Maksimum ${AppEnv.maxDeliveryDistanceMeters} meter.',
    );
  }
  
  // Jika lolos validasi → lanjut ke upload foto
}
```

**Poin presentasi:** "Kita menggunakan `Geolocator.distanceBetween()` yang mengimplementasikan formula Haversine — formula matematika untuk menghitung jarak terpendek antara dua titik di permukaan bola (bumi). Lebih akurat dari Euclidean distance untuk koordinat GPS."

**Formula Haversine (untuk dipahami):**
```
d = 2r × arcsin(√(sin²(Δlat/2) + cos(lat1)×cos(lat2)×sin²(Δlon/2)))
```
Di mana `r` adalah radius bumi (~6371 km). Package `geolocator` mengimplementasikan ini secara internal.

---

### 5.4 Integrasi dalam Alur POD (Konteks Lengkap)
**File:** `lib/features/tasks/data/pod_service.dart`

```dart
Future<PodSubmissionResult> submitProofOfDelivery(
  CourierBagPackage packageItem,
  File preparedImageFile, {
  void Function(PodProgressStep, {int attempt, int maxAttempts})? onProgress,
}) async {
  // ... (langkah sebelumnya)
  
  // LANGKAH 3: Kunci posisi GPS
  onProgress?.call(PodProgressStep.lockingLocation);
  final Position position = await _lockCourierPosition(); // ← GPS aktif
  
  // LANGKAH 4: Validasi jarak ke tujuan
  onProgress?.call(PodProgressStep.validatingDistance);
  await _validateDistance(packageItem, position); // ← Geofence check
  
  // LANGKAH 5: Baru boleh upload foto (hanya jika lolos validasi)
  onProgress?.call(PodProgressStep.uploadingPhoto);
  final photoUrl = await _withRetry(() => _uploadPhoto(packageItem.id, preparedImageFile));
  
  // Koordinat kurir ikut dikirim ke backend untuk audit
  final request = CourierDeliveryRequest(
    status: 'DELIVERED',
    podImageUrl: photoUrl,
    courierLatitude: position.latitude,   // ← dari GPS
    courierLongitude: position.longitude, // ← dari GPS
  );
  await _apiClient.put('/courier/tasks/${packageItem.id}/deliver',
                       data: request.toJson());
  
  return PodSubmissionResult(
    photoUrl: photoUrl,
    latitude: position.latitude,
    longitude: position.longitude,
  );
}
```

**Poin presentasi:** "Validasi jarak adalah gatekeeper — jika kurir di luar radius 250m, proses berhenti di sini. Foto tidak akan diunggah dan status tidak akan diubah. Ini mencegah fraud pengiriman di mana kurir mengklaim sudah mengantarkan tanpa benar-benar ke lokasi."

---

### 5.5 Error Message yang Ramah Pengguna
**File:** `lib/features/tasks/data/pod_service.dart`

```dart
String _mapErrorMessage(dynamic error) {
  if (error is PodFailure) return error.message;
  
  final msg = error.toString().toLowerCase();
  if (msg.contains('location') || msg.contains('gps')) {
    return 'Tidak dapat mendapatkan lokasi GPS. Pastikan GPS diaktifkan.';
  }
  if (msg.contains('permission')) {
    return 'Izin lokasi diperlukan untuk pengiriman.';
  }
  if (msg.contains('timeout')) {
    return 'GPS timeout. Pastikan berada di area terbuka.';
  }
  if (msg.contains('network') || msg.contains('connection')) {
    return 'Koneksi internet tidak stabil. Periksa sinyal.';
  }
  return 'Terjadi kesalahan. Silakan coba lagi.';
}
```

---

## 6. Dokumen QA Test Cases

Sebagai bagian dari tanggung jawabmu, kamu menyusun dokumen skenario pengujian. Berikut adalah kerangka lengkap yang harus kamu kuasai:

---

### 6.1 Test Suite: Autentikasi (berkoordinasi dengan Galih)

| ID | Skenario | Langkah | Expected Result | Status |
|---|---|---|---|---|
| AUTH-01 | Login berhasil | Input email & password valid, tap Login | Masuk ke halaman Task List | ✅ |
| AUTH-02 | Login gagal — password salah | Input email valid, password salah | Pesan error ditampilkan, tetap di Login | ✅ |
| AUTH-03 | Login gagal — user tidak ada | Input email tidak terdaftar | Pesan "Email not found" ditampilkan | ✅ |
| AUTH-04 | Login tanpa internet | Matikan WiFi/data, coba login | Pesan "Tidak ada koneksi internet" | ✅ |
| AUTH-05 | Logout berhasil | Tap tombol logout dari profil | Kembali ke halaman Login, token terhapus | ✅ |
| AUTH-06 | Session expired — auto refresh | Tunggu token expired (atau paksa), lakukan aksi apapun | Token otomatis diperbarui, aksi berhasil tanpa login ulang | ✅ |
| AUTH-07 | Session expired — refresh gagal | Token refresh juga expired | Otomatis logout, redirect ke Login | ✅ |
| AUTH-08 | Buka app saat sudah login | Tutup app, buka ulang | Langsung masuk ke Task List (skip Login) | ✅ |

---

### 6.2 Test Suite: Task List (berkoordinasi dengan Naufal)

| ID | Skenario | Langkah | Expected Result | Status |
|---|---|---|---|---|
| TASK-01 | Lihat daftar tugas aktif | Login, buka Task List | ListView menampilkan daftar tugas dengan detail lengkap | ✅ |
| TASK-02 | Empty state | Semua tugas sudah DELIVERED | Tampilan "Tidak ada tugas" dengan ilustrasi | ✅ |
| TASK-03 | Pull-to-Refresh | Tarik layar ke bawah | Indikator refresh muncul, data terbaru dimuat | ✅ |
| TASK-04 | Tap ikon Maps | Tap ikon peta di kartu tugas | Google Maps terbuka dengan rute ke tujuan | ✅ |
| TASK-05 | Auto-polling | Tunggu 60 detik tanpa interaksi | Data otomatis diperbarui jika ada tugas baru | ✅ |
| TASK-06 | Notifikasi tugas baru | Admin tambah tugas baru di backend | Notifikasi lokal muncul di perangkat | ✅ |
| TASK-07 | Loading state | Buka Task List dengan koneksi lambat | Spinner/loading indicator tampil selama fetch | ✅ |
| TASK-08 | Error state | Matikan internet saat fetch | Pesan error + tombol "Coba Lagi" tampil | ✅ |
| TASK-09 | Tap kartu tugas | Tap salah satu kartu | Navigasi ke halaman detail tugas | ✅ |
| TASK-10 | Tugas tanpa koordinat | Tugas tidak memiliki lat/lng | Ikon Maps di-disable/tidak tampil | ✅ |

---

### 6.3 Test Suite: Proof of Delivery — Kamera & Upload (berkoordinasi dengan Rusdiyanto)

| ID | Skenario | Langkah | Expected Result | Status |
|---|---|---|---|---|
| POD-01 | POD sukses — happy path | Tap antar, ambil foto, konfirmasi, dalam radius | Paket berubah DELIVERED, foto tersimpan | ✅ |
| POD-02 | Batal ambil foto | Tap antar, lalu batal di kamera | Proses berhenti, status tidak berubah | ✅ |
| POD-03 | Batal di dialog konfirmasi | Ambil foto, lalu tap Batal | Proses berhenti, status tidak berubah | ✅ |
| POD-04 | Foto sudah DELIVERED | Coba tap "Antar" di paket DELIVERED | Tombol di-disable, tidak bisa diklik | ✅ |
| POD-05 | Upload gagal (internet putus) | Putus internet setelah foto diambil | Retry 3x, tampilkan error yang jelas | ✅ |
| POD-06 | Progres ditampilkan | Jalankan POD dengan koneksi normal | Progress bar dan pesan tahap tampil berurutan | ✅ |
| POD-07 | Semua paket diantar | Antar paket terakhir dalam tas | Otomatis kembali ke Task List | ✅ |
| POD-08 | File foto terlalu besar | Ambil foto resolusi sangat tinggi | Kompresi berjalan, upload tetap berhasil | ✅ |

---

### 6.4 Test Suite: Geolocation & Validasi Jarak (TANGGUNG JAWAB UTAMAMU)

| ID | Skenario | Langkah | Expected Result | Status |
|---|---|---|---|---|
| GEO-01 | Dalam radius — sukses | Kurir di lokasi yang sama dengan tujuan | Validasi lolos, proses lanjut | ✅ |
| GEO-02 | Di luar radius — gagal | Kurir > 250m dari tujuan | Error: "Anda berada Xm dari lokasi. Maks 250m" | ✅ |
| GEO-03 | Tepat di batas radius | Kurir persis 250m dari tujuan | Validasi lolos (batas inklusif) | ✅ |
| GEO-04 | GPS mati | Matikan GPS di Settings, coba POD | Pesan: "Aktifkan GPS di pengaturan" | ✅ |
| GEO-05 | Izin lokasi ditolak | Tolak permission saat diminta | Pesan: "Izin lokasi diperlukan" | ✅ |
| GEO-06 | Izin ditolak permanen | Pilih "Jangan tanya lagi" di dialog | Pesan: "Buka Pengaturan untuk aktifkan lokasi" | ✅ |
| GEO-07 | GPS timeout | GPS tidak mendapat sinyal dalam 15 detik | Pesan: "GPS timeout, coba di area terbuka" | ✅ |
| GEO-08 | Paket tanpa koordinat | Paket tidak memiliki lat/lng tujuan | Validasi jarak dilewati, proses lanjut | ✅ |
| GEO-09 | GeofenceValidationScreen | Buka layar validasi geofence | Tampilan map dengan posisi kurir dan radius | ✅ |
| GEO-10 | Koordinat kurir di payload | Selesaikan POD | Cek di backend: payload berisi lat/lng kurir | ✅ |
| GEO-11 | Backend tolak karena di luar radius | Backend return 403 | Pesan: "Kurir berada di luar radius pengiriman" | ✅ |

---

### 6.5 Test Suite: Edge Cases & Performance

| ID | Skenario | Langkah | Expected Result | Status |
|---|---|---|---|---|
| EDGE-01 | Background task polling | Tutup app 15 menit, ada tugas baru | Notifikasi muncul di status bar | ✅ |
| EDGE-02 | Multi-tap tombol | Tap "Antar Paket" berkali-kali cepat | Hanya satu proses yang berjalan | ✅ |
| EDGE-03 | Rotasi layar saat POD | Putar layar di tengah proses POD | State tidak hilang, proses lanjut | ✅ |
| EDGE-04 | App kill saat upload | Force close saat foto sedang upload | Foto tidak terupload, status tidak berubah | ✅ |
| EDGE-05 | Offline activity log | Matikan internet, lakukan POD | Log di-queue, terkirim saat online kembali | ✅ |
| EDGE-06 | Token expired saat submit POD | Token expired tepat saat PUT deliver | Silent refresh terjadi, request diulang | ✅ |
| EDGE-07 | Banyak paket dalam tas | Tas dengan 10+ paket | Semua paket tampil, scroll lancar | ✅ |

---

## 7. Alur Geolocation dalam Konteks Keseluruhan

```
User tap "Antar Paket"
    ↓
PodService.captureCompressedPhoto()  [Rusdiyanto]
    ↓
Dialog Konfirmasi Foto
    ↓
PodService.submitProofOfDelivery()
    │
    ├─[Langkah 3] _lockCourierPosition()     [Tsaqif]
    │     ├── checkPermission()              → izin lokasi
    │     ├── requestPermission() jika perlu → minta izin
    │     └── getCurrentPosition(
    │               accuracy: high,          → GPS + WiFi + Cell
    │               timeLimit: 15s           → timeout handling
    │         )
    │
    ├─[Langkah 4] _validateDistance()        [Tsaqif]
    │     ├── cek packageItem.hasCoordinates → skip jika null
    │     ├── Geolocator.distanceBetween()   → formula Haversine
    │     └── if distance > 250m → throw PodFailure  [validasi GAGAL]
    │
    ├─[Langkah 5] _uploadPhoto()             [Rusdiyanto]
    │     └── hanya jika lolos validasi!
    │
    └─[Langkah 6] PUT /courier/tasks/{id}/deliver
          payload: {
            status: 'DELIVERED',
            pod_image_url: <supabase-url>,
            courier_latitude: position.latitude,   ← dari GPS Tsaqif
            courier_longitude: position.longitude, ← dari GPS Tsaqif
          }
```

---

## 8. Kemungkinan Pertanyaan saat Presentasi

**Q: Kenapa radius 250 meter, bukan 100 atau 500?**
> A: Ini adalah parameter operasional yang didiskusikan dengan stakeholder. 250 meter memberikan toleransi untuk: gedung besar di mana pintu masuk kurir berbeda dari koordinat penerima, akurasi GPS yang bervariasi (GPS indoor bisa error hingga 50-100m), dan kurir yang parkir di dekat lokasi tapi tidak persis di depan pintu.

**Q: Formula apa yang dipakai untuk hitung jarak GPS?**
> A: `Geolocator.distanceBetween()` menggunakan formula Haversine yang menghitung jarak terpendek (great-circle distance) antara dua titik di permukaan bola. Ini lebih akurat dari jarak Euclidean (garis lurus di peta datar) terutama untuk jarak lebih dari beberapa kilometer.

**Q: Bagaimana backend tahu kurir di luar radius? Apakah hanya dicek di mobile?**
> A: Ada dua layer validasi. Mobile (kode kita) mencegah request dikirim jika kurir di luar radius. Tapi backend Next.js juga memvalidasi koordinat yang dikirim — jika backend mendeteksi koordinat tidak valid, ia mengembalikan HTTP 403. Kode kita di `MobileCourierRepository.fromDio()` mendeteksi 403 pada operasi deliver dan menampilkan pesan "Kurir berada di luar radius pengiriman". Ini defense in depth.

**Q: Apakah GPS selalu akurat? Bagaimana jika sinyal lemah?**
> A: Tidak selalu. Kita set `timeLimit: 15 seconds` di `getCurrentPosition()`. Jika GPS tidak mendapat fix dalam 15 detik, throw timeout exception yang ditangkap `_mapErrorMessage()` dengan pesan "GPS timeout, pastikan berada di area terbuka". Di dalam gedung atau area yang sangat padat sinyal GPS bisa lemah — ini adalah trade-off yang harus disampaikan ke operator.

**Q: Bagaimana jika kurir memalsukan GPS (GPS spoofing)?**
> A: Deteksi GPS spoofing di Flutter memerlukan teknik tambahan seperti mock location detection. Untuk saat ini, kita mengandalkan validasi backend sebagai defense kedua. Jika akurasi GPS (`position.accuracy`) terlalu tinggi (misal: 0.0 meter — tidak realistis), itu bisa menjadi indikator spoofing. Ini bisa menjadi peningkatan di versi berikutnya.
