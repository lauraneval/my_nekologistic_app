import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/neko_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfile();
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to log out of this device?',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) context.go('/login');
    }
  }

  void _showEditBottomSheet() {
    final provider = context.read<ProfileProvider>();
    final profile = provider.profile;
    final nameCtrl = TextEditingController(text: profile?.name == '-' ? '' : profile?.name);
    final phoneCtrl = TextEditingController(text: profile?.phone == '-' ? '' : profile?.phone);
    final emailCtrl = TextEditingController(text: profile?.email == '-' ? '' : profile?.email);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: ctx.nekoCardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Edit Profile',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700,
                          color: ctx.nekoTextPrimary)),
                  const SizedBox(height: 20),
                  _editField(ctx, 'Name', nameCtrl, Icons.person_outline),
                  const SizedBox(height: 12),
                  _editField(ctx, 'Phone Number', phoneCtrl, Icons.phone_outlined,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _editField(ctx, 'Email', emailCtrl, Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.button)),
                      ),
                      onPressed: provider.isSaving
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              final ok = await provider.updateProfile(
                                name: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
                                phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                                email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(ok ? 'Profile updated successfully' : 'Failed to save profile'),
                                  backgroundColor: ok ? AppColors.successGreen : AppColors.errorRed,
                                ));
                              }
                            },
                      child: provider.isSaving
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Save', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _editField(BuildContext ctx, String label, TextEditingController ctrl, IconData icon,
      {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                color: ctx.nekoTextSecondary, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 14, color: ctx.nekoTextPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: ctx.nekoTextSecondary),
            fillColor: ctx.nekoInputFill,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final profile = provider.profile;

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primaryBlue,
        onRefresh: () => context.read<ProfileProvider>().loadProfile(),
        child: LoadingOverlay(
          isLoading: provider.isLoading && profile == null,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: NekoAppBar(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    children: [
                      _buildAvatar(),
                      const SizedBox(height: 16),
                      Text(
                        profile?.name ?? '-',
                        style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700,
                            color: context.nekoTextPrimary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _badgeChip('COURIER'),
                          const SizedBox(width: 8),
                          _badgeChip('ID: NK-${_shortId(profile?.raw['id']?.toString())}'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildContactCard(profile),
                      const SizedBox(height: 12),
                      _buildMetricCard(profile),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('App Preferences',
                            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700,
                                color: context.nekoTextPrimary)),
                      ),
                      const SizedBox(height: 12),
                      _buildPreferencesCard(provider),
                      const SizedBox(height: 24),
                      _buildLogoutButton(),
                      const SizedBox(height: 12),
                      Text(
                        'version ${provider.appVersion} (Build ${provider.buildNumber})',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: _showEditBottomSheet,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: context.nekoInputFill,
            child: Icon(Icons.person, size: 52, color: context.nekoTextSecondary),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppColors.activeOrange,
                shape: BoxShape.circle,
                border: Border.all(color: context.nekoCardBg, width: 2),
              ),
              child: const Icon(Icons.edit, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.nekoInputFill,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
              color: context.nekoTextSecondary, letterSpacing: 0.5)),
    );
  }

  Widget _buildContactCard(dynamic profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: context.nekoCardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contacts_outlined, size: 14, color: context.nekoTextSecondary),
              const SizedBox(width: 6),
              Text('CONTACT INFO',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600,
                      color: context.nekoTextSecondary, letterSpacing: 1.2)),
              const Spacer(),
              GestureDetector(
                onTap: _showEditBottomSheet,
                child: Text('Edit',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _contactRow(Icons.email_outlined, profile?.email ?? '-'),
          const SizedBox(height: 8),
          _contactRow(Icons.phone_outlined, profile?.phone ?? '-'),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.nekoTextSecondary),
        const SizedBox(width: 10),
        Text(value, style: GoogleFonts.inter(fontSize: 14, color: context.nekoTextPrimary)),
      ],
    );
  }

  Widget _buildMetricCard(dynamic profile) {
    final score = profile?.efficiencyScore ?? 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: context.nekoCardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up_outlined, size: 14, color: context.nekoTextSecondary),
              const SizedBox(width: 6),
              Text('METRIC SUMMARY',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600,
                      color: context.nekoTextSecondary, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${score.toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800,
                          color: AppColors.primaryBlue)),
                  Text('Delivery Accuracy',
                      style: GoogleFonts.inter(fontSize: 13, color: context.nekoTextSecondary)),
                ],
              ),
              const Icon(Icons.trending_up, color: AppColors.successGreen, size: 28),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(ProfileProvider provider) {
    return Container(
      decoration: context.nekoCardDecor(),
      child: Column(
        children: [
          _prefRow(
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            subtitle: 'Real-time route updates',
            trailing: Switch(
              value: provider.pushNotif,
              activeTrackColor: AppColors.primaryBlue,
              onChanged: (v) => context.read<ProfileProvider>().setPushNotif(v),
            ),
          ),
          Divider(height: 1, color: context.nekoDivider),
          _prefRow(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Interface',
            subtitle: 'Optimized for night routes',
            trailing: Switch(
              value: provider.darkMode,
              activeTrackColor: AppColors.primaryBlue,
              onChanged: (v) => context.read<ProfileProvider>().setDarkMode(v),
            ),
          ),
          Divider(height: 1, color: context.nekoDivider),
          _prefRow(
            icon: Icons.security_outlined,
            title: 'Privacy & Security',
            subtitle: 'Manage app permissions',
            trailing: GestureDetector(
              onTap: () => context.push('/profile/privacy'),
              child: Icon(Icons.chevron_right, color: context.nekoTextSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _prefRow({required IconData icon, required String title,
      required String subtitle, required Widget trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: context.nekoBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: context.nekoTextSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600,
                        color: context.nekoTextPrimary)),
                Text(subtitle,
                    style: GoogleFonts.inter(fontSize: 12, color: context.nekoTextSecondary)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _logout,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, size: 18),
            const SizedBox(width: 8),
            Text('Logout from Device',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  String _shortId(String? id) {
    if (id == null || id.length < 5) return id ?? '00000';
    return id.substring(0, 5).toUpperCase();
  }
}
