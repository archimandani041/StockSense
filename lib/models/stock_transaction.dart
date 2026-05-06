import 'package:hive/hive.dart';

part 'stock_transaction.g.dart';

@HiveType(typeId: 1)
class StockTransaction extends HiveObject {
  @HiveField(0)
  late String transactionId;

  @HiveField(1)
  late String productId;

  @HiveField(2)
  late String transactionType; // 'stock_in' or 'stock_out'

  @HiveField(3)
  late int quantity;

  @HiveField(4)
  late DateTime timestamp;

  @HiveField(5)
  late String updatedBy;

  // Additional fields for UI optimization
  @HiveField(6)
  late String productName;
  
  @HiveField(7)
  late String warehouse;

  @HiveField(8)
  late int previousQuantity;

  @HiveField(9)
  late int newQuantity;

  StockTransaction({
    required this.transactionId,
    required this.productId,
    required this.transactionType,
    required this.quantity,
    required this.timestamp,
    required this.updatedBy,
    required this.productName,
    this.warehouse = '',
    this.previousQuantity = 0,
    this.newQuantity = 0,
  });

  bool get isStockIn => transactionType.toLowerCase() == 'stock_in';

  int get signedQuantity => isStockIn ? quantity : -quantity;

  String get quantityDisplay => '${isStockIn ? '+' : '-'}$quantity';
}
