# Panduan Presentasi Mobile Client — NekoLogistic App

Folder ini berisi naskah teknis presentasi untuk setiap PIC di sisi **Mobile Client** aplikasi NekoLogistic.

## Daftar Panduan

| File | PIC | Tanggung Jawab |
|---|---|---|
| [01_galih_autentikasi.md](01_galih_autentikasi.md) | Galih Trisna | Autentikasi lintas platform (Login UI, JWT, Secure Storage, Bearer Header) |
| [02_naufal_task_management.md](02_naufal_task_management.md) | Naufal Thoriq Muzhaffar | Manajemen Tugas & Rute Kurir (Task List, API integration, ListView, Loading/Empty State) |
| [03_rusdiyanto_pod.md](03_rusdiyanto_pod.md) | Muhammad Rusdiyanto | Proof of Delivery Berbasis Kamera (Camera, Supabase Storage, status update API) |
| [04_tsaqif_geolocation_qa.md](04_tsaqif_geolocation_qa.md) | Tsaqif Kanz Ahmad | Validasi Geolocation & QA (GPS, distance validation, test scenarios) |

## Tech Stack Ringkas

- **Framework:** Flutter (Dart)
- **State Management:** Provider (`ChangeNotifier`)
- **HTTP Client:** Dio dengan interceptor Bearer Token otomatis
- **Auth:** Custom REST API (`/mobile/auth/*`) + `flutter_secure_storage`
- **Cloud Storage:** Supabase Storage (khusus upload foto POD)
- **GPS:** `geolocator ^14.0.2`
- **Camera:** `image_picker ^1.2.0` + `flutter_image_compress ^2.4.0`
- **Routing:** `go_router ^14.6.3`
- **Background Tasks:** `workmanager ^0.9.0`
- **Backend:** Next.js REST API di `https://nekologistic.lauraneval.dev`
