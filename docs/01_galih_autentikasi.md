# Panduan Presentasi: Galih Trisna
## Topik: Autentikasi Lintas Platform

---

## 1. Gambaran Umum Tanggung Jawab

Kamu bertanggung jawab atas **seluruh sistem autentikasi** di sisi mobile client, mulai dari UI halaman login hingga pengelolaan token JWT secara aman dan penyisipan Bearer Token di setiap request HTTP ke backend.

**Kata kunci yang harus kamu kuasai:** Login UI, JWT, Refresh Token, Secure Storage, Bearer Authorization Header, Silent Token Refresh, Session Expiry.

---

## 2. Poin Utama yang Harus Dibicarakan saat Presentasi

### 2.1 Alur UI/UX Login
1. Aplikasi dibuka → `SplashPage` (atau redirect `GoRouter`) mendeteksi status session.
2. Jika belum login → diarahkan ke `LoginScreen` (`lib/screens/login_screen.dart`).
3. User mengisi email & password → tap tombol Login.
4. Tampilkan loading state selama proses autentikasi.
5. Jika berhasil → `AuthProvider` set `isLoggedIn = true` → `GoRouter` redirect otomatis ke `/tasks`.
6. Jika gagal → tampilkan pesan error (contoh: "Invalid credentials", "Server error").

### 2.2 Integrasi dengan Backend REST API
- Autentikasi **bukan** menggunakan Supabase Auth, melainkan **custom REST endpoint** di backend Next.js:
  - `POST /mobile/auth/login` — menerima `{email, password}`, mengembalikan `{access_token, refresh_token, expires_in}`.
  - `POST /mobile/auth/logout` — membatalkan sesi di sisi server.
  - `POST /mobile/auth/refresh` — memperbarui access token menggunakan refresh token yang tersimpan.

### 2.3 Penyimpanan Token yang Aman (Secure Storage)
- Token JWT **tidak disimpan di SharedPreferences** (tidak aman), melainkan menggunakan `flutter_secure_storage` yang mengenkripsi data di Keychain (iOS) / EncryptedSharedPreferences (Android).
- Kunci yang disimpan: `access_token`, `refresh_token`, `expires_at` (ISO 8601), `user_json`.

### 2.4 Penyisipan Bearer Token Otomatis (Interceptor)
- Setiap HTTP request ke backend otomatis memiliki header `Authorization: Bearer <token>` melalui Dio Interceptor di `ApiClient`.
- Jika token sudah kadaluarsa → sistem melakukan **silent refresh** (refresh otomatis di latar belakang) lalu mengulang request asli — user tidak perlu login ulang.

### 2.5 Penanganan Session Expired
- Jika refresh token juga gagal (misal: token dicabut server) → `onSessionExpired` callback terpicu → `AuthProvider.logout()` → user diarahkan kembali ke `LoginScreen`.
- Mekanisme ini berjalan otomatis tanpa gangguan UI.

---

## 3. Struktur Folder dan File

```
lib/
├── screens/
│   └── login_screen.dart              ← UI halaman login (Form, TextField, Button)
│
├── features/
│   └── auth/
│       └── data/
│           └── auth_service.dart      ← Inti logika autentikasi (sign-in, sign-out, refresh)
│
├── core/
│   ├── network/
│   │   └── api_client.dart            ← Dio + Interceptor (inject Bearer Token, handle 401)
│   └── storage/
│       └── secure_storage_service.dart ← Baca/tulis token ke Keychain/EncryptedSharedPrefs
│
├── models/
│   ├── auth_tokens.dart               ← Model JWT (accessToken, refreshToken, expiresAt)
│   └── user_model.dart                ← Model data user (id, name, email, role, phone)
│
├── providers/
│   └── auth_provider.dart             ← State Management auth (ChangeNotifier)
│
└── router/
    └── app_router.dart                ← GoRouter redirect berdasarkan auth state
```

---

## 4. Package Utama yang Digunakan

