# Panduan Presentasi: Muhammad Rusdiyanto
## Topik: Proof of Delivery Berbasis Kamera

---

## 1. Gambaran Umum Tanggung Jawab

Kamu bertanggung jawab atas **seluruh alur Proof of Delivery (POD)** — fitur inti yang membuktikan bahwa paket telah berhasil diantarkan. Tanggung jawabmu mencakup: desain antarmuka halaman detail pengantaran, penggunaan kamera untuk mengambil foto bukti, kompresi foto sebelum diunggah, upload langsung ke Supabase Storage, dan pemanggilan API backend untuk mengubah status paket menjadi DELIVERED.

**Kata kunci yang harus kamu kuasai:** image_picker, flutter_image_compress, Supabase Storage, bucket, progress tracking, PodProgressStep, PodService, CourierBagDetailPage, foto kompresi JPEG.

---

## 2. Poin Utama yang Harus Dibicarakan saat Presentasi

### 2.1 Alur UI/UX Detail Pengantaran
1. User tap kartu tugas di Task List → masuk ke `CourierBagDetailPage`.
2. Halaman menampilkan: kode tas, kota tujuan, status, dan daftar paket di dalamnya.
3. Setiap paket memiliki tombol **"Antar Paket"** (disabled jika sudah DELIVERED).
4. User tap "Antar Paket" → **kamera terbuka otomatis**.
5. User ambil foto (atau batalkan).
6. Muncul **dialog konfirmasi** dengan preview foto dan tombol "Konfirmasi Pengiriman".
7. Setelah konfirmasi → **progress bar** muncul dengan 7 tahap:
   - Membuka kamera
   - Mengompresi foto
   - Mengunci lokasi GPS
   - Memvalidasi jarak
   - Mengunggah foto
   - Memperbarui status
   - Selesai
8. Jika semua paket sudah diantar → kembali ke halaman sebelumnya otomatis.

### 2.2 Integrasi Hardware Kamera
- Package `image_picker` digunakan untuk membuka kamera native perangkat.
- Foto yang diambil dikompresi menggunakan `flutter_image_compress` ke format JPEG dengan:
  - Kualitas: 75-80 (dari skala 0-100)
  - Resolusi minimum: 1280×1280 piksel
  - Ini menghemat bandwidth upload dan ruang penyimpanan di Supabase.

### 2.3 Upload ke Supabase Storage
- Foto **tidak** dikirim ke backend Next.js sebagai form data, melainkan **langsung diunggah ke Supabase Storage** (seperti AWS S3 tapi yang dikelola Supabase).
- Struktur path file di bucket: `courier/{packageId}/{timestamp}.jpg`
- Setelah upload berhasil → dapatkan **public URL** foto.
- URL ini kemudian dikirim ke backend bersama data pengiriman lainnya.

### 2.4 Notifikasi Status ke Backend
- Setelah mendapat URL foto → `PUT /courier/tasks/{packageId}/deliver` dengan payload:
  - `status: 'DELIVERED'`
  - `podImageUrl:` URL foto dari Supabase Storage
  - `courierLatitude, courierLongitude:` GPS kurir saat pengiriman
  - `deliveredAt:` waktu pengiriman

### 2.5 Retry Logic untuk Keandalan
- Upload foto dan update status memiliki **3 kali percobaan ulang** dengan exponential backoff jika gagal.
- Ini penting karena jaringan di lapangan sering tidak stabil.

---

## 3. Struktur Folder dan File

```
lib/
├── screens/
│   └── pod_screen.dart                   ← UI layar POD (kamera + review foto)
│
├── features/
│   ├── tasks/
│   │   ├── data/
│   │   │   ├── pod_service.dart          ← INTI: Orkestrasi seluruh alur POD
│   │   │   └── activity_log_queue_service.dart ← Logging offline-first
│   │   ├── domain/
│   │   │   └── courier_bag_models.dart   ← Model CourierBagTask, CourierBagPackage,
│   │   │                                    CourierDeliveryRequest, dll.
│   │   └── presentation/
│   │       └── courier_bag_detail_page.dart ← UI halaman detail tas + trigger POD
│   │
│   └── mobile/
│       └── data/
│           └── proof_upload_service.dart ← Upload foto ke Supabase Storage
│
├── services/
│   └── delivery_service.dart             ← Alternatif: upload multipart + confirm delivery
│
└── models/
    └── delivery_result.dart              ← Model hasil konfirmasi pengiriman
```

