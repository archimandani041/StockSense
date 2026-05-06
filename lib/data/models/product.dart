import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String sku;

  @HiveField(3)
  late String category;

  @HiveField(4)
  late int quantity;

  @HiveField(5)
  late int maxQuantity;

  @HiveField(6)
  late int minThreshold;

  @HiveField(7)
  late DateTime lastUpdated;

  @HiveField(8)
  late String description;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.quantity,
    required this.maxQuantity,
    required this.minThreshold,
    required this.lastUpdated,
    this.description = '',
  });

  double get stockPercentage =>
      maxQuantity > 0 ? (quantity / maxQuantity).clamp(0.0, 1.0) : 0.0;

  String get status {
    final pct = stockPercentage;
    if (quantity == 0) return 'CRITICAL';
    if (pct <= 0.15) return 'CRITICAL';
    if (pct <= 0.35) return 'LOW';
    return 'NORMAL';
  }

  String get statusLabel {
    switch (status) {
      case 'CRITICAL':
        return quantity == 0 ? 'OUT OF STOCK RISK' : 'CRITICAL';
      case 'LOW':
        return 'Reorder Soon';
      default:
        return 'Optimal';
    }
  }

  Product copyWith({
    String? id,
    String? name,
    String? sku,
    String? category,
    int? quantity,
    int? maxQuantity,
    int? minThreshold,
    DateTime? lastUpdated,
    String? description,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      minThreshold: minThreshold ?? this.minThreshold,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      description: description ?? this.description,
    );
  }
}