| Package | Versi | Fungsi |
|---|---|---|
| `dio` | `^5.9.0` | HTTP client untuk POST login/logout/refresh ke backend |
| `flutter_secure_storage` | `^9.2.4` | Enkripsi token JWT di perangkat (Keychain / EncryptedSharedPrefs) |
| `supabase_flutter` | `^2.10.1` | Hanya untuk Supabase Storage (foto POD). **Bukan** untuk autentikasi. |
| `go_router` | `^14.6.3` | Redirect otomatis berdasarkan `isLoggedIn` state |
| `provider` | `^6.1.2` | State management `AuthProvider` |

---

## 5. Penjelasan Kode Detail

### 5.1 `AuthService` — Inti Sistem Autentikasi
**File:** `lib/features/auth/data/auth_service.dart`

```dart
class AuthService {
  final SecureStorageService _secureStorage;
  AuthTokens? _tokens;       // cache token di memori
  UserModel? _currentUser;
  VoidCallback? onSessionExpired; // dipanggil jika refresh gagal total
  
  // Dipanggil saat app pertama kali dibuka
  Future<void> initialize() async {
    // 1. Baca token dari Secure Storage
    final accessToken = await _secureStorage.readAccessToken();
    if (accessToken == null) return; // Belum pernah login
    
    // 2. Cek apakah token sudah expired
    final expiresAt = await _secureStorage.readExpiresAt();
    if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
      // 3. Coba refresh otomatis (silent refresh)
      await refreshTokens();
    }
  }
  
  // Dipanggil saat user tap tombol Login
  Future<void> signInWithEmail(String email, String password) async {
    final response = await _dio.post(
      '/mobile/auth/login',
      data: {'email': email, 'password': password},
    );
    // Simpan token ke Secure Storage
    await _applyTokenResponse(response.data);
  }
  
  // Dipakai oleh ApiClient interceptor sebelum setiap request
  Future<String?> getBearerToken() async {
    if (_tokens == null || _tokens!.isExpired) {
      await refreshTokens(); // refresh jika expired
    }
    return _tokens?.accessToken;
  }
}
```

**Poin presentasi:** "Fungsi `getBearerToken()` adalah jembatan antara AuthService dan ApiClient. Setiap kali ada request HTTP, interceptor memanggil fungsi ini untuk mendapatkan token yang selalu fresh."

---

### 5.2 `SecureStorageService` — Enkripsi Token
**File:** `lib/core/storage/secure_storage_service.dart`

```dart
class SecureStorageService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _expiresAtKey = 'expires_at';
  static const _userJsonKey = 'user_json';

  Future<void> saveTokens(String accessToken, String refreshToken, 
                           DateTime? expiresAt) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    if (expiresAt != null) {
      await _storage.write(key: _expiresAtKey, 
                           value: expiresAt.toIso8601String());
    }
  }

  Future<void> clearTokens() async {
    // Dipanggil saat logout
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _expiresAtKey);
    await _storage.delete(key: _userJsonKey);
  }
}
```

**Poin presentasi:** "Di Android, `flutter_secure_storage` menggunakan `EncryptedSharedPreferences` dengan AES-256. Di iOS menggunakan Keychain. Ini jauh lebih aman dibanding `SharedPreferences` biasa yang disimpan sebagai plain text."

---

### 5.3 `ApiClient` — Interceptor Bearer Token Otomatis
**File:** `lib/core/network/api_client.dart`

```dart
// Interceptor ini berjalan SEBELUM setiap HTTP request dikirim
_dio.interceptors.add(
  InterceptorsWrapper(
    onRequest: (options, handler) async {
      // Ambil token fresh (auto-refresh jika expired)
      final token = await _authService.getBearerToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options); // lanjutkan request
    },
    onError: (error, handler) async {
      // Jika server mengembalikan 401 (token tidak valid)
      if (error.response?.statusCode == 401) {
        // Coba silent refresh SATU KALI
        try {
          await _authService.refreshTokens();
          // Ulangi request asli dengan token baru
          final retryResponse = await _dio.fetch(error.requestOptions);
          handler.resolve(retryResponse);
        } catch (_) {
          // Refresh gagal → trigger logout otomatis
          handler.next(error);
        }
      } else {
        handler.next(error);
      }
    },
  ),
);
```

