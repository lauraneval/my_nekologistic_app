# Panduan Presentasi: Naufal Thoriq Muzhaffar
## Topik: Manajemen Tugas & Rute Kurir

---

## 1. Gambaran Umum Tanggung Jawab

Kamu bertanggung jawab atas **tampilan dan pengelolaan daftar tugas pengiriman** di sisi mobile. Mulai dari halaman Task List dengan Card UI yang dinamis, pemanggilan API ke backend untuk mengambil data tugas, hingga penanganan state Loading dan Empty State yang baik dari sisi UX.

**Kata kunci yang harus kamu kuasai:** ListView.builder, Card UI, FutureBuilder, Dio GET request, query parameter, Loading State, Empty State, TaskProvider (ChangeNotifier), auto-polling.

---

## 2. Poin Utama yang Harus Dibicarakan saat Presentasi

### 2.1 Alur UI/UX Task List
1. User berhasil login → diarahkan ke halaman Task List (`/tasks`).
2. Aplikasi langsung menampilkan **Loading State** (indikator atau shimmer) sambil mengambil data dari API.
3. Data tiba → ListView menampilkan daftar kartu tugas (`TaskCard`), masing-masing berisi: kode tas, kota tujuan, jumlah paket, status, dan tombol aksi.
4. Jika tidak ada tugas → tampilkan **Empty State** dengan ilustrasi dan teks "Tidak ada tugas saat ini".
5. User menarik layar ke bawah (Pull-to-Refresh) → data diperbarui.
6. User tap tombol Maps di kartu → membuka Google Maps via `url_launcher`.
7. User tap kartu → masuk ke halaman Detail Tugas (`TaskDetailScreen`).

### 2.2 Pemanggilan API dengan Dio
- Endpoint utama: `GET /mobile/tasks` — mengambil semua tugas kurir yang sedang aktif.
- Endpoint detail: `GET /mobile/tasks/{id}` — mengambil detail satu tugas tertentu.
- Semua request sudah otomatis menyisipkan Bearer Token via `ApiClient` Interceptor (dikerjakan Galih).
- Request juga bisa membawa **query parameter** (misal: `status=OUT_FOR_DELIVERY`) untuk filter di sisi backend.

### 2.3 Dynamic ListView dengan Card
- Menggunakan `ListView.builder()` agar hanya widget yang terlihat di layar yang di-render (efisiensi memori).
- Setiap item ditampilkan oleh widget `TaskCard` yang menerima satu objek `MobileTaskItem` atau `CourierBagTask`.
- Status pengiriman ditampilkan dengan warna berbeda melalui widget `StatusBadge`.

### 2.4 Auto-Polling Setiap 60 Detik
- `TaskProvider` secara otomatis melakukan polling ke API setiap 60 detik selama user sedang login.
- Jika ada tugas baru yang belum pernah dilihat → sistem menampilkan notifikasi lokal.
- Polling berhenti otomatis saat user logout.

### 2.5 Background Polling via WorkManager
- Bahkan saat aplikasi ditutup, WorkManager menjalankan polling setiap 15 menit untuk memeriksa tugas baru.
- Ini memastikan kurir tidak melewatkan tugas baru meskipun tidak sedang membuka aplikasi.

---

## 3. Struktur Folder dan File

```
lib/
├── screens/
│   ├── task_list_screen.dart           ← UI utama Task List (dengan Provider)
│   └── task_detail_screen.dart         ← UI detail satu tugas
│
├── features/
│   ├── tasks/
│   │   ├── domain/
│   │   │   ├── courier_bag_models.dart ← Model data: CourierBagTask, CourierBagPackage
│   │   │   └── courier_task.dart       ← Model sederhana CourierTask
│   │   ├── data/
│   │   │   └── courier_bag_api_client.dart ← API calls ke /courier/tasks/*
│   │   └── presentation/
│   │       └── task_list_page.dart     ← Versi lama task list (referensi)
│   │
│   └── mobile/
│       ├── domain/
│       │   └── mobile_models.dart      ← Model MobileTaskItem, MobileTaskBoardResponse
│       └── data/
│           ├── mobile_courier_api_client.dart ← API calls ke /mobile/tasks/*
│           └── mobile_courier_repository.dart ← Error-handling wrapper (MobileApiException)
│
├── providers/
│   └── task_provider.dart              ← State management + auto-polling (ChangeNotifier)
│
├── services/
│   └── api_service.dart                ← Facade yang menyatukan repository + delivery service
│
├── widgets/
│   ├── task_card.dart                  ← Widget kartu satu tugas
│   ├── status_badge.dart               ← Badge warna berdasarkan status
│   └── loading_overlay.dart            ← Loading indicator overlay
│
└── models/
    └── delivery_result.dart            ← Model hasil konfirmasi pengiriman
```

