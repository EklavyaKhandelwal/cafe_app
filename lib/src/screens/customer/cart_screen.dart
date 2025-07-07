import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/order_service.dart';
import '../../models/order.dart';
import '../../models/user.dart';
import '../../widgets/cart_provider.dart';
import 'order_success_splash_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final specialRequestController = TextEditingController();
  final nameController = TextEditingController();
  final tableController = TextEditingController();
  bool _isPlacingOrder = false;
  String? _nameError;
  String? _tableError;
  late Razorpay _razorpay;
  Order? _pendingOrder;
  // Removed _selectedPaymentMethod as only Razorpay will be available
  final String serverUrl = 'http://192.168.29.253:5000/create-order';

  @override
  void initState() {
    super.initState();
    nameController.addListener(_validateInputs);
    tableController.addListener(_validateInputs);
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    specialRequestController.dispose();
    nameController.removeListener(_validateInputs);
    nameController.dispose();
    tableController.removeListener(_validateInputs);
    tableController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  void _validateInputs() {
    setState(() {
      _nameError = nameController.text.trim().isEmpty ? 'Name is required' : null;
      _tableError = tableController.text.trim().isEmpty ? 'Table number is required' : null;
    });
  }

  Future<Map<String, dynamic>?> _createServerOrder(Order order) async {
    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': order.total, // Remove * 100, backend handles conversion
          'currency': 'INR',
          'receipt': order.id,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create order: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error creating order: $e',
            style: GoogleFonts.lora(color: const Color(0xFFF5E6CC)),
          ),
          backgroundColor: const Color(0xFF2E1F1F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return null;
    }
  }

  void _startPayment(Order order, CartProvider cartProvider) async {
    setState(() => _isPlacingOrder = true);

    final serverOrder = await _createServerOrder(order);
    if (serverOrder == null) {
      setState(() => _isPlacingOrder = false);
      return;
    }

    var options = {
      'key': 'rzp_live_Y7TfZS3eA2vI0U', // Replace with your Razorpay Test Key
      'order_id': serverOrder['order_id'],
      'amount': serverOrder['amount'],
      'currency': serverOrder['currency'],
      'name': 'TeaTime Stories',
      'description': 'Food Order',
      'prefill': {
        'contact': '9876543210',
        'email': 'eklavya@example.com',
      },
      'method': {
        'upi': true,      // Enable UPI
        'wallet': true,   // Enable wallets (Google Pay, PhonePe, Paytm, etc.)
        'card': true,     // Enable card payments
        'netbanking': true // Enable net banking
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error initiating payment: $e',
            style: GoogleFonts.lora(color: const Color(0xFFF5E6CC)),
          ),
          backgroundColor: const Color(0xFF2E1F1F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      setState(() => _isPlacingOrder = false);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print("✅ Payment Success: ${response.paymentId}");
    if (_pendingOrder != null) {
      _placeOrderAfterPayment(_pendingOrder!);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print("❌ Payment Failed: ${response.message}");
    setState(() => _isPlacingOrder = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payment failed: ${response.message}',
          style: GoogleFonts.lora(color: const Color(0xFFF5E6CC)),
        ),
        backgroundColor: const Color(0xFF2E1F1F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    _pendingOrder = null;
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print("💼 External Wallet Selected: ${response.walletName}");
  }

  Future<void> _placeOrderAfterPayment(Order order) async {
    try {
      await Provider.of<OrderService>(context, listen: false).placeOrder(order);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.clearCart();
      specialRequestController.clear();
      nameController.clear();
      tableController.clear();
      // Show splash screen before navigating
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const OrderSuccessSplashScreen(),
        ),
      );
      // Navigate to Thank You page
      Navigator.of(context).pushReplacementNamed('/thank-you');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to place order: $e',
            style: GoogleFonts.lora(color: const Color(0xFFF5E6CC)),
          ),
          backgroundColor: const Color(0xFF2E1F1F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      setState(() => _isPlacingOrder = false);
      _pendingOrder = null;
    }
  }

  Future<void> _confirmOrder(BuildContext context, CartProvider cartProvider, User user) async { // Removed paymentMethod parameter
    _validateInputs();
    if (_nameError != null || _tableError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter both your name and table number.',
            style: GoogleFonts.lora(color: const Color(0xFFF5E6CC)),
          ),
          backgroundColor: const Color(0xFF2E1F1F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      customerId: user.id,
      customerName: nameController.text.trim(),
      tableNumber: tableController.text.trim(),
      items: cartProvider.cartItems.entries
          .map((e) => OrderItem(menuItemId: e.key.id, quantity: e.value))
          .toList(),
      status: 'Pending',
      specialRequest: specialRequestController.text.isNotEmpty ? specialRequestController.text : null,
      timestamp: DateTime.now(),
      total: cartProvider.calculateTotal(),
      paymentMethod: 'Razorpay', // Hardcoded to Razorpay
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDF6E3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Confirm Order',
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFF3A2A2A),
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to place this order for ₹${cartProvider.calculateTotal().toStringAsFixed(2)} using Razorpay?', // Updated text
          style: GoogleFonts.lora(color: const Color(0xFF3A2A2A), fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.lora(color: const Color(0xFF3A2A2A), fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE2B570),
              foregroundColor: const Color(0xFF2E1F1F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Confirm',
              style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isPlacingOrder = true);
      _pendingOrder = order;
      _startPayment(order, cartProvider); // Directly start Razorpay payment
    }
  }

  Widget _buildCartItems(CartProvider cartProvider) {
    if (cartProvider.cartItems.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.shopping_cart_outlined,
                size: 80,
                color: Color(0xFFE2B570),
              ),
              const SizedBox(height: 16),
              Text(
                'Your cart is empty',
                style: GoogleFonts.lora(
                  color: const Color(0xFF3A2A2A),
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final item = cartProvider.cartItems.keys.elementAt(index);
          final quantity = cartProvider.cartItems[item]!;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              color: const Color(0xFFFDF6E3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image,
                      color: Color(0xFF4A3726),
                      size: 50,
                    ),
                  ),
                ),
                title: Text(
                  item.name,
                  style: GoogleFonts.lora(
                    color: const Color(0xFF3A2A2A),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  '₹${item.price.toStringAsFixed(2)} x $quantity',
                  style: GoogleFonts.lora(
                    color: const Color(0xFF4A3726),
                    fontSize: 14,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, color: Color(0xFFE2B570)),
                      onPressed: () => cartProvider.removeFromCart(item),
                    ),
                    Text(
                      '$quantity',
                      style: GoogleFonts.lora(
                        color: const Color(0xFF3A2A2A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Color(0xFFE2B570)),
                      onPressed: () => cartProvider.addToCart(item),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        childCount: cartProvider.cartItems.length,
      ),
    );
  }

  Widget _buildSpecialRequest() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          controller: specialRequestController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Special Requests',
            labelStyle: GoogleFonts.lora(color: const Color(0xFF3A2A2A)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4A3726)),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF4A3726)),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2B570), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF5E6CC),
          ),
          style: GoogleFonts.lora(color: const Color(0xFF3A2A2A)),
        ),
      ),
    );
  }

  Widget _buildCustomerDetails() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          color: const Color(0xFFFDF6E3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Customer Name',
                    labelStyle: GoogleFonts.lora(color: const Color(0xFF3A2A2A)),
                    errorText: _nameError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF4A3726)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2B570), width: 2),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5E6CC),
                  ),
                  style: GoogleFonts.lora(color: const Color(0xFF3A2A2A)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tableController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Table Number',
                    labelStyle: GoogleFonts.lora(color: const Color(0xFF3A2A2A)),
                    errorText: _tableError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF4A3726)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2B570), width: 2),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5E6CC),
                  ),
                  style: GoogleFonts.lora(color: const Color(0xFF3A2A2A)),
                ),
                const SizedBox(height: 16),
                // Removed the Row with payment method selection buttons,
                // as only Razorpay is available now.
                Center( // Center the single payment button
                  child: ElevatedButton.icon(
                    onPressed: _isPlacingOrder ? null : () {
                      // No need to setState for _selectedPaymentMethod,
                      // as it's implicitly Razorpay now.
                    },
                    icon: const Icon(Icons.payment, color: Color(0xFFF5E6CC)),
                    label: Text(
                      'Pay with Razorpay',
                      style: GoogleFonts.lora(
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFF5E6CC),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700, // Always Razorpay style
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      elevation: 8, // Always elevated
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(CartProvider cartProvider, User? user) {
    final isButtonEnabled =
        cartProvider.cartItems.isNotEmpty && user != null && !_isPlacingOrder;

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFFFDF6E3),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ₹${cartProvider.calculateTotal().toStringAsFixed(2)}',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3A2A2A),
                  ),
                ),
                if (cartProvider.cartItems.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      cartProvider.clearCart();
                      specialRequestController.clear();
                      nameController.clear();
                      tableController.clear();
                    },
                    child: Text(
                      'Clear Cart',
                      style: GoogleFonts.lora(
                        color: const Color(0xFF4A3726),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: isButtonEnabled
                  ? () => _confirmOrder(context, cartProvider, user!) // Removed paymentMethod argument
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE2B570),
                foregroundColor: const Color(0xFF2E1F1F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isPlacingOrder
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF2E1F1F),
                ),
              )
                  : Text(
                'Place Order',
                style: GoogleFonts.lora(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final user = Provider.of<User?>(context);

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2E1F1F),
                Color(0xFF4A3726),
              ],
            ),
          ),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 100.0,
                floating: true,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Your Cart',
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFF5E6CC),
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      shadows: [
                        Shadow(
                          blurRadius: 8.0,
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF2E1F1F),
                          Color(0xFF4A3726),
                        ],
                      ),
                    ),
                  ),
                ),
                elevation: 0,
                backgroundColor: Colors.transparent,
                centerTitle: true,
              ),
              _buildCartItems(cartProvider),
              _buildSpecialRequest(),
              _buildCustomerDetails(),
              _buildFooter(cartProvider, user),
            ],
          ),
        ),
      ),
    );
  }
}