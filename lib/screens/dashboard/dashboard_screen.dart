import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_card.dart';
import '../../models/stock_transaction.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _ringController;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _ringAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOutCubic),
    );

    _ringController.forward();
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(dashboardStatsProvider);
    final transactions = ref.watch(transactionProvider);
    final recentActivity = transactions.take(5).toList();
    final aiSuggestion = AppConstants.aiRecommendations[0];
    final health = stats['inventoryHealth'] as int;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.read(productProvider.notifier).refresh();
          ref.read(transactionProvider.notifier).refresh();
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),
                  // ── Health Ring ──────────────────────────────────
                  _buildHealthRing(health),
                  const SizedBox(height: 24),
                  // ── Stats Grid ───────────────────────────────────
                  _buildStatsGrid(stats),
                  const SizedBox(height: 20),
                  // ── AI Card ──────────────────────────────────────
                  _buildAICard(aiSuggestion),
                  const SizedBox(height: 24),
                  // ── Chart ────────────────────────────────────────
                  _buildChartSection(),
                  const SizedBox(height: 24),
                  // ── Recent Activity ───────────────────────────────
                  _buildRecentActivity(recentActivity),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader() {
    final auth = ref.read(authProvider.notifier);
    final authState = ref.watch(authProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GOOD MORNING,',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Inventory Mgr',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Logout icon button
          GestureDetector(
            onTap: () async {
              await auth.logout();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.critical.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: AppColors.critical.withValues(alpha: 0.2)),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.critical,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthRing(int health) {
    return Center(
      child: AnimatedBuilder(
        animation: _ringAnimation,
        builder: (context, child) {
          return SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: _HealthRingPainter(
                progress: _ringAnimation.value * (health / 100),
                health: health,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$health%',
                      style: GoogleFonts.outfit(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Inventory Health',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    return Column(
      children: [
        _buildStatCard(
          label: 'Total Products',
          value: '${stats['totalProducts']}',
          valueFormatted: _formatNumber(stats['totalProducts']),
          change: '+4% vs last month',
          changeColor: AppColors.emerald,
          icon: Icons.inventory_2_outlined,
          iconColor: AppColors.primary.withOpacity(0.15),
          iconFgColor: AppColors.primary,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          label: 'Low Stock Items',
          value: '${stats['lowStockItems']}',
          valueFormatted: '${stats['lowStockItems']}',
          change: 'Requires attention',
          changeColor: AppColors.warning,
          icon: Icons.warning_amber_rounded,
          iconColor: AppColors.warning.withOpacity(0.12),
          iconFgColor: AppColors.warning,
          valueColor: stats['lowStockItems'] > 0
              ? AppColors.critical
              : AppColors.textPrimary,
          dotColor: AppColors.critical,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String valueFormatted,
    required String change,
    required Color changeColor,
    required IconData icon,
    required Color iconColor,
    required Color iconFgColor,
    Color? valueColor,
    Color? dotColor,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  valueFormatted,
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: valueColor ?? AppColors.textPrimary,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconFgColor, size: 22),
              ),
              const SizedBox(height: 8),
              dotColor != null
                  ? Row(
                      children: [
                        Text(
                          change,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: changeColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: changeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        change,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: changeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAICard(Map<String, String> suggestion) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.cardWhite,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI RECOMMENDATION',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Restock: ${suggestion['title']!.replaceFirst('Restock ', '')}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  suggestion['detail']!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  child: Row(
                    children: [
                      Text(
                        '${suggestion['action']} →',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Monthly Stock Usage',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceGray,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Usage',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
          child: SizedBox(
            height: 160,
            child: LineChart(
              _buildLineChartData(),
            ),
          ),
        ),
      ],
    );
  }

  LineChartData _buildLineChartData() {
    final data = AppConstants.monthlyUsageData;
    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 200,
        getDrawingHorizontalLine: (value) => FlLine(
          color: AppColors.borderLight,
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= AppConstants.monthLabels.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  AppConstants.monthLabels[idx],
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
            reservedSize: 28,
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.4,
          gradient: AppColors.primaryGradient,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: index == spots.length - 1 ? 5 : 0,
                color: AppColors.cyan,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.15),
                AppColors.cyan.withOpacity(0.02),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(List<StockTransaction> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...transactions.map((tx) => _buildActivityItem(tx)),
      ],
    );
  }

  Widget _buildActivityItem(StockTransaction tx) {
    final isIn = tx.isStockIn;
    final color = isIn ? AppColors.primary : AppColors.critical;
    final bg = isIn
        ? AppColors.primary.withOpacity(0.08)
        : AppColors.critical.withOpacity(0.08);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isIn ? Icons.add_rounded : Icons.remove_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${isIn ? 'Stock In' : 'Stock Out'}: ${tx.productName}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_timeAgo(tx.timestamp)} • ${tx.warehouse}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            tx.quantityDisplay,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.45),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  String _formatNumber(int n) {
    return NumberFormat('#,##0').format(n);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    return '${diff.inDays} days ago';
  }
}

// ── Custom Painter for Circular Health Ring ──────────────────────────────────

class _HealthRingPainter extends CustomPainter {
  final double progress;
  final int health;

  _HealthRingPainter({required this.progress, required this.health});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 20) / 2;
    const strokeWidth = 14.0;
    const startAngle = -math.pi / 2;

    // Background track
    final trackPaint = Paint()
      ..color = AppColors.surfaceGray
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Gradient arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepAngle = 2 * math.pi * progress;

    final shader = const LinearGradient(
      colors: [Color(0xFF3B36F5), Color(0xFF4CC9F0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(rect);

    final arcPaint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);

    // Glow effect
    final glowPaint = Paint()
      ..color = AppColors.cyan.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);
  }

  @override
  bool shouldRepaint(_HealthRingPainter old) =>
      old.progress != progress || old.health != health;
}