---

## 4. Package Utama yang Digunakan

| Package | Versi | Fungsi |
|---|---|---|
| `dio` | `^5.9.0` | HTTP GET request ke `/mobile/tasks` dengan Bearer Token otomatis |
| `provider` | `^6.1.2` | `TaskProvider` sebagai state management (auto-polling, notifikasi) |
| `go_router` | `^14.6.3` | Navigasi dari Task List ke Task Detail (`/tasks/:id`) |
| `url_launcher` | `^6.3.2` | Buka Google Maps dengan koordinat paket |
| `flutter_local_notifications` | `^18.0.1` | Notifikasi lokal saat ada tugas baru ditemukan polling |
| `workmanager` | `^0.9.0` | Background polling setiap 15 menit meski app ditutup |
| `shared_preferences` | `^2.3.5` | Simpan ID tugas yang sudah diketahui (deteksi tugas baru) |

---

## 5. Penjelasan Kode Detail

### 5.1 `MobileTaskItem` — Model Data Tugas
**File:** `lib/features/mobile/domain/mobile_models.dart`

```dart
class MobileTaskItem {
  final String id;
  final String title;
  final String status;         // OUT_FOR_DELIVERY, IN_TRANSIT, DELIVERED, dll.
  final double? latitude;
  final double? longitude;
  
  // Info paket
  final String? recipientName;
  final String? recipientAddress;
  final String? recipientPhone;
  
  // Info tas/bag
  final String? bagCode;
  
  // Cek apakah koordinat tersedia untuk fitur Maps
  bool get hasCoordinates => latitude != null && longitude != null;
  
  // Factory constructor dengan multi-key fallback
  // (handles variasi field dari backend: 'id' vs 'task_id' vs 'uuid')
  factory MobileTaskItem.fromJson(Map<String, dynamic> json) { ... }
}
```

**Poin presentasi:** "Field mapping menggunakan multi-key fallback karena response JSON dari backend bisa bervariasi tergantung endpoint. Contoh: field ID bisa berupa `'id'`, `'task_id'`, atau `'uuid'` — kode kita handle semua kemungkinan ini."

---

### 5.2 `MobileCourierApiClient` — Pemanggilan API
**File:** `lib/features/mobile/data/mobile_courier_api_client.dart`

```dart
class MobileCourierApiClient {
  final ApiClient _apiClient; // sudah punya Bearer Token Interceptor
  
  // GET /mobile/tasks — ambil semua tugas aktif + antrian
  Future<MobileTaskBoardResponse> fetchTaskBoard() async {
    final response = await _apiClient.get('/mobile/tasks');
    return MobileTaskBoardResponse.fromJson(response.data);
  }
  
  // GET /mobile/tasks/{id} — ambil detail satu tugas
  Future<MobileTaskDetailResponse> fetchTaskDetail(String id) async {
    final response = await _apiClient.get('/mobile/tasks/$id');
    return MobileTaskDetailResponse.fromJson(response.data);
  }
  
  // PATCH /mobile/tasks/{id}/accept — kurir terima tugas
  Future<void> acceptTask(String id) async {
    await _apiClient.patch(
      '/mobile/tasks/$id/accept',
      data: {'status': 'IN_TRANSIT'},
    );
  }
}
```

**Poin presentasi:** "Kita tidak perlu menambahkan header Authorization secara manual di sini. `ApiClient` sudah menanganinya melalui Dio Interceptor — separation of concerns yang bersih."

---

### 5.3 `CourierBagApiClient` — API Versi Kurir
**File:** `lib/features/tasks/data/courier_bag_api_client.dart`

```dart
class CourierBagApiClient {
  final ApiClient _apiClient;
  
  // GET /courier/tasks?status=OUT_FOR_DELIVERY — dengan query parameter
  Future<List<CourierBagTask>> fetchBagTasks() async {
    final response = await _apiClient.get(
      '/courier/tasks',
      queryParameters: {'status': 'OUT_FOR_DELIVERY'}, // ← query param
    );
    final List list = response.data['data'] ?? response.data;
    return list.map((e) => CourierBagTask.fromJson(e)).toList();
  }
  
  // GET /courier/tasks/{bagId}/timeline
  Future<CourierBagTimelineResponse> fetchBagTimeline(String bagId) async {
    final response = await _apiClient.get('/courier/tasks/$bagId/timeline');
    return CourierBagTimelineResponse.fromJson(response.data);
  }
}
```