---

## 4. Package Utama yang Digunakan

| Package | Versi | Fungsi |
|---|---|---|
| `image_picker` | `^1.2.0` | Membuka kamera native untuk mengambil foto POD |
| `camera` | `^0.11.2` | Akses kamera tingkat rendah (digunakan bersama image_picker) |
| `flutter_image_compress` | `^2.4.0` | Kompres foto ke JPEG sebelum upload (hemat bandwidth) |
| `supabase_flutter` | `^2.10.1` | Upload foto langsung ke Supabase Storage bucket |
| `dio` | `^5.9.0` | PUT request ke backend setelah foto terupload |
| `geolocator` | `^14.0.2` | Kunci posisi GPS kurir saat pengiriman (dipakai bersama Tsaqif) |
| `path_provider` | (transitive) | Menyimpan file foto ter-compress sementara di temp directory |

---

## 5. Penjelasan Kode Detail

### 5.1 `PodService` — Otak dari Seluruh Alur POD
**File:** `lib/features/tasks/data/pod_service.dart`

Ini adalah service paling penting di tanggung jawabmu. Dia mengorkestrasi 7 langkah POD secara berurutan:

```dart
class PodService {
  final ApiClient _apiClient;
  final ImagePicker _imagePicker;
  final ActivityLogQueueService _logQueue;
  
  // LANGKAH 1: Buka kamera dan kompresi foto
  Future<File> captureCompressedPhoto({
    void Function(PodProgressStep step)? onProgress
  }) async {
    onProgress?.call(PodProgressStep.openingCamera);
    
    // Buka kamera native
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100, // ambil kualitas penuh dulu, kompresi manual nanti
    );
    if (pickedFile == null) throw PodFailure('Pengambilan foto dibatalkan');
    
    onProgress?.call(PodProgressStep.compressingPhoto);
    
    // Kompresi manual untuk kontrol lebih baik
    return await _compressPhoto(File(pickedFile.path));
  }
  
  // LANGKAH 2-7: Submit seluruh bukti pengiriman
  Future<PodSubmissionResult> submitProofOfDelivery(
    CourierBagPackage packageItem,
    File preparedImageFile, {
    void Function(PodProgressStep, {int attempt, int maxAttempts})? onProgress,
  }) async {
    // Langkah 2a: Flush pending activity logs
    await _logQueue.flush(...);
    
    // Langkah 3: Kunci posisi GPS
    onProgress?.call(PodProgressStep.lockingLocation);
    final position = await _lockCourierPosition();
    
    // Langkah 4: Validasi jarak (Tsaqif punya ini juga — terintegrasi di sini)
    onProgress?.call(PodProgressStep.validatingDistance);
    await _validateDistance(packageItem, position);
    
    // Langkah 5: Upload foto ke Supabase Storage (dengan retry)
    onProgress?.call(PodProgressStep.uploadingPhoto, attempt: 1, maxAttempts: 3);
    final photoUrl = await _withRetry(
      () => _uploadPhoto(packageItem.id, preparedImageFile),
      maxAttempts: 3,
    );
    
    // Langkah 6: Update status paket ke DELIVERED
    onProgress?.call(PodProgressStep.updatingStatus);
    final request = CourierDeliveryRequest(
      status: 'DELIVERED',
      podImageUrl: photoUrl,
      courierLatitude: position.latitude,
      courierLongitude: position.longitude,
    );
    await _apiClient.put('/courier/tasks/${packageItem.id}/deliver', 
                         data: request.toJson());
    
    // Langkah 7: Log aktivitas
    onProgress?.call(PodProgressStep.completed);
    await _tryLogActivity(packageItem, photoUrl, position);
    
    return PodSubmissionResult(
      photoUrl: photoUrl, 
      latitude: position.latitude, 
      longitude: position.longitude
    );
  }
}
```

