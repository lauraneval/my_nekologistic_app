import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/theme/app_theme.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  Map<Permission, PermissionStatus> _statuses = {};
  bool _loading = true;

  final _permissions = [
    _PermissionInfo(
      permission: Permission.camera,
      icon: Icons.camera_alt_outlined,
      title: 'Kamera',
      subtitle: 'Digunakan untuk foto bukti pengiriman (POD)',
      color: AppColors.activeOrange,
    ),
    _PermissionInfo(
      permission: Permission.locationWhenInUse,
      icon: Icons.location_on_outlined,
      title: 'Lokasi (GPS)',
      subtitle: 'Digunakan untuk validasi jarak pengiriman',
      color: AppColors.primaryBlue,
    ),
    _PermissionInfo(
      permission: Permission.phone,
      icon: Icons.phone_outlined,
      title: 'Telepon',
      subtitle: 'Digunakan untuk menghubungi penerima',
      color: AppColors.successGreen,
    ),
    _PermissionInfo(
      permission: Permission.storage,
      icon: Icons.folder_outlined,
      title: 'Penyimpanan',
      subtitle: 'Digunakan untuk menyimpan foto pengiriman',
      color: const Color(0xFF8B5CF6),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _loading = true);
    final statuses = await [
      Permission.camera,
      Permission.locationWhenInUse,
      Permission.phone,
      Permission.storage,
    ].request();
    if (mounted) setState(() { _statuses = statuses; _loading = false; });
  }

  Future<void> _requestPermission(_PermissionInfo info) async {
    final status = await info.permission.request();
    if (mounted) setState(() => _statuses[info.permission] = status);
    if (status.isPermanentlyDenied && mounted) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Izin Diblokir', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: Text(
            'Izin "${info.title}" diblokir. Buka pengaturan aplikasi untuk mengaktifkannya.',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: GoogleFonts.inter(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () { Navigator.pop(context); openAppSettings(); },
              child: Text('Buka Pengaturan', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.nekoCardBg,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
            ),
            child: Icon(Icons.arrow_back, size: 20, color: context.nekoTextPrimary),
          ),
        ),
        title: Text('Privacy & Security',
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700,
                color: context.nekoTextPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Kelola izin yang dibutuhkan aplikasi NekoLogistic untuk berjalan dengan baik.',
                  style: GoogleFonts.inter(fontSize: 13, color: context.nekoTextSecondary),
                ),
                const SizedBox(height: 20),
                ..._permissions.map((info) => _buildPermissionCard(info)),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _checkPermissions,
                  icon: const Icon(Icons.refresh_outlined),
                  label: Text('Cek Ulang Semua Izin',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPermissionCard(_PermissionInfo info) {
    final status = _statuses[info.permission];
    final isGranted = status?.isGranted ?? false;
    final isDenied = status?.isDenied ?? false;
    final isPermanent = status?.isPermanentlyDenied ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: context.nekoCardDecor(),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: info.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(info.icon, color: info.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.title,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600,
                        color: context.nekoTextPrimary)),
                const SizedBox(height: 2),
                Text(info.subtitle,
                    style: GoogleFonts.inter(fontSize: 12, color: context.nekoTextSecondary)),
                const SizedBox(height: 6),
                _StatusChip(isGranted: isGranted, isPermanent: isPermanent, isDenied: isDenied),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!isGranted)
            TextButton(
              onPressed: () => _requestPermission(info),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.08),
              ),
              child: Text(isPermanent ? 'Pengaturan' : 'Izinkan',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isGranted, required this.isPermanent, required this.isDenied});

  final bool isGranted;
  final bool isPermanent;
  final bool isDenied;

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = isGranted
        ? ('Diizinkan', AppColors.deliveredText, AppColors.deliveredBg)
        : isPermanent
            ? ('Diblokir', AppColors.errorRed, const Color(0xFFFEE2E2))
            : ('Belum Diizinkan', AppColors.inTransitText, AppColors.inTransitBg);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _PermissionInfo {
  const _PermissionInfo({
    required this.permission,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final Permission permission;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}
