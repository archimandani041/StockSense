import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'core/theme/app_theme.dart';
import 'models/product.dart';
import 'models/stock_transaction.dart';
import 'models/user.dart';
import 'core/constants/app_constants.dart';
import 'screens/auth/auth_wrapper.dart';

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
  Hive.registerAdapter(UserAdapter());

  // Open Boxes
  await Hive.openBox<Product>(AppConstants.productsBox);
  await Hive.openBox<StockTransaction>(AppConstants.transactionsBox);
  await Hive.openBox<User>(AppConstants.usersBox);
  await Hive.openBox(AppConstants.sessionBox);

  // Seed default user if not exists
  await _seedDefaultUser();

  runApp(
    const ProviderScope(
      child: StockSenseApp(),
    ),
  );
}

class StockSenseApp extends StatelessWidget {
  const StockSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StockSense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}

Future<void> _seedDefaultUser() async {
  final box = Hive.box<User>(AppConstants.usersBox);
  
  // requested user
  const email = 'mandani@gmail.com';
  
  final exists = box.values.any((u) => u.email.toLowerCase() == email.toLowerCase());
  
  if (!exists) {
    const password = '1234567';
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes).toString();
    
    final user = User(
      id: const Uuid().v4(),
      name: 'Archi Mandani',
      email: email,
      passwordHash: hash,
      createdAt: DateTime.now(),
    );
    
    await box.put(user.id, user);
    print('DEBUG: Seeded default user: $email');
  }
}