**Poin presentasi:** "Query parameter `?status=OUT_FOR_DELIVERY` memfilter data di server — tidak perlu mengambil semua data lalu filter di client. Ini lebih efisien untuk bandwidth."

---

### 5.4 `MobileCourierRepository` — Error Handling
**File:** `lib/features/mobile/data/mobile_courier_repository.dart`

```dart
class MobileApiException implements Exception {
  final int? statusCode;
  final String message;
  
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden    => statusCode == 403;
  bool get isNotFound     => statusCode == 404;
  bool get isServerError  => statusCode != null && statusCode! >= 500;
  
  // 403 di operasi 'deliver' berarti kurir di luar radius
  factory MobileApiException.fromDio(DioException e, {String? operation}) {
    if (e.response?.statusCode == 403 && operation == 'deliver') {
      return MobileApiException(
        statusCode: 403, 
        message: 'Kurir berada di luar radius pengiriman',
      );
    }
    // ... pemetaan error lainnya
  }
}

class MobileCourierRepository {
  Future<T> _handle<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw MobileApiException.fromDio(e);
    }
  }
  
  Future<MobileTaskBoardResponse> getTasks() =>
    _handle(() => _apiClient.fetchTaskBoard());
}
```

**Poin presentasi:** "Repository layer mengkonversi `DioException` yang low-level menjadi `MobileApiException` yang lebih mudah ditangani di UI. UI tidak perlu tahu Dio sama sekali — hanya perlu cek `exception.isUnauthorized` atau tampilkan `exception.message`."

---

### 5.5 `TaskProvider` — State Management + Auto-Polling
**File:** `lib/providers/task_provider.dart`

```dart
class TaskProvider extends ChangeNotifier {
  MobileTaskBoardResponse? _board;
  bool _isLoading = false;
  String? _error;
  Timer? _pollingTimer;
  List<MobileTaskItem> _newTasks = []; // tugas yang belum pernah dilihat
  
  // Getter untuk UI
  List<MobileTaskItem> get activeTasks => _board?.activeTasks ?? [];
  List<MobileTaskItem> get queueTasks  => _board?.queueTasks  ?? [];
  bool get isLoading => _isLoading;
  String? get error  => _error;
  
  // Dipanggil dari UI dan dari polling timer
  Future<void> loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // ← trigger rebuild di UI untuk tampilkan Loading
    
    try {
      _board = await _apiService.getTasks();
      await _detectNewTasks(); // bandingkan dengan ID yang tersimpan
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners(); // ← trigger rebuild untuk tampilkan data / error
    }
  }
  
  // Auto-polling setiap 60 detik
  void startPolling() {
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => loadTasks(),
    );
  }
  
  void stopPolling() => _pollingTimer?.cancel();
  
  // Deteksi tugas baru vs yang sudah diketahui
  Future<void> _detectNewTasks() async {
    final knownIds = await _loadKnownTaskIds(); // dari SharedPreferences
    _newTasks = activeTasks.where((t) => !knownIds.contains(t.id)).toList();
    if (_newTasks.isNotEmpty) {
      await _notificationService.showNewTaskNotification(_newTasks.length);
    }
    await _saveKnownTaskIds(activeTasks.map((t) => t.id).toSet());
  }
}
```

**Poin presentasi:** "Ada dua layer polling: foreground (60 detik via `Timer`) dan background (15 menit via WorkManager). Foreground polling menggunakan `Timer.periodic()` yang dimulai saat login dan dihentikan saat logout."

---

### 5.6 Penanganan Loading dan Empty State di UI

**File:** `lib/screens/task_list_screen.dart`

```dart
class TaskListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        // State 1: LOADING
        if (provider.isLoading && provider.activeTasks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // State 2: ERROR
        if (provider.error != null) {
          return Center(
            child: Column(children: [
              Text('Terjadi kesalahan: ${provider.error}'),
              ElevatedButton(
                onPressed: provider.loadTasks,
                child: const Text('Coba Lagi'),
              ),
            ]),
          );
        }
        
        // State 3: EMPTY
        if (provider.activeTasks.isEmpty) {
          return const Center(
            child: Column(children: [
              Icon(Icons.inbox_outlined, size: 64),
              Text('Tidak ada tugas aktif saat ini'),
            ]),
          );
        }
        
        // State 4: DATA ADA — tampilkan ListView
        return RefreshIndicator(
          onRefresh: provider.loadTasks,
          child: ListView.builder(
            itemCount: provider.activeTasks.length,
            itemBuilder: (context, index) {
              final task = provider.activeTasks[index];
              return TaskCard(
                task: task,
                onTap: () => context.go('/tasks/${task.id}'),
                onMapsTap: task.hasCoordinates
                    ? () => _openMaps(task.latitude!, task.longitude!)
                    : null,
              );
            },
          ),
        );
      },
    );
  }
  
  void _openMaps(double lat, double lng) {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
```

