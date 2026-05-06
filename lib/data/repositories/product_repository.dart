import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';

class ProductRepository {
  final Box<Product> _box;
  final _uuid = const Uuid();

  ProductRepository(this._box);

  List<Product> getAllProducts() {
    return _box.values.toList()
      ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
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
    product.lastUpdated = DateTime.now();
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
      product.quantity = newQuantity;
      product.lastUpdated = DateTime.now();
      await product.save();
    }
  }

  List<Product> getLowStockProducts() {
    return _box.values.where((p) => p.status != 'NORMAL').toList();
  }

  List<Product> getOutOfStockProducts() {
    return _box.values.where((p) => p.quantity == 0).toList();
  }

  List<Product> searchProducts(String query, {String? category, String? status}) {
    var products = _box.values.toList();

    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      products = products
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
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

  Future<void> seedDefaultProducts() async {
    if (_box.isNotEmpty) return;

    final now = DateTime.now();
    final products = [
      Product(
        id: _uuid.v4(),
        name: 'Core Processor i9',
        sku: 'CP-I9-001',
        category: 'Electronics',
        quantity: 450,
        maxQuantity: 530,
        minThreshold: 100,
        lastUpdated: now.subtract(const Duration(hours: 2)),
        description: 'High-performance Intel Core i9 processor',
      ),
      Product(
        id: _uuid.v4(),
        name: 'Industrial Drill Bit',
        sku: 'IDB-42-X',
        category: 'Hardware',
        quantity: 42,
        maxQuantity: 200,
        minThreshold: 50,
        lastUpdated: now.subtract(const Duration(hours: 5)),
        description: 'Tungsten carbide industrial drill bit set',
      ),
      Product(
        id: _uuid.v4(),
        name: 'Safety Goggles XL',
        sku: 'SG-XL-007',
        category: 'Safety',
        quantity: 8,
        maxQuantity: 150,
        minThreshold: 25,
        lastUpdated: now.subtract(const Duration(hours: 12)),
        description: 'Anti-fog UV protection safety goggles',
      ),
      Product(
        id: _uuid.v4(),
        name: 'Torque Wrench Set',
        sku: 'TW-SET-22',
        category: 'Tools',
        quantity: 128,
        maxQuantity: 160,
        minThreshold: 30,
        lastUpdated: now.subtract(const Duration(hours: 1)),
        description: 'Professional torque wrench set 10-150 Nm',
      ),
      Product(
        id: _uuid.v4(),
        name: 'Quantum Core X1',
        sku: 'QC-99210-A',
        category: 'Electronics',
        quantity: 45,
        maxQuantity: 200,
        minThreshold: 40,
        lastUpdated: now.subtract(const Duration(minutes: 30)),
        description: 'Next-gen quantum computing module',
      ),
      Product(
        id: _uuid.v4(),
        name: 'Industrial Bolts X-2',
        sku: 'IB-X2-500',
        category: 'Hardware',
        quantity: 18,
        maxQuantity: 1000,
        minThreshold: 100,
        lastUpdated: now.subtract(const Duration(hours: 3)),
        description: 'High-tensile M10 industrial bolts, box of 500',
      ),
      Product(
        id: _uuid.v4(),
        name: 'Optical Sensors v4',
        sku: 'OS-V4-112',
        category: 'Electronics',
        quantity: 112,
        maxQuantity: 300,
        minThreshold: 50,
        lastUpdated: now.subtract(const Duration(hours: 8)),
        description: 'High-precision optical proximity sensors',
      ),
      Product(
        id: _uuid.v4(),
        name: 'Ceramic Tiles (Box)',
        sku: 'CT-BOX-450',
        category: 'Hardware',
        quantity: 450,
        maxQuantity: 600,
        minThreshold: 80,
        lastUpdated: now.subtract(const Duration(minutes: 120)),
        description: 'Premium grade ceramic wall tiles, 60x60cm',
      ),
      Product(
        id: _uuid.v4(),
        name: 'LED Panels 60W',
        sku: 'LED-60W-P',
        category: 'Electronics',
        quantity: 89,
        maxQuantity: 250,
        minThreshold: 30,
        lastUpdated: now.subtract(const Duration(hours: 4)),
        description: 'Energy efficient LED panel lights 60W',
      ),
      Product(
        id: _uuid.v4(),
        name: 'Engine Oil 5W-30',
        sku: 'EO-5W30-L',
        category: 'Tools',
        quantity: 12,
        maxQuantity: 100,
        minThreshold: 20,
        lastUpdated: now.subtract(const Duration(hours: 1)),
        description: 'Synthetic engine oil 5W-30, 4L can',
      ),
    ];

    for (final p in products) {
      await _box.put(p.id, p);
    }
  }
}
