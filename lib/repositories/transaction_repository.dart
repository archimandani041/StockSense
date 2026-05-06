import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/stock_transaction.dart';

class TransactionRepository {
  final Box<StockTransaction> _box;
  final _uuid = const Uuid();

  TransactionRepository(this._box);

  List<StockTransaction> getAllTransactions() {
    return _box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<StockTransaction> getTodayTransactions() {
    final today = DateTime.now();
    return _box.values.where((t) {
      return t.timestamp.year == today.year &&
          t.timestamp.month == today.month &&
          t.timestamp.day == today.day;
    }).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<StockTransaction> getWeeklyTransactions() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _box.values
        .where((t) => t.timestamp.isAfter(weekAgo))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<StockTransaction> getMonthlyTransactions() {
    final monthAgo = DateTime.now().subtract(const Duration(days: 30));
    return _box.values
        .where((t) => t.timestamp.isAfter(monthAgo))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<StockTransaction> addTransaction({
    required String productId,
    required String productName,
    required String transactionType,
    required int quantity,
    required String updatedBy,
    required String warehouse,
    required int previousQuantity,
    required int newQuantity,
  }) async {
    final tx = StockTransaction(
      transactionId: _uuid.v4(),
      productId: productId,
      productName: productName,
      transactionType: transactionType,
      quantity: quantity,
      updatedBy: updatedBy,
      warehouse: warehouse,
      timestamp: DateTime.now(),
      previousQuantity: previousQuantity,
      newQuantity: newQuantity,
    );
    await _box.put(tx.transactionId, tx);
    return tx;
  }

  int getTodayNetChange() {
    return getTodayTransactions()
        .fold(0, (sum, t) => sum + t.signedQuantity);
  }
}
