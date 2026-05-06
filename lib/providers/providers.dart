import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/product.dart';
import '../models/stock_transaction.dart';
import '../repositories/product_repository.dart';
import '../repositories/transaction_repository.dart';
import '../core/constants/app_constants.dart';
import '../services/sync_service.dart';

// ── Services & Repositories ──────────────────────────────────────────────

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService();
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final box = Hive.box<Product>(AppConstants.productsBox);
  return ProductRepository(box);
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final box = Hive.box<StockTransaction>(AppConstants.transactionsBox);
  return TransactionRepository(box);
});

// ── Products State ──────────────────────────────────────────────────────

class ProductNotifier extends StateNotifier<List<Product>> {
  final ProductRepository _repo;

  ProductNotifier(this._repo) : super(_repo.getAllProducts());

  void refresh() {
    state = _repo.getAllProducts();
  }

  Future<void> addProduct(Product product) async {
    await _repo.addProduct(product);
    refresh();
  }

  Future<void> updateProduct(Product product) async {
    await _repo.updateProduct(product);
    refresh();
  }

  Future<void> deleteProduct(String id) async {
    await _repo.deleteProduct(id);
    refresh();
  }

  Future<void> updateStock(String id, int newQuantity) async {
    await _repo.updateStock(id, newQuantity);
    refresh();
  }
}

final productProvider = StateNotifierProvider<ProductNotifier, List<Product>>((ref) {
  return ProductNotifier(ref.watch(productRepositoryProvider));
});

// ── Transactions State ──────────────────────────────────────────────────

class TransactionNotifier extends StateNotifier<List<StockTransaction>> {
  final TransactionRepository _repo;

  TransactionNotifier(this._repo) : super(_repo.getAllTransactions());

  void refresh() {
    state = _repo.getAllTransactions();
  }

  Future<void> addTransaction({
    required String productId,
    required String productName,
    required String transactionType,
    required int quantity,
    required String updatedBy,
    required String warehouse,
    required int previousQuantity,
    required int newQuantity,
  }) async {
    await _repo.addTransaction(
      productId: productId,
      productName: productName,
      transactionType: transactionType,
      quantity: quantity,
      updatedBy: updatedBy,
      warehouse: warehouse,
      previousQuantity: previousQuantity,
      newQuantity: newQuantity,
    );
    refresh();
  }
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, List<StockTransaction>>((ref) {
  return TransactionNotifier(ref.watch(transactionRepositoryProvider));
});

// ── Search & Filter State ───────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');
final selectedStatusFilterProvider = StateProvider<String?>((ref) => null);
final sortOptionProvider = StateProvider<String>((ref) => 'Alphabetical');

final filteredProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(productProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final category = ref.watch(selectedCategoryProvider);
  final status = ref.watch(selectedStatusFilterProvider);

  return products.where((p) {
    final matchesQuery = query.isEmpty ||
        p.productName.toLowerCase().contains(query) ||
        p.sku.toLowerCase().contains(query) ||
        p.category.toLowerCase().contains(query);
    final matchesCategory = category == 'All' || p.category == category;
    final matchesStatus = status == null || p.status == status;
    return matchesQuery && matchesCategory && matchesStatus;
  }).toList();
});

final sortedFilteredProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(filteredProductsProvider);
  final sortOption = ref.watch(sortOptionProvider);

  final sorted = List<Product>.from(products);
  switch (sortOption) {
    case 'Quantity':
      sorted.sort((a, b) => b.quantityAvailable.compareTo(a.quantityAvailable));
      break;
    case 'Last Updated':
      sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      break;
    case 'Alphabetical':
    default:
      sorted.sort((a, b) => a.productName.compareTo(b.productName));
      break;
  }
  return sorted;
});

// ── Dashboard Analytics State ───────────────────────────────────────────

final dashboardStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final products = ref.watch(productProvider);

  int lowStock = 0;
  int criticalStock = 0;
  int outOfStock = 0;
  int totalThresholdSum = 0;
  int totalQuantitySum = 0;

  for (final p in products) {
    if (p.quantityAvailable == 0) outOfStock++;
    else if (p.quantityAvailable <= p.minimumThreshold) criticalStock++;
    else if (p.quantityAvailable <= p.minimumThreshold * 1.5) lowStock++;

    totalThresholdSum += p.minimumThreshold * 3; // 3x threshold is '100% health'
    totalQuantitySum += p.quantityAvailable;
  }

  // Calculate dynamic inventory health
  int healthPercentage = 100;
  if (totalThresholdSum > 0) {
    healthPercentage = ((totalQuantitySum / totalThresholdSum) * 100).clamp(0, 100).toInt();
  } else if (products.isEmpty) {
    healthPercentage = 0;
  }

  return {
    'totalProducts': products.length,
    'lowStockItems': lowStock + criticalStock,
    'outOfStockItems': outOfStock,
    'inventoryHealth': healthPercentage,
  };
});

// Dynamic AI Restocking Recommendation
final aiRecommendationProvider = Provider<Map<String, String>>((ref) {
  final products = ref.watch(productProvider);
  final transactions = ref.watch(transactionProvider);

  // Default if nothing to recommend
  if (products.isEmpty) {
    return {
      'title': 'System Ready',
      'detail': 'Add your first product to begin tracking inventory.',
      'action': 'Add Product',
    };
  }

  // Find most critical item
  final criticalItems = products.where((p) => p.quantityAvailable <= p.minimumThreshold).toList();
  if (criticalItems.isNotEmpty) {
    criticalItems.sort((a, b) => a.quantityAvailable.compareTo(b.quantityAvailable));
    final target = criticalItems.first;
    
    // Check usage this week
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final recentUsage = transactions
        .where((t) => t.productId == target.id && t.transactionType == 'STOCK_OUT' && t.timestamp.isAfter(weekAgo))
        .fold(0, (sum, t) => sum + t.quantity);

    return {
      'title': 'Restock ${target.productName}',
      'detail': 'Only ${target.quantityAvailable} left. High usage detected ($recentUsage units/week).',
      'action': 'Generate PO',
    };
  }

  return {
    'title': 'Optimal Levels',
    'detail': 'All inventory items are currently above their minimum thresholds.',
    'action': 'View Analytics',
  };
});

// Dynamic Monthly Usage Data (from actual transactions)
final monthlyUsageProvider = Provider<List<double>>((ref) {
  final transactions = ref.watch(transactionProvider);
  
  // Initialize 6 months of data
  List<double> monthlyData = List.filled(6, 0.0);
  final now = DateTime.now();

  for (final tx in transactions) {
    if (tx.transactionType == 'STOCK_OUT') {
      final monthDiff = (now.year - tx.timestamp.year) * 12 + now.month - tx.timestamp.month;
      if (monthDiff >= 0 && monthDiff < 6) {
        // Reverse index: 0 is oldest (5 months ago), 5 is current month
        final idx = 5 - monthDiff;
        monthlyData[idx] += tx.quantity.toDouble();
      }
    }
  }

  // If there's no data at all, return dummy data just to keep the chart from crashing
  // However, the user wants fully dynamic. Let's return the real zeros.
  return monthlyData;
});

// ── History Filter State ────────────────────────────────────────────────

final historyFilterProvider = StateProvider<String>((ref) => 'Today');

final filteredTransactionsProvider = Provider<List<StockTransaction>>((ref) {
  final filter = ref.watch(historyFilterProvider);
  final repo = ref.watch(transactionRepositoryProvider);

  if (filter == 'Weekly') {
    return repo.getWeeklyTransactions();
  } else if (filter == 'Monthly') {
    return repo.getMonthlyTransactions();
  }
  return repo.getTodayTransactions();
});
