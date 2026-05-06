class AppConstants {
  // Hive Box Names
  static const String productsBox = 'products_box';
  static const String transactionsBox = 'transactions_box';

  // Categories
  static const List<String> categories = [
    'All',
    'Electronics',
    'Hardware',
    'Safety',
    'Tools',
    'Medical',
    'Chemicals',
  ];

  // Stock Status
  static const String statusNormal = 'NORMAL';
  static const String statusLow = 'LOW';
  static const String statusCritical = 'CRITICAL';

  // Transaction Types
  static const String stockIn = 'STOCK IN';
  static const String stockOut = 'STOCK OUT';

  // Warehouses
  static const List<String> warehouses = [
    'Warehouse A',
    'Warehouse B',
    'Fulfillment Center',
    'Lab Storage',
    'Main Campus',
  ];

  // Users
  static const List<String> users = [
    'Alex Johnson',
    'Sarah M.',
    'Marcus V.',
    'System AI',
    'Dr. Chen',
  ];

  // AI Recommendations
  static const List<Map<String, String>> aiRecommendations = [
    {
      'title': 'Restock Industrial Bolts (X-2)',
      'detail': 'Usage increased 15% this week.',
      'action': 'Order Now',
    },
    {
      'title': 'Safety Goggles XL running critically low',
      'detail': 'Only 8 units remain. Reorder threshold: 25 units.',
      'action': 'Reorder',
    },
    {
      'title': 'Core Processor i9 trending upward',
      'detail': 'Demand +22% vs last month. Consider bulk order.',
      'action': 'Order Now',
    },
    {
      'title': 'Optical Sensors v4 — automated reorder triggered',
      'detail': 'System AI initiated reorder of 200 units.',
      'action': 'View Order',
    },
  ];

  // Monthly chart data (last 7 months)
  static const List<double> monthlyUsageData = [
    420, 380, 510, 470, 595, 540, 620,
  ];

  static const List<String> monthLabels = [
    'Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr', 'May',
  ];
}
