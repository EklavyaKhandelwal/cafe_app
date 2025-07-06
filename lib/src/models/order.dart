import 'package:teatimestories/src/models/menu_item.dart';

class OrderItem {
  final String menuItemId;
  final int quantity;

  OrderItem({required this.menuItemId, required this.quantity});

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      menuItemId: json['menu_item_id'] as String,
      quantity: json['quantity'] as int,
    );
  }

  // Instead of a static name, we dynamically get the name from menu items
  String getName(List<MenuItem> menuItems) {
    return menuItems.firstWhere(
          (item) => item.id == menuItemId,
      orElse: () => MenuItem(id: '', name: 'Unknown', description: '', price: 0, imageUrl: '', category: ''),
    ).name;
  }

  Map<String, dynamic> toJson() {
    return {
      'menu_item_id': menuItemId,
      'quantity': quantity,
    };
  }
}

class Order {
  final String id;
  final String customerId;
  final String customerName;
  final List<OrderItem> items;
  final String status;
  final String? specialRequest;
  final DateTime timestamp;
  final double total;
  final String tableNumber;
  final String? paymentMethod;// ✅ NEW FIELD

  Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.status,
    this.specialRequest,
    required this.timestamp,
    required this.total,
    required this.tableNumber,
    required this.paymentMethod,// ✅ NEW FIELD
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      customerName: json['customer_name'] as String,
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      status: json['status'] as String,
      specialRequest: json['special_request'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      total: (json['total'] as num).toDouble(),
      tableNumber: json['table_number'] as String, paymentMethod: '', // ✅
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'items': items.map((item) => item.toJson()).toList(),
      'status': status,
      'special_request': specialRequest,
      'timestamp': timestamp.toIso8601String(),
      'total': total,
      'table_number': tableNumber, // ✅
    };
  }
}