**Poin presentasi:** "Ada 4 state yang harus ditangani UI dengan benar: Loading, Error, Empty, dan Data. `Consumer<TaskProvider>` dari package `provider` membuat widget rebuild otomatis setiap kali `TaskProvider.notifyListeners()` dipanggil."

---

## 6. Alur Lengkap: Login → Tampil Task List → Buka Maps

```
Login berhasil → GoRouter redirect ke /tasks
    ↓
TaskListScreen build() → Consumer<TaskProvider>
    ↓
TaskProvider.loadTasks() dipanggil (oleh initState atau listener)
    ↓
_isLoading = true → notifyListeners() → UI tampilkan CircularProgressIndicator
    ↓
GET /mobile/tasks (Dio + Bearer Token Interceptor)
    ↓
Response: { activeTasks: [...], queueTasks: [...], summary: {...} }
    ↓
MobileTaskBoardResponse.fromJson() → parsing JSON ke model Dart
    ↓
_board = response → _isLoading = false → notifyListeners()
    ↓
UI rebuild → ListView.builder() render TaskCard untuk setiap task
    ↓
User tap ikon Maps di TaskCard
    ↓
url_launcher buka: google.com/maps/dir/?destination={lat},{lng}
    ↓
Google Maps terbuka di luar aplikasi dengan navigasi otomatis
```

---

## 7. Model Data Tas (Bag) yang Lebih Kompleks

Selain `MobileTaskItem`, ada model `CourierBagTask` di `lib/features/tasks/domain/courier_bag_models.dart` yang dipakai oleh `CourierBagApiClient`:

```dart
class CourierBagTask {
  final String id;
  final String bagCode;       // Kode identifikasi tas
  final String destinationCity;
  final String status;
  final int packageCount;     // Jumlah paket dalam tas
  final List<CourierBagPackage> packages; // Daftar paket di dalam tas
  final double? latitude;
  final double? longitude;
}

class CourierBagPackage {
  final String id;
  final String resi;           // Nomor resi paket
  final String receiverName;
  final String receiverAddress;
  final String status;
  final List<CourierTrackingEvent> timeline; // Riwayat perjalanan paket
}
```

**Poin presentasi:** "Ada dua layer data: `CourierBagTask` (satu tas bisa berisi banyak paket) dan `CourierBagPackage` (paket individual). ListView menampilkan list Tas, dan di halaman detail baru ditampilkan list Paket di dalam tas tersebut."

---

## 8. Kemungkinan Pertanyaan saat Presentasi

**Q: Kenapa menggunakan `ListView.builder` bukan `ListView` biasa?**
> A: `ListView.builder` menggunakan lazy loading — widget hanya di-render saat masuk ke viewport. Untuk list dengan ratusan tugas, ini menghemat memori dan meningkatkan performa scroll secara signifikan dibanding `ListView` yang me-render semua item sekaligus.

**Q: Bagaimana cara refresh data yang paling terbaru?**
> A: Ada tiga cara: (1) Pull-to-Refresh dengan `RefreshIndicator`, (2) Auto-polling setiap 60 detik dari `TaskProvider`, (3) Background polling via WorkManager setiap 15 menit. Ketiganya memanggil `TaskProvider.loadTasks()` yang sama.

**Q: Apa yang terjadi kalau tidak ada sinyal internet saat polling?**
> A: `Dio` throw `DioExceptionType.connectionTimeout`. `MobileCourierRepository._handle()` menangkap ini dan melempar `MobileApiException`. `TaskProvider` menyimpannya ke `_error` dan memanggil `notifyListeners()` — UI menampilkan pesan error dengan tombol "Coba Lagi".

**Q: Bagaimana menentukan apakah tugas itu "baru" atau sudah pernah dilihat?**
> A: `TaskProvider._detectNewTasks()` menyimpan set ID tugas yang sudah pernah di-fetch ke `SharedPreferences`. Setiap polling, ID baru dibandingkan dengan set ini. Jika ada ID yang belum ada di set → tugas dianggap baru → notifikasi lokal ditampilkan.