**Poin presentasi:** "Seluruh alur POD dikapsulasi dalam satu service. `CourierBagDetailPage` cukup memanggil dua fungsi: `captureCompressedPhoto()` dan `submitProofOfDelivery()`. Ini clean separation of concerns — UI tidak tahu detail teknis upload atau GPS."

---

### 5.2 `PodProgressStep` — Enum Progress Tracking
**File:** `lib/features/tasks/data/pod_service.dart`

```dart
enum PodProgressStep {
  openingCamera,
  compressingPhoto,
  lockingLocation,
  validatingDistance,
  uploadingPhoto,
  updatingStatus,
  completed,
}
```

Dan di `CourierBagDetailPage`, setiap step di-mapping ke pesan dan progress value:

```dart
void _onProgress(PodProgressStep step, {int attempt = 1, int maxAttempts = 1}) {
  setState(() {
    switch (step) {
      case PodProgressStep.openingCamera:
        _progressMessage = 'Membuka kamera...';
        _progressValue = 0.1;
      case PodProgressStep.compressingPhoto:
        _progressMessage = 'Mengompresi foto...';
        _progressValue = 0.25;
      case PodProgressStep.lockingLocation:
        _progressMessage = 'Mengunci lokasi GPS...';
        _progressValue = 0.40;
      case PodProgressStep.validatingDistance:
        _progressMessage = 'Memvalidasi jarak...';
        _progressValue = 0.55;
      case PodProgressStep.uploadingPhoto:
        _progressMessage = 'Mengunggah foto ($attempt/$maxAttempts)...';
        _progressValue = 0.70;
      case PodProgressStep.updatingStatus:
        _progressMessage = 'Memperbarui status paket...';
        _progressValue = 0.90;
      case PodProgressStep.completed:
        _progressMessage = 'Pengiriman berhasil!';
        _progressValue = 1.0;
    }
  });
}
```

**Poin presentasi:** "Progress bar yang informatif adalah kunci UX yang baik untuk operasi yang membutuhkan waktu. User tahu sistem sedang bekerja dan di tahap mana — tidak hanya menunggu tanpa informasi."

---

### 5.3 `_compressPhoto` — Kompresi JPEG
**File:** `lib/features/tasks/data/pod_service.dart`

```dart
Future<File> _compressPhoto(File originalFile) async {
  final tempDir = await getTemporaryDirectory();
  final targetPath = 
    '${tempDir.path}/pod_${DateTime.now().millisecondsSinceEpoch}.jpg';
  
  final result = await FlutterImageCompress.compressAndGetFile(
    originalFile.path,
    targetPath,
    quality: 75,        // 75% kualitas JPEG — titik manis antara kualitas dan ukuran
    minWidth: 1280,     // lebar minimum 1280px
    minHeight: 1280,    // tinggi minimum 1280px
    format: CompressFormat.jpeg,
  );
  
  // Fallback: jika kompresi gagal, gunakan file asli
  return result != null ? File(result.path) : originalFile;
}
```

**Poin presentasi:** "Kamera modern menghasilkan foto 5-15 MB. Dengan kompresi ke quality 75, ukuran turun ke sekitar 200-500 KB — pengurangan hingga 95%. Ini krusial untuk kurir yang menggunakan data seluler."

---

### 5.4 `_uploadPhoto` — Upload ke Supabase Storage
**File:** `lib/features/tasks/data/pod_service.dart`

```dart
Future<String> _uploadPhoto(String packageId, File imageFile) async {
  // Sinkronisasi session Supabase (Supabase Storage butuh auth token-nya sendiri)
  await _syncSupabaseSession();
  
  final client = Supabase.instance.client;
  final bucket = AppEnv.podBucket; // dari env var POD_BUCKET
  
  // Path: courier/{packageId}/{timestamp}.jpg
  final filePath = 
    'courier/$packageId/${DateTime.now().millisecondsSinceEpoch}.jpg';
  
  await client.storage
    .from(bucket)
    .uploadBinary(
      filePath,
      await imageFile.readAsBytes(),
      fileOptions: const FileOptions(contentType: 'image/jpeg'),
    );
  
  // Dapatkan URL publik foto
  return client.storage.from(bucket).getPublicUrl(filePath);
}
```

