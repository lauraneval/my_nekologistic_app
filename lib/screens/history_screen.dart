import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../features/mobile/domain/mobile_models.dart';
import '../providers/history_provider.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/neko_app_bar.dart';
import '../widgets/status_badge.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HistoryProvider>();

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primaryBlue,
        onRefresh: () => context.read<HistoryProvider>().loadHistory(),
        child: LoadingOverlay(
          isLoading: provider.isLoading && provider.history == null,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NekoAppBar(),
                      const SizedBox(height: 8),
                      Text(
                        'Delivery History',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: context.nekoTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tracking your completed logistical movements.',
                        style: GoogleFonts.inter(
                            fontSize: 14, color: context.nekoTextSecondary),
                      ),
                      const SizedBox(height: 20),
                      _buildTabRow(provider),
                      const SizedBox(height: 20),
                      _buildMonthlyCard(provider),
                      const SizedBox(height: 12),
                      _buildEfficiencyCard(provider),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              if (provider.error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(provider.error!,
                        style: GoogleFonts.inter(
                            color: AppColors.errorRed, fontSize: 14),
                        textAlign: TextAlign.center),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _buildHistoryItem(provider.currentItems[i]),
                      childCount: provider.currentItems.length,
                    ),
                  ),
                ),
              if (provider.currentItems.isEmpty && !provider.isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No delivery history yet',
                        style: GoogleFonts.inter(
                            fontSize: 14, color: context.nekoTextSecondary),
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  child: _buildLoadMoreButton(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabRow(HistoryProvider provider) {
    final tabs = [
      (HistoryTab.today, 'Today'),
      (HistoryTab.yesterday, 'Yesterday'),
      (HistoryTab.last7Days, 'Last 7 Days'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((t) {
          final isActive = provider.activeTab == t.$1;
          return GestureDetector(
            onTap: () => context.read<HistoryProvider>().setTab(t.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? AppColors.primaryBlue : context.nekoDivider,
                ),
              ),
              child: Text(
                t.$2,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? Colors.white : context.nekoTextSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthlyCard(HistoryProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: context.nekoCardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MONTHLY TOTAL',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: context.nekoTextSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${provider.history?.last7Days.length ?? 0}',
                style: GoogleFonts.inter(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: context.nekoTextPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.deliveredBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '+0%',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deliveredText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyCard(HistoryProvider provider) {
    final score = provider.profile?.efficiencyScore ?? 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EFFICIENCY SCORE',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${score.toStringAsFixed(1)}%',
            style: GoogleFonts.inter(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(MobileTaskItem item) {
    final delivered = item.deliveredAt;
    final dateStr = delivered != null ? _formatDateTime(delivered) : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: context.nekoCardDecor(),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.nekoInputFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.inventory_2_outlined,
                color: context.nekoTextSecondary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.recipientName ?? item.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.nekoTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: context.nekoTextSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(status: item.status),
              const SizedBox(height: 4),
              Text(
                'ID: ${(item.bagCode ?? item.title).length > 10 ? (item.bagCode ?? item.title).substring(0, 10) : (item.bagCode ?? item.title)}',
                style: GoogleFonts.inter(
                    fontSize: 11, color: context.nekoTextSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: context.nekoDivider, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Center(
        child: Text(
          'Load More History',
          style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.nekoTextSecondary),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • $h:$m';
  }
}
