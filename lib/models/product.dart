import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String productName;

  @HiveField(2)
  late String category;

  @HiveField(3)
  late int quantityAvailable;

  @HiveField(4)
  late int minimumThreshold;

  @HiveField(5)
  late DateTime createdAt;

  @HiveField(6)
  late DateTime updatedAt;

  // Additional helper fields not strictly in requirements but useful for UI
  @HiveField(7)
  late String sku;

  Product({
    required this.id,
    required this.productName,
    required this.category,
    required this.quantityAvailable,
    required this.minimumThreshold,
    required this.createdAt,
    required this.updatedAt,
    this.sku = '',
  });

  // Dynamic calculations based on real data
  double get stockPercentage {
    if (minimumThreshold <= 0) return quantityAvailable > 0 ? 1.0 : 0.0;
    // Assume 3x minimumThreshold is "full capacity"
    final maxCapacity = minimumThreshold * 3;
    return (quantityAvailable / maxCapacity).clamp(0.0, 1.0);
  }

  String get status {
    if (quantityAvailable == 0) return 'OUT OF STOCK';
    if (quantityAvailable <= minimumThreshold) return 'CRITICAL';
    if (quantityAvailable <= minimumThreshold * 1.5) return 'LOW';
    return 'NORMAL';
  }

  String get statusLabel {
    switch (status) {
      case 'OUT OF STOCK':
        return 'Out of Stock';
      case 'CRITICAL':
        return 'Critical Level';
      case 'LOW':
        return 'Reorder Soon';
      default:
        return 'Optimal';
    }
  }

  Product copyWith({
    String? id,
    String? productName,
    String? category,
    int? quantityAvailable,
    int? minimumThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? sku,
  }) {
    return Product(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      quantityAvailable: quantityAvailable ?? this.quantityAvailable,
      minimumThreshold: minimumThreshold ?? this.minimumThreshold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sku: sku ?? this.sku,
    );
  }
}
