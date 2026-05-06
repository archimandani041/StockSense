import 'package:hive/hive.dart';
import '../models/product.dart';

class ProductRepository {
  final Box<Product> _box;

  ProductRepository(this._box);

  List<Product> getAllProducts() {
    return _box.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Product? getProductById(String id) {
    try {
      return _box.values.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addProduct(Product product) async {
    await _box.put(product.id, product);
  }

  Future<void> updateProduct(Product product) async {
    product.updatedAt = DateTime.now();
    await _box.put(product.id, product);
  }

  Future<void> deleteProduct(String id) async {
    final key = _box.keys.firstWhere(
      (k) => _box.get(k)?.id == id,
      orElse: () => null,
    );
    if (key != null) await _box.delete(key);
  }

  Future<void> updateStock(String productId, int newQuantity) async {
    final product = getProductById(productId);
    if (product != null) {
      product.quantityAvailable = newQuantity;
      product.updatedAt = DateTime.now();
      await product.save();
    }
  }

  List<Product> getLowStockProducts() {
    return _box.values.where((p) => p.status != 'NORMAL').toList();
  }

  List<Product> getOutOfStockProducts() {
    return _box.values.where((p) => p.quantityAvailable == 0).toList();
  }

  List<Product> searchProducts(String query, {String? category, String? status}) {
    var products = _box.values.toList();

    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      products = products
          .where((p) =>
              p.productName.toLowerCase().contains(q) ||
              p.sku.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q))
          .toList();
    }

    if (category != null && category != 'All') {
      products = products.where((p) => p.category == category).toList();
    }

    if (status != null) {
      products = products.where((p) => p.status == status).toList();
    }

    return products;
  }
}