**Poin presentasi:** "Dengan interceptor ini, tidak ada satu pun layar atau service yang perlu mengelola token secara manual. Cukup inject `ApiClient`, dan setiap request sudah otomatis memiliki header Authorization yang benar."

---

### 5.4 `AuthProvider` — State Management
**File:** `lib/providers/auth_provider.dart`

```dart
class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = true; // loading saat cek session awal
  String? _error;

  // Dipanggil dari app.dart saat startup
  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();
    
    await _authService.initialize();
    _isLoggedIn = _authService.hasSession;
    _isLoading = false;
    notifyListeners(); // trigger GoRouter redirect
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.signInWithEmail(email, password);
      _isLoggedIn = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

**Poin presentasi:** "Provider memanggil `notifyListeners()` setiap kali state berubah. `GoRouter` listen ke `AuthProvider.isLoggedIn` dan otomatis melakukan redirect — tidak perlu `Navigator.push()` manual."

---

### 5.5 `AuthTokens` — Model JWT
**File:** `lib/models/auth_tokens.dart`

```dart
class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;    // dalam detik (biasanya 3600 = 1 jam)
  final DateTime createdAt;

  // Buffer 60 detik untuk mencegah token expired di tengah request
  DateTime get expiresAt => 
    createdAt.add(Duration(seconds: expiresIn - 60));
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
```

**Poin presentasi:** "Ada buffer 60 detik sebelum waktu expired yang sesungguhnya. Ini memastikan token tidak kadaluarsa tepat saat request sedang dikirim (race condition)."

---

## 6. Alur Lengkap: Boot → Login → Request Terautentikasi

```
App dibuka
    ↓
AppBootstrap.initialize() → Supabase init (untuk Storage saja)
    ↓
AuthProvider.checkAuth()
    ↓
AuthService.initialize()
    ├── Baca token dari SecureStorage
    ├── Cek isExpired
    └── Jika expired → refreshTokens() [silent]
    ↓
GoRouter redirect
    ├── hasSession = true  → /tasks (TaskListScreen)
    └── hasSession = false → /login (LoginScreen)
    ↓
User tap Login → AuthService.signInWithEmail()
    ↓
POST /mobile/auth/login → Backend Next.js
    ↓
Response: {access_token, refresh_token, expires_in}
    ↓
SecureStorageService.saveTokens()
    ↓
AuthProvider._isLoggedIn = true → notifyListeners()
    ↓
GoRouter redirect → /tasks
    ↓
Setiap API request:
    └── ApiClient Interceptor → getBearerToken() → "Authorization: Bearer <jwt>"
```

---

## 7. Kemungkinan Pertanyaan saat Presentasi

**Q: Kenapa tidak pakai Supabase Auth?**
> A: Backend kami menggunakan sistem autentikasi custom di Next.js. Supabase hanya kami pakai untuk Storage (upload foto POD). Memisahkan ini memberi kami kontrol penuh atas logika autentikasi dan session management.

**Q: Apakah token aman jika HP di-root?**
> A: Di Android, `EncryptedSharedPreferences` masih menggunakan Android Keystore yang secara hardware di beberapa device bisa lebih tahan terhadap root. Namun untuk keamanan maksimal di device yang di-root, perlu tambahan deteksi root. Untuk scope proyek ini, penggunaan `flutter_secure_storage` sudah merupakan best practice standar.

**Q: Apa yang terjadi jika internet mati saat login?**
> A: `Dio` akan throw `DioExceptionType.connectionTimeout` atau `receiveTimeout`. `AuthService._extractErrorMessage()` menangkap ini dan mengembalikan pesan yang ramah pengguna ke `AuthProvider._error`, lalu ditampilkan di UI LoginScreen.

**Q: Bagaimana mencegah user yang sudah logout mengakses halaman task?**
> A: `GoRouter` di `app_router.dart` memiliki `redirect` callback yang membaca `AuthProvider.isLoggedIn`. Setiap kali navigasi terjadi, callback ini diperiksa. Jika `isLoggedIn = false`, router otomatis redirect ke `/login`.
