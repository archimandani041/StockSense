import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../models/product.dart';
import '../../widgets/stock_progress_bar.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/gradient_button.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddProductSheet({Product? editProduct}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddProductSheet(editProduct: editProduct),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(filteredProductsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildHeader()),

          // ── Search ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: _buildSearchBar(),
            ),
          ),

          // ── Category Chips ────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildCategoryChips(selectedCategory),
          ),

          // ── Product List ──────────────────────────────────────────
          products.isEmpty
              ? const SliverFillRemaining(child: _EmptyProductsState())
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _buildProductCard(products[i]),
                      childCount: products.length,
                    ),
                  ),
                ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MANAGEMENT',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Product Catalog',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.filter_list_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) =>
            ref.read(searchQueryProvider.notifier).state = v,
        decoration: InputDecoration(
          hintText: 'Search inventory items...',
          hintStyle: GoogleFonts.inter(
            color: AppColors.textTertiary,
            fontSize: 14,
          ),
          prefixIcon:
              const Icon(Icons.search_rounded, color: AppColors.textTertiary),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(String selected) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: AppConstants.categories.map((cat) {
          final isActive = cat == selected;
          return GestureDetector(
            onTap: () =>
                ref.read(selectedCategoryProvider.notifier).state = cat,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                gradient: isActive ? AppColors.primaryGradient : null,
                color: isActive ? null : AppColors.cardWhite,
                borderRadius: BorderRadius.circular(30),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Text(
                cat,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final statusColor = AppColors.statusColor(product.status);
    final borderColor = product.status == 'NORMAL'
        ? AppColors.borderLight
        : product.status == 'LOW'
            ? AppColors.warning.withOpacity(0.3)
            : AppColors.critical.withOpacity(0.4);

    return Dismissible(
      key: Key(product.id),
      background: _dismissBackground(true),
      secondaryBackground: _dismissBackground(false),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await _confirmDelete(product);
        } else {
          _showAddProductSheet(editProduct: product);
          return false;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          ref.read(productProvider.notifier).deleteProduct(product.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.productName} deleted'),
              backgroundColor: AppColors.critical,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _categoryIcon(product.category),
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.productName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          product.category.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textTertiary,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: product.status),
                ],
              ),
              const SizedBox(height: 14),

              // ── quantityAvailable row
              Row(
                children: [
                  Text(
                    '${product.quantityAvailable} Units',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: product.status == 'CRITICAL'
                          ? AppColors.critical
                          : AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    product.status == 'NORMAL'
                        ? '${(product.stockPercentage * 100).round()}% In Stock'
                        : product.statusLabel,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              GradientProgressBar(
                value: product.stockPercentage,
                status: product.status,
              ),

              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.swipe_rounded,
                    size: 12,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Swipe to edit or delete',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dismissBackground(bool isEdit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isEdit ? AppColors.primary : AppColors.critical,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: isEdit ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEdit ? Icons.edit_rounded : Icons.delete_rounded,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            isEdit ? 'Edit' : 'Delete',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(Product product) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Delete Product?'),
            content: Text('Remove "${product.productName}" from inventory?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete',
                      style: TextStyle(color: AppColors.critical))),
            ],
          ),
        ) ??
        false;
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
        onPressed: () => _showAddProductSheet(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Electronics':
        return Icons.computer_rounded;
      case 'Hardware':
        return Icons.hardware_rounded;
      case 'Safety':
        return Icons.health_and_safety_rounded;
      case 'Tools':
        return Icons.build_rounded;
      case 'Medical':
        return Icons.medical_services_rounded;
      case 'Chemicals':
        return Icons.science_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }
}

// ── Add/Edit Product Bottom Sheet ────────────────────────────────────────────

class _AddProductSheet extends ConsumerStatefulWidget {
  final Product? editProduct;
  const _AddProductSheet({this.editProduct});

  @override
  ConsumerState<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<_AddProductSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _skuCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _maxCtrl;
  late final TextEditingController _minCtrl;
  String _selectedCategory = 'Electronics';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.editProduct;
    _nameCtrl = TextEditingController(text: p?.productName ?? '');
    _skuCtrl = TextEditingController(text: p?.sku ?? '');
    _qtyCtrl = TextEditingController(text: p?.quantityAvailable.toString() ?? '');
    _maxCtrl = TextEditingController(text: ''); // Removed maxQuantity, keeping controller to not break layout
    _minCtrl = TextEditingController(text: p?.minimumThreshold.toString() ?? '');
    _selectedCategory = p?.category ?? 'Electronics';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _qtyCtrl.dispose();
    _maxCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.editProduct == null ? 'Add Product' : 'Edit Product',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              _field(_nameCtrl, 'Product productName', Icons.inventory_2_outlined,
                  required: true),
              const SizedBox(height: 12),
              _field(_skuCtrl, 'SKU Code', Icons.qr_code_rounded,
                  required: true),
              const SizedBox(height: 12),
              _categoryDropdown(),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _field(_qtyCtrl, 'Current Qty',
                        Icons.numbers_rounded,
                        isNumber: true)),
                const SizedBox(width: 10),
                Expanded(
                    child: _field(
                        _maxCtrl, 'Max Qty', Icons.arrow_upward_rounded,
                        isNumber: true)),
              ]),
              const SizedBox(height: 12),
              _field(_minCtrl, 'Min Threshold', Icons.warning_amber_rounded,
                  isNumber: true),
              const SizedBox(height: 24),
              GradientButton(
                label:
                    widget.editProduct == null ? 'Add Product' : 'Save Changes',
                icon: Icons.check_rounded,
                isLoading: _isLoading,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool required = false,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: required
          ? (v) => v == null || v.isEmpty ? 'Required' : null
          : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
            color: AppColors.textTertiary, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
        filled: true,
        fillColor: AppColors.surfaceGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _categoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      onChanged: (v) => setState(() => _selectedCategory = v!),
      decoration: InputDecoration(
        hintText: 'Category',
        prefixIcon: const Icon(Icons.category_rounded,
            color: AppColors.primary, size: 18),
        filled: true,
        fillColor: AppColors.surfaceGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: AppConstants.categories
          .where((c) => c != 'All')
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));

    final qty = int.tryParse(_qtyCtrl.text) ?? 0;
    final min = int.tryParse(_minCtrl.text) ?? 10;

    if (widget.editProduct == null) {
      final product = Product(
        id: const Uuid().v4(),
        productName: _nameCtrl.text.trim(),
        sku: _skuCtrl.text.trim(),
        category: _selectedCategory,
        quantityAvailable: qty,
        minimumThreshold: min,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await ref.read(productProvider.notifier).addProduct(product);
    } else {
      final updated = widget.editProduct!.copyWith(
        productName: _nameCtrl.text.trim(),
        sku: _skuCtrl.text.trim(),
        category: _selectedCategory,
        quantityAvailable: qty,
        minimumThreshold: min,
        updatedAt: DateTime.now(),
      );
      await ref.read(productProvider.notifier).updateProduct(updated);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
    }
  }
}

class _EmptyProductsState extends StatelessWidget {
  const _EmptyProductsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.primary,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search or category',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
