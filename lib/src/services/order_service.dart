import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/supabase.dart';
import '../models/order.dart';

class OrderService extends ChangeNotifier {
  List<Order> _userOrders = [];

  List<Order> get userOrders => _userOrders;

  StreamSubscription? _userOrdersSubscription; // Store subscription here

  Future<void> placeOrder(Order order) async {
    try {
      // Added .execute() here to actually run the insert
      await SupabaseConfig.client.from('orders').insert(order.toJson()).execute();
    } catch (e) {
      throw Exception('Failed to place order: $e');
    }
  }

  Future<List<Order>> fetchOrders(String customerId) async {
    try {
      final response = await SupabaseConfig.client
          .from('orders')
          .select()
          .eq('customer_id', customerId)
          .execute();

      final data = response.data as List<dynamic>?;

      if (data == null) return [];

      return data
          .map((item) => Order.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Order>> fetchAllOrders() async {
    try {
      final response =
      await SupabaseConfig.client.from('orders').select().execute();

      final data = response.data as List<dynamic>?;

      if (data == null) return [];

      return data
          .map((item) => Order.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      // Added .execute() here to actually run the update
      await SupabaseConfig.client
          .from('orders')
          .update({'status': status})
          .eq('id', orderId)
          .execute();
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  Stream<List<Order>> streamOrders() {
    return SupabaseConfig.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .map((event) {
      // Added cast here to Map<String, dynamic> to prevent errors
      return event.map<Order>((item) => Order.fromJson(item as Map<String, dynamic>)).toList();
    });
  }

  // Fetch user orders once and update internal list
  Future<void> fetchUserOrders(String customerId) async {
    _userOrders = await fetchOrders(customerId);
    notifyListeners();
  }

  // Stream user orders and update internal list live
  void listenToUserOrders(String customerId) {
    // Cancel previous subscription if any
    _userOrdersSubscription?.cancel();

    _userOrdersSubscription = SupabaseConfig.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('customer_id', customerId)
        .listen((event) {
      _userOrders = event.map<Order>((item) => Order.fromJson(item as Map<String, dynamic>)).toList();
      notifyListeners();
    });
  }

  // New method to stop listening to user orders
  void stopListeningToUserOrders() {
    _userOrdersSubscription?.cancel();
    _userOrdersSubscription = null;
  }
}







