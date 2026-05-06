import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../data/models/product.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../shared/widgets/stock_progress_bar.dart';

class UpdatesScreen extends ConsumerStatefulWidget {
  const UpdatesScreen({super.key});

  @override
  ConsumerState<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends ConsumerState<UpdatesScreen>
    with TickerProviderStateMixin {
  Product? _selectedProduct;
  String _transactionType = 'STOCK IN';
  int _quantity = 1;
  bool _isLoading = false;
  bool _showSuccess = false;
  String _selectedWarehouse = AppConstants.warehouses[0];
  String _selectedUser = AppConstants.users[0];

  late AnimationController _successController;
  late Animation<double> _successScale;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _successScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }

  int get _newStockLevel {
    if (_selectedProduct == null) return 0;
    if (_transactionType == 'STOCK IN') {
      return _selectedProduct!.quantity + _quantity;
    } else {
      return (_selectedProduct!.quantity - _quantity)
          .clamp(0, _selectedProduct!.maxQuantity);
    }
  }

  double get _newStockPercent {
    if (_selectedProduct == null) return 0;
    return _newStockLevel / _selectedProduct!.maxQuantity;
  }

  Future<void> _confirmTransaction() async {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a product'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_transactionType == 'STOCK OUT' &&
        _quantity > _selectedProduct!.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Cannot remove $_quantity units. Only ${_selectedProduct!.quantity} available.'),
          backgroundColor: AppColors.critical,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final prev = _selectedProduct!.quantity;
    final next = _newStockLevel;

    await ref.read(productProvider.notifier).updateStock(
          _selectedProduct!.id,
          next,
        );

    await ref.read(transactionProvider.notifier).addTransaction(
          productId: _selectedProduct!.id,
          productName: _selectedProduct!.name,
          type: _transactionType,
          quantity: _quantity,
          user: _selectedUser,
          warehouse: _selectedWarehouse,
          previousQuantity: prev,
          newQuantity: next,
        );

    setState(() {
      _isLoading = false;
      _showSuccess = true;
    });
    _successController.forward();

    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
      setState(() {
        _showSuccess = false;
        _quantity = 1;
        _selectedProduct = null;
      });
      _successController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────
            _buildHeader(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ── Product Selector ─────────────────────────
                  _sectionLabel('Select Product'),
                  const SizedBox(height: 8),
                  _buildProductSelector(products),
                  const SizedBox(height: 20),

                  // ── Transaction Type ─────────────────────────
                  _sectionLabel('Transaction Type'),
                  const SizedBox(height: 8),
                  _buildTypeToggle(),
                  const SizedBox(height: 20),

                  // ── Quantity Stepper ─────────────────────────
                  _buildQuantityStepper(),
                  const SizedBox(height: 20),

                  // ── Live Preview ──────────────────────────────
                  if (_selectedProduct != null) ...[
                    _buildLivePreview(),
                    const SizedBox(height: 20),
                  ],

                  // ── Warehouse / User ─────────────────────────
                  _buildWarehouseAndUser(),
                  const SizedBox(height: 28),

                  // ── Confirm Button ───────────────────────────
                  _showSuccess
                      ? _buildSuccessState()
                      : GradientButton(
                          label: 'Confirm Transaction',
                          icon: Icons.check_circle_outline_rounded,
                          height: 58,
                          isLoading: _isLoading,
                          onPressed: _confirmTransaction,
                        ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Stock\nTransaction',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  height: 1.2,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.emerald.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.emerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Last synced: Just now',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.emerald,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ── Warehouse Hero ───────────────────────────────────
          Stack(
            children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0F1741),
                      Color(0xFF1A237E),
                      Color(0xFF0D47A1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative elements simulating warehouse
                    ...List.generate(6, (i) {
                      return Positioned(
                        left: 20.0 + i * 45,
                        top: 30,
                        bottom: 0,
                        child: Container(
                          width: 35,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04 + i * 0.01),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ),
                      );
                    }),
                    // Center glow
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.cyan.withOpacity(0.4),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Center(
                      child: Icon(
                        Icons.warehouse_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: Text(
                    'New Transaction',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductSelector(List<Product> products) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Product>(
          value: _selectedProduct,
          isExpanded: true,
          hint: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.inventory_2_outlined,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Select a product',
                style: GoogleFonts.inter(
                  color: AppColors.textTertiary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          items: products.map((p) {
            return DropdownMenuItem<Product>(
              value: p,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.inventory_2_outlined,
                        color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          p.name,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'SKU: ${p.sku}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (p) => setState(() => _selectedProduct = p),
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.surfaceGray,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: ['STOCK IN', 'STOCK OUT'].map((type) {
          final isActive = _transactionType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _transactionType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: isActive ? AppColors.primaryGradient : null,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    type,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? Colors.white
                          : AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuantityStepper() {
    return Column(
      children: [
        Text(
          'Quantity',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _stepperButton(
              icon: Icons.remove_rounded,
              onTap: () {
                if (_quantity > 1) setState(() => _quantity--);
              },
            ),
            const SizedBox(width: 24),
            Column(
              children: [
                Text(
                  '$_quantity',
                  style: GoogleFonts.outfit(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    height: 1,
                  ),
                ),
                Text(
                  'units',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            _stepperButton(
              icon: Icons.add_rounded,
              onTap: () => setState(() => _quantity++),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stepperButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
    );
  }

  Widget _buildLivePreview() {
    final current = _selectedProduct!.quantity;
    final next = _newStockLevel;
    final isIn = _transactionType == 'STOCK IN';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live Inventory Preview',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.textTertiary)),
                  const SizedBox(height: 4),
                  Text('$current',
                      style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ],
              ),
              const Spacer(),
              Icon(
                isIn
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: isIn ? AppColors.emerald : AppColors.critical,
                size: 28,
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('New Level',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.textTertiary)),
                  const SizedBox(height: 4),
                  Text('$next',
                      style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: isIn ? AppColors.primary : AppColors.critical)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          GradientProgressBar(
            value: _newStockPercent,
            status: next == 0
                ? 'CRITICAL'
                : _newStockPercent < 0.2
                    ? 'LOW'
                    : 'NORMAL',
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseAndUser() {
    return Row(
      children: [
        Expanded(
          child: _miniDropdown(
            label: 'Warehouse',
            value: _selectedWarehouse,
            items: AppConstants.warehouses,
            icon: Icons.warehouse_outlined,
            onChanged: (v) => setState(() => _selectedWarehouse = v!),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _miniDropdown(
            label: 'Updated by',
            value: _selectedUser,
            items: AppConstants.users,
            icon: Icons.person_outline_rounded,
            onChanged: (v) => setState(() => _selectedUser = v!),
          ),
        ),
      ],
    );
  }

  Widget _miniDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Text(
              label,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 16, color: AppColors.textSecondary),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              items: items
                  .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return ScaleTransition(
      scale: _successScale,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: AppColors.emerald,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.emerald.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              'Transaction Confirmed!',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}
