# NekoLogistic Courier App (Flutter)

Aplikasi mobile khusus peran kurir untuk operasional pengantaran paket NekoLogistic.

## Arsitektur

Struktur project saat ini menggunakan Clean Architecture sederhana (feature-first):

```
lib/
	app.dart
	main.dart
	bootstrap/
		app_bootstrap.dart
	core/
		config/
			app_env.dart
		network/
			api_client.dart
		storage/
			secure_storage_service.dart
	features/
		auth/
			data/
				auth_service.dart
			presentation/
				login_page.dart
		splash/
			presentation/
				splash_page.dart
		tasks/
			domain/
				courier_task.dart
			presentation/
				task_list_page.dart
```

## Dependency Utama

Sudah ditambahkan di `pubspec.yaml`:

- `supabase_flutter` (Auth + Storage)
- `flutter_secure_storage` (penyimpanan token JWT aman)
- `dio` (REST API client + Bearer interceptor)
- `geolocator` (validasi lokasi)
- `image_picker`, `camera` (foto POD)
- `flutter_image_compress` (kompres foto)
- `url_launcher` (buka Google Maps)
- `path_provider` (helper path file lokal)

## Setup Environment

Konfigurasi environment dilakukan via `--dart-define`:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `API_BASE_URL`
- `POD_BUCKET` (opsional, default: `proof-of-delivery`)

Contoh menjalankan aplikasi:

```bash
flutter run \
	--dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
	--dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY \
	--dart-define=API_BASE_URL=https://api.your-domain.com
```

## Platform Permission

Permission minimum sudah disiapkan:

- Android: Internet, Camera, Fine/Coarse Location, serta query intent untuk Maps.
- iOS: Camera usage, Location when in use, dan Photo Library Add usage.

## Status Implementasi Saat Ini

- Bootstrap aplikasi + inisialisasi Supabase.
- Login email/password Supabase Auth.
- Penyimpanan JWT ke secure storage.
- API client Dio dengan auto attach header `Authorization: Bearer <token>`.
- Task list page dengan loading, error, empty state, pull-to-refresh.
- Tombol `Arahkan` untuk membuka Google Maps eksternal.

## Tahap Berikutnya

- Integrasi endpoint backend nyata untuk daftar tugas kurir.
- Halaman detail task + alur POD (kamera -> kompres -> upload Supabase Storage -> update status `DELIVERED`).
- Validasi geolocation real-time sebelum submit POD.
