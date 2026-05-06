import 'package:hive/hive.dart';

part 'stock_transaction.g.dart';

@HiveType(typeId: 1)
class StockTransaction extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String productId;

  @HiveField(2)
  late String productName;

  @HiveField(3)
  late String type; // 'STOCK IN' or 'STOCK OUT'

  @HiveField(4)
  late int quantity;

  @HiveField(5)
  late String user;

  @HiveField(6)
  late String warehouse;

  @HiveField(7)
  late DateTime timestamp;

  @HiveField(8)
  late int previousQuantity;

  @HiveField(9)
  late int newQuantity;

  StockTransaction({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.user,
    required this.warehouse,
    required this.timestamp,
    required this.previousQuantity,
    required this.newQuantity,
  });

  bool get isStockIn => type == 'STOCK IN';

  String get quantityDisplay =>
      isStockIn ? '+$quantity' : '-$quantity';

  int get signedQuantity => isStockIn ? quantity : -quantity;
}
