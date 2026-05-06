import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/product.dart';
import '../data/models/stock_transaction.dart';
import '../data/repositories/product_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../core/constants/app_constants.dart';

// ─── Repository Providers ───────────────────────────────────────────────────

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final box = Hive.box<Product>(AppConstants.productsBox);
  return ProductRepository(box);
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final box = Hive.box<StockTransaction>(AppConstants.transactionsBox);
  return TransactionRepository(box);
});

// ─── Product State ──────────────────────────────────────────────────────────

class ProductNotifier extends StateNotifier<List<Product>> {
  final ProductRepository _repo;

  ProductNotifier(this._repo) : super([]) {
    _loadProducts();
  }

  void _loadProducts() {
    state = _repo.getAllProducts();
  }

  Future<void> addProduct(Product product) async {
    await _repo.addProduct(product);
    _loadProducts();
  }

  Future<void> updateProduct(Product product) async {
    await _repo.updateProduct(product);
    _loadProducts();
  }

  Future<void> deleteProduct(String id) async {
    await _repo.deleteProduct(id);
    _loadProducts();
  }

  Future<void> updateStock(String productId, int newQuantity) async {
    await _repo.updateStock(productId, newQuantity);
    _loadProducts();
  }

  void refresh() => _loadProducts();
}

final productProvider =
    StateNotifierProvider<ProductNotifier, List<Product>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return ProductNotifier(repo);
});

// ─── Filtered Products ──────────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');
final selectedStatusFilterProvider = StateProvider<String?>((ref) => null);

final filteredProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(productProvider);
  final query = ref.watch(searchQueryProvider);
  final category = ref.watch(selectedCategoryProvider);
  final statusFilter = ref.watch(selectedStatusFilterProvider);

  var filtered = products;

  if (query.isNotEmpty) {
    final q = query.toLowerCase();
    filtered = filtered
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q))
        .toList();
  }

  if (category != 'All') {
    filtered = filtered.where((p) => p.category == category).toList();
  }

  if (statusFilter != null) {
    filtered = filtered.where((p) => p.status == statusFilter).toList();
  }

  return filtered;
});

// ─── Transaction State ──────────────────────────────────────────────────────

class TransactionNotifier extends StateNotifier<List<StockTransaction>> {
  final TransactionRepository _repo;

  TransactionNotifier(this._repo) : super([]) {
    _loadAll();
  }

  void _loadAll() {
    state = _repo.getAllTransactions();
  }

  Future<void> addTransaction({
    required String productId,
    required String productName,
    required String type,
    required int quantity,
    required String user,
    required String warehouse,
    required int previousQuantity,
    required int newQuantity,
  }) async {
    await _repo.addTransaction(
      productId: productId,
      productName: productName,
      type: type,
      quantity: quantity,
      user: user,
      warehouse: warehouse,
      previousQuantity: previousQuantity,
      newQuantity: newQuantity,
    );
    _loadAll();
  }

  void refresh() => _loadAll();
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, List<StockTransaction>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return TransactionNotifier(repo);
});

// ─── History Filter ──────────────────────────────────────────────────────────

final historyFilterProvider = StateProvider<String>((ref) => 'Today');

final filteredTransactionsProvider =
    Provider<List<StockTransaction>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  final filter = ref.watch(historyFilterProvider);

  switch (filter) {
    case 'Weekly':
      return repo.getWeeklyTransactions();
    case 'Monthly':
      return repo.getMonthlyTransactions();
    default:
      return repo.getTodayTransactions();
  }
});

// ─── Dashboard Derived Stats ────────────────────────────────────────────────

final dashboardStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final products = ref.watch(productProvider);
  final transactions = ref.watch(transactionProvider);

  final total = products.length;
  final lowStock =
      products.where((p) => p.status == 'LOW' || p.status == 'CRITICAL').length;
  final outOfStock = products.where((p) => p.quantity == 0).length;

  final monthAgo = DateTime.now().subtract(const Duration(days: 30));
  final monthlyTx = transactions.where((t) => t.timestamp.isAfter(monthAgo));
  final monthlyUsage = monthlyTx
      .where((t) => !t.isStockIn)
      .fold(0, (sum, t) => sum + t.quantity);

  final inventoryHealth = total > 0
      ? ((total - outOfStock) / total * 100).round()
      : 0;

  return {
    'totalProducts': total,
    'lowStockItems': lowStock,
    'outOfStock': outOfStock,
    'monthlyUsage': monthlyUsage,
    'inventoryHealth': inventoryHealth,
  };
});

// ─── Sort Provider for Search ───────────────────────────────────────────────
final sortOptionProvider = StateProvider<String>((ref) => 'Alphabetical');

final sortedFilteredProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(filteredProductsProvider);
  final sort = ref.watch(sortOptionProvider);

  final sorted = [...products];
  switch (sort) {
    case 'Quantity':
      sorted.sort((a, b) => a.quantity.compareTo(b.quantity));
      break;
    case 'Last Updated':
      sorted.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
      break;
    default: // Alphabetical
      sorted.sort((a, b) => a.name.compareTo(b.name));
  }
  return sorted;
});