**Poin presentasi:** "Foto diunggah langsung dari Flutter ke Supabase Storage — tidak melalui server Next.js. Ini lebih efisien karena mengurangi beban server dan biaya transfer data. Yang dikirim ke Next.js hanyalah URL-nya."

---

### 5.5 `_syncSupabaseSession` — Sinkronisasi Token
**File:** `lib/features/tasks/data/pod_service.dart`

```dart
Future<void> _syncSupabaseSession() async {
  // Supabase Storage butuh session Supabase sendiri, bukan JWT dari backend kami.
  // Kita inject token custom auth kami ke dalam Supabase session.
  final bearerToken = await _apiClient.authService.getBearerToken();
  if (bearerToken != null) {
    await Supabase.instance.client.auth.setSession(bearerToken);
  }
}
```

**Poin presentasi:** "Ini adalah jembatan antara dua sistem auth: JWT dari backend Next.js kami, dan session Supabase yang dibutuhkan untuk mengakses Storage. RLS (Row Level Security) Supabase mengharuskan user ter-autentikasi untuk upload."

---

### 5.6 `_withRetry` — Retry Logic
**File:** `lib/features/tasks/data/pod_service.dart`

```dart
Future<T> _withRetry<T>(
  Future<T> Function() operation, {
  int maxAttempts = 3,
}) async {
  int attempt = 0;
  while (true) {
    attempt++;
    try {
      return await operation();
    } catch (e) {
      if (attempt >= maxAttempts) rethrow; // lempar error setelah 3 kali gagal
      // Exponential backoff: 1s, 2s, 4s
      await Future.delayed(Duration(seconds: 1 << (attempt - 1)));
    }
  }
}
```

**Poin presentasi:** "Exponential backoff berarti percobaan pertama ulang setelah 1 detik, kedua setelah 2 detik, ketiga setelah 4 detik. Ini adalah teknik standar untuk menangani gangguan jaringan sementara tanpa membanjiri server."

---

### 5.7 `CourierBagDetailPage` — Trigger dan Dialog Konfirmasi
**File:** `lib/features/tasks/presentation/courier_bag_detail_page.dart`

```dart
Future<void> _submitPod(CourierBagPackage packageItem) async {
  setState(() => _isSubmitting = true);
  
  try {
    // Langkah 1: Ambil dan kompresi foto
    final photoFile = await _podService.captureCompressedPhoto(
      onProgress: (step) => _onProgress(step),
    );
    
    // Tampilkan dialog konfirmasi dengan preview foto
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Pengiriman'),
        content: Image.file(photoFile),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), 
                     child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), 
                         child: const Text('Konfirmasi')),
        ],
      ),
    );
    
    if (confirmed != true) return; // User batal
    
    // Langkah 2-7: Submit dengan progress tracking
    await _podService.submitProofOfDelivery(
      packageItem,
      photoFile,
      onProgress: _onProgress, // update progress bar
    );
    
    // Berhasil → reload data tas
    await _reloadBagDetail();
    
  } on PodFailure catch (e) {
    // Error yang diketahui (jarak terlalu jauh, foto dibatalkan, dll.)
    _showErrorSnackbar(e.message);
  } catch (e) {
    _showErrorSnackbar('Terjadi kesalahan tidak terduga: $e');
  } finally {
    setState(() => _isSubmitting = false);
  }
}
```

**Poin presentasi:** "Ada step konfirmasi sebelum pengiriman dimulai. Ini mencegah pengiriman yang tidak sengaja — kurir harus secara eksplisit melihat preview foto dan menekan tombol konfirmasi."

---

### 5.8 `CourierDeliveryRequest` — Payload ke Backend
**File:** `lib/features/tasks/domain/courier_bag_models.dart`

