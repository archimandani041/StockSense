import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/stock_progress_bar.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchCtrl = TextEditingController();
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final sortedProducts = ref.watch(sortedFilteredProductsProvider);
    final selectedStatus = ref.watch(selectedStatusFilterProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final sortOption = ref.watch(sortOptionProvider);

    final showResults = _hasSearched || query.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildHeader()),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Search Bar ────────────────────────────────────
                _buildSearchBar(query),
                const SizedBox(height: 16),

                // ── Smart Suggestions ─────────────────────────────
                _buildSmartSuggestions(),
                const SizedBox(height: 20),

                if (showResults) ...[
                  // ── Filters ──────────────────────────────────────
                  _buildCategoryFilter(selectedCategory),
                  const SizedBox(height: 16),
                  _buildStatusFilter(selectedStatus),
                  const SizedBox(height: 16),
                  _buildSortOptions(sortOption),
                  const SizedBox(height: 20),

                  // ── Results ───────────────────────────────────────
                  _buildResultsHeader(sortedProducts.length),
                  const SizedBox(height: 12),
                  ...sortedProducts.map(_buildResultCard),
                ] else ...[
                  // ── Empty / Hero State ────────────────────────────
                  _buildEmptyState(),
                ],

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
      child: Column(
        children: [
          Text(
            'Find Products',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Manage your inventory with intelligent precision',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(String currentQuery) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) {
          ref.read(searchQueryProvider.notifier).state = v;
          setState(() => _hasSearched = v.isNotEmpty);
        },
        decoration: InputDecoration(
          hintText: 'Search by productName, SKU, category...',
          hintStyle: GoogleFonts.inter(
            color: AppColors.textTertiary,
            fontSize: 14,
          ),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.textTertiary, size: 22),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.mic_none_rounded,
                    color: AppColors.primary, size: 22),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded,
                    color: AppColors.primary, size: 22),
                onPressed: () {},
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSmartSuggestions() {
    final chips = [
      'Top requested',
      'Out of stock',
      'Recently updated',
      'Trending items',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SMART SUGGESTIONS:',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textTertiary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: chips.map((chip) {
              return GestureDetector(
                onTap: () {
                  if (chip == 'Out of stock') {
                    ref
                        .read(selectedStatusFilterProvider.notifier)
                        .state = 'CRITICAL';
                  } else if (chip == 'Recently updated') {
                    ref.read(sortOptionProvider.notifier).state =
                        'Last Updated';
                  }
                  setState(() => _hasSearched = true);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.borderLight, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    chip,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(String selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CATEGORY',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
              letterSpacing: 1.2,
            )),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: AppColors.borderLight, width: 1.2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selected,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              items: AppConstants.categories
                  .map((c) =>
                      DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  ref
                      .read(selectedCategoryProvider.notifier)
                      .state = v;
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilter(String? selected) {
    final statuses = ['NORMAL', 'LOW', 'CRITICAL'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STOCK STATUS',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
              letterSpacing: 1.2,
            )),
        const SizedBox(height: 8),
        Row(
          children: statuses.map((s) {
            final isActive = selected == s;
            Color color = AppColors.statusColor(s);

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  ref.read(selectedStatusFilterProvider.notifier).state =
                      isActive ? null : s;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? color.withOpacity(0.1)
                        : AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive
                          ? color.withOpacity(0.5)
                          : AppColors.borderLight,
                      width: isActive ? 1.5 : 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color:
                              isActive ? color : AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSortOptions(String selected) {
    final options = ['Alphabetical', 'quantityAvailable', 'Last Updated'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SORT BY',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
              letterSpacing: 1.2,
            )),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isActive = selected == opt;
            return GestureDetector(
              onTap: () =>
                  ref.read(sortOptionProvider.notifier).state = opt,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  gradient:
                      isActive ? AppColors.primaryGradient : null,
                  color: isActive ? null : AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                  border: isActive
                      ? null
                      : Border.all(
                          color: AppColors.borderLight, width: 1.2),
                ),
                child: Text(
                  opt,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResultsHeader(int count) {
    return Row(
      children: [
        Text(
          '$count results',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        if (_searchCtrl.text.isNotEmpty)
          GestureDetector(
            onTap: () {
              _searchCtrl.clear();
              ref.read(searchQueryProvider.notifier).state = '';
              ref.read(selectedStatusFilterProvider.notifier).state = null;
              ref.read(selectedCategoryProvider.notifier).state = 'All';
              ref.read(sortOptionProvider.notifier).state = 'Alphabetical';
              setState(() => _hasSearched = false);
            },
            child: Text(
              'Clear filters',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResultCard(product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2_outlined,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
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
                  '${product.category} • SKU: ${product.sku}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 6),
                GradientProgressBar(
                  value: product.stockPercentage,
                  status: product.status,
                  height: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(status: product.status),
              const SizedBox(height: 4),
              Text(
                '${product.quantityAvailable}',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // Warehouse illustration (programmatic)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [Color(0xFF0F1741), Color(0xFF1A237E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Shelf rows
                ...List.generate(4, (i) {
                  return Positioned(
                    left: 24.0,
                    right: 24.0,
                    top: 30.0 + i * 40,
                    child: Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05 + i * 0.01),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  );
                }),
                // Search icon glow
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const Icon(
                  Icons.manage_search_rounded,
                  color: Colors.white,
                  size: 52,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Ready to sync?',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a product productName or scan a barcode\nto begin tracking your assets.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
