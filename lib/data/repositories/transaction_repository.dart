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
    required String type,
    required int quantity,
    required String user,
    required String warehouse,
    required int previousQuantity,
    required int newQuantity,
  }) async {
    final tx = StockTransaction(
      id: _uuid.v4(),
      productId: productId,
      productName: productName,
      type: type,
      quantity: quantity,
      user: user,
      warehouse: warehouse,
      timestamp: DateTime.now(),
      previousQuantity: previousQuantity,
      newQuantity: newQuantity,
    );
    await _box.put(tx.id, tx);
    return tx;
  }

  int getTodayNetChange() {
    return getTodayTransactions()
        .fold(0, (sum, t) => sum + t.signedQuantity);
  }

  Future<void> seedDefaultTransactions(Map<String, String> productNames) async {
    if (_box.isNotEmpty) return;

    final now = DateTime.now();
    final transactions = [
      StockTransaction(
        id: _uuid.v4(),
        productId: productNames.keys.first,
        productName: 'Ceramic Tiles (Box)',
        type: 'STOCK IN',
        quantity: 450,
        user: 'Alex Johnson',
        warehouse: 'Warehouse A',
        timestamp: now.subtract(const Duration(minutes: 2)),
        previousQuantity: 0,
        newQuantity: 450,
      ),
      StockTransaction(
        id: _uuid.v4(),
        productId: productNames.keys.skip(1).first,
        productName: 'Engine Oil 5W-30',
        type: 'STOCK OUT',
        quantity: 24,
        user: 'Marcus V.',
        warehouse: 'Fulfillment Center',
        timestamp: now.subtract(const Duration(hours: 1)),
        previousQuantity: 36,
        newQuantity: 12,
      ),
      StockTransaction(
        id: _uuid.v4(),
        productId: productNames.keys.skip(2).first,
        productName: 'LED Panels 60W',
        type: 'STOCK IN',
        quantity: 100,
        user: 'Sarah M.',
        warehouse: 'Warehouse B',
        timestamp: now.subtract(const Duration(hours: 4)),
        previousQuantity: 0,
        newQuantity: 100,
      ),
      StockTransaction(
        id: _uuid.v4(),
        productId: productNames.keys.first,
        productName: 'Quantum Processor X1',
        type: 'STOCK IN',
        quantity: 50,
        user: 'Sarah M.',
        warehouse: 'Warehouse A',
        timestamp: now.subtract(const Duration(hours: 6)),
        previousQuantity: 0,
        newQuantity: 50,
      ),
      StockTransaction(
        id: _uuid.v4(),
        productId: productNames.keys.skip(1).first,
        productName: 'Liquid Cooling Unit',
        type: 'STOCK OUT',
        quantity: 12,
        user: 'Marcus V.',
        warehouse: 'Fulfillment Center',
        timestamp: now.subtract(const Duration(hours: 9)),
        previousQuantity: 60,
        newQuantity: 48,
      ),
      StockTransaction(
        id: _uuid.v4(),
        productId: productNames.keys.skip(2).first,
        productName: 'Optical Sensors v4',
        type: 'STOCK IN',
        quantity: 112,
        user: 'System AI',
        warehouse: 'Warehouse A',
        timestamp: now.subtract(const Duration(hours: 10)),
        previousQuantity: 0,
        newQuantity: 112,
      ),
      StockTransaction(
        id: _uuid.v4(),
        productId: productNames.keys.first,
        productName: 'Thermal Paste 50g',
        type: 'STOCK OUT',
        quantity: 5,
        user: 'Sarah M.',
        warehouse: 'Lab Storage',
        timestamp: now.subtract(const Duration(hours: 11)),
        previousQuantity: 40,
        newQuantity: 35,
      ),
    ];

    for (final t in transactions) {
      await _box.put(t.id, t);
    }
  }
}