```dart
class CourierDeliveryRequest {
  final String status;          // selalu 'DELIVERED'
  final String podImageUrl;     // URL dari Supabase Storage
  final double courierLatitude; // GPS kurir saat antar
  final double courierLongitude;
  final double? targetLatitude; // Koordinat tujuan (opsional)
  final double? targetLongitude;
  final DateTime? deliveredAt;  // Waktu pengiriman
  
  Map<String, dynamic> toJson() => {
    'status': status,
    'pod_image_url': podImageUrl,
    'courier_latitude': courierLatitude,
    'courier_longitude': courierLongitude,
    if (targetLatitude != null) 'target_latitude': targetLatitude,
    if (targetLongitude != null) 'target_longitude': targetLongitude,
    if (deliveredAt != null) 'delivered_at': deliveredAt!.toIso8601String(),
  };
}
```

**Poin presentasi:** "Payload ini dikirim melalui `PUT /courier/tasks/{packageId}/deliver`. Backend menerima data lengkap: status baru, bukti foto, lokasi kurir, dan timestamp — semua yang dibutuhkan untuk audit trail pengiriman."

---

## 6. Alur Lengkap: Tap "Antar Paket" → Status DELIVERED

```
User tap "Antar Paket" di CourierBagDetailPage
    ↓
_submitPod(packageItem) dipanggil
    ↓
PodService.captureCompressedPhoto()
    ├── ImagePicker.pickImage(source: ImageSource.camera)
    ├── Kamera native terbuka
    ├── User ambil foto
    └── FlutterImageCompress → JPEG quality 75, min 1280x1280
    ↓
Dialog konfirmasi muncul (preview foto)
    ↓
User tap "Konfirmasi"
    ↓
PodService.submitProofOfDelivery()
    ├── ActivityLogQueue.flush()          → kirim log offline yang tertunda
    ├── _lockCourierPosition()            → Geolocator.getCurrentPosition()
    ├── _validateDistance()               → cek jarak ≤ 250 meter
    ├── _withRetry(_uploadPhoto())        → upload ke Supabase Storage bucket
    │   └── path: courier/{id}/{ts}.jpg  → dapat public URL
    └── ApiClient.put('/courier/tasks/{id}/deliver', {
              status: DELIVERED,
              pod_image_url: <supabase-url>,
              courier_latitude: <lat>,
              courier_longitude: <lng>
          })
    ↓
PodSubmissionResult berhasil
    ↓
_reloadBagDetail() → refresh tampilan halaman detail
    ↓
Jika semua paket DELIVERED → Navigator.pop() → kembali ke Task List
```

---

## 7. Kemungkinan Pertanyaan saat Presentasi

**Q: Kenapa foto diupload ke Supabase, bukan langsung ke backend Next.js?**
> A: Dua alasan: (1) Efisiensi — upload binary besar langsung ke object storage lebih cepat dan murah daripada melalui server; (2) Skalabilitas — Supabase Storage dirancang untuk menyimpan file dalam jumlah besar dengan CDN bawaan, sedangkan server Next.js tidak cocok untuk menyimpan file permanen.

**Q: Apa yang terjadi kalau upload foto gagal karena internet putus?**
> A: `_withRetry()` mencoba ulang maksimal 3 kali dengan jeda 1s/2s/4s. Jika semua gagal, `PodFailure` dilempar dengan pesan yang jelas ke UI. Status paket TIDAK diubah — tidak ada partial state yang inkonsisten.

**Q: Bagaimana kalau user cancel di tengah proses (menutup app)?**
> A: Karena update status ke backend adalah langkah terakhir (setelah foto sudah terupload), jika dibatalkan sebelum langkah itu, status tetap belum DELIVERED. User bisa mengulang POD dari awal. Jika dibatalkan setelah `PUT /deliver` sudah terkirim, status sudah berubah dan itu konsisten.

**Q: Apakah ada risiko duplikasi foto jika retry?**
> A: Setiap retry menggunakan timestamp baru sebagai nama file (`{timestamp}.jpg`), sehingga file sebelumnya yang mungkin terupload sebagian tidak ditimpa. File "gagal" bisa menumpuk di storage, tapi ini dapat dibersihkan oleh lifecycle policy di Supabase.

**Q: Mengapa kualitas kompresi 75, bukan 50 atau 90?**
> A: Dari pengujian empiris, quality 75 adalah titik manis di mana foto masih jelas untuk audit (wajah penerima, tanda tangan) namun ukuran file cukup kecil untuk upload cepat di jaringan 3G/4G yang umum di lapangan pengiriman.
