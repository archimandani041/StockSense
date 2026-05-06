import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'data/models/product.dart';
import 'data/models/stock_transaction.dart';
import 'data/repositories/product_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'core/constants/app_constants.dart';
import 'app/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Initialize Hive
  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(StockTransactionAdapter());

  // Open Boxes
  final productsBox = await Hive.openBox<Product>(AppConstants.productsBox);
  final transactionsBox =
      await Hive.openBox<StockTransaction>(AppConstants.transactionsBox);

  // Seed data if empty
  final productRepo = ProductRepository(productsBox);
  await productRepo.seedDefaultProducts();

  final txRepo = TransactionRepository(transactionsBox);
  await txRepo.seedDefaultTransactions({'seed': 'dummy'});

  runApp(
    const ProviderScope(
      child: StockSyncApp(),
    ),
  );
}

class StockSyncApp extends StatelessWidget {
  const StockSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StockSync AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainScaffold(),
    );
  }
}
