import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teatimestories/src/services/order_service.dart';
import 'package:teatimestories/src/widgets/order_tile.dart';

class OrderStatusScreen extends StatefulWidget {
  final String customerId;

  const OrderStatusScreen({super.key, required this.customerId});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> with SingleTickerProviderStateMixin {
  late final OrderService _orderService;
  late AnimationController _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _orderService = context.read<OrderService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _orderService.fetchUserOrders(widget.customerId);
        _orderService.listenToUserOrders(widget.customerId);
      }
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _orderService.stopListeningToUserOrders();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderService = context.watch<OrderService>();
    final orders = orderService.userOrders ?? [];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A1212), // Darker top gradient
                  Color(0xFF2E1F1F), // Darker bottom gradient
                ],
              ),
            ),
            child: _fadeAnimation != null
                ? FadeTransition(
              opacity: _fadeAnimation!,
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverAppBar(
                    expandedHeight: 120.0,
                    floating: true,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    centerTitle: true,
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                      title: Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: Text(
                          'Order Status',
                          style: GoogleFonts.playfairDisplay(
                            color: const Color(0xFFD4B88C), // Slightly darker text color
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                            shadows: [
                              Shadow(
                                blurRadius: 8.0,
                                color: Colors.black.withOpacity(0.3), // Darker shadow
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF1A1212), // Darker top gradient
                              Color(0xFF2E1F1F), // Darker bottom gradient
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                body: orders.isEmpty
                    ? Center(
                  child: Text(
                    'You have no orders yet.',
                    style: GoogleFonts.lora(
                      fontSize: 20,
                      color: const Color(0xFFD4B88C), // Darker text color
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
                    : Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8DAB2).withOpacity(0.8), // Darker background
                    borderRadius: BorderRadius.circular(12),
                    border: const Border(
                      top: BorderSide(color: Color(0xFFD4B88C), width: 1.5), // Darker border
                      bottom: BorderSide(color: Color(0xFFD4B88C), width: 1.5),
                    ),
                  ),
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    physics: const BouncingScrollPhysics(),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 16,
                      color: Color(0xFF1A1212), // Darker divider
                    ),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return FadeTransition(
                        opacity: _fadeAnimation!,
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(
                              color: Color(0xFFD4B88C), // Darker border
                              width: 1.5,
                            ),
                          ),
                          color: const Color(0xFF1E1C11).withOpacity(0.8), // Darker card background
                          elevation: 4,
                          shadowColor: Colors.black.withOpacity(0.3), // Darker shadow
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: OrderTile(
                              order: order,
                              isAdmin: false,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            )
                : const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD4B88C), // Darker loading indicator
              ),
            ),
          ),
        ),
      ),
    );
  }
}


