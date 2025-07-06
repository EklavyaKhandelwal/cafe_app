import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/order_service.dart';
import '../../models/order.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> with SingleTickerProviderStateMixin {
  late Future<List<Order>> _ordersFuture;
  String _selectedFilter = 'All Time';
  final List<String> _filters = ['Today', 'This Week', 'All Time'];
  late AnimationController _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  void _loadOrders() {
    _ordersFuture = context.read<OrderService>().fetchAllOrders();
  }

  Future<void> _refresh() async {
    _loadOrders();
    _animationController.reset();
    _animationController.forward();
    setState(() {});
    await _ordersFuture;
  }

  List<Order> _filterOrders(List<Order> orders) {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Today':
        return orders
            .where((o) =>
        o.timestamp != null &&
            o.timestamp!.year == now.year &&
            o.timestamp!.month == now.month &&
            o.timestamp!.day == now.day)
            .toList();
      case 'This Week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return orders
            .where((o) =>
        o.timestamp != null &&
            o.timestamp!.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
            o.timestamp!.isBefore(weekEnd.add(const Duration(days: 1))))
            .toList();
      case 'All Time':
      default:
        return orders;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E1F1F), // Deeper espresso brown
              Color(0xFF4A3726), // Richer mocha
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
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Sales Report',
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
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: const Color(0xFFFDF6E3),
                        value: _selectedFilter,
                        icon: const Icon(
                          Icons.filter_list,
                          color: Color(0xFFF5E6CC),
                        ),
                        items: _filters
                            .map((filter) => DropdownMenuItem(
                          value: filter,
                          child: Text(
                            filter,
                            style: GoogleFonts.lora(
                              color: const Color(0xFF3A2A2A),
                              fontSize: 14,
                            ),
                          ),
                        ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedFilter = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
            body: RefreshIndicator(
              onRefresh: _refresh,
              color: const Color(0xFFE2B570),
              backgroundColor: const Color(0xFF2E1F1F),
              child: FutureBuilder<List<Order>>(
                future: _ordersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE2B570),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading sales data: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lora(
                          color: const Color(0xFF914747),
                          fontSize: 20,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    );
                  }

                  List<Order> orders = snapshot.data ?? [];
                  orders = _filterOrders(orders);

                  if (orders.isEmpty) {
                    return Center(
                      child: Text(
                        'No orders found for "$_selectedFilter".',
                        style: GoogleFonts.lora(
                          color: const Color(0xFFF5E6CC),
                          fontSize: 20,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    );
                  }

                  final totalRevenue =
                  orders.fold<double>(0.0, (sum, order) => sum + order.total);

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SummaryCard(
                            label: 'Total Orders',
                            value: '${orders.length}',
                            icon: Icons.receipt_long,
                            color: const Color(0xFFE2B570), // Refined gold
                          ),
                          _SummaryCard(
                            label: 'Total Revenue',
                            value: '₹${totalRevenue.toStringAsFixed(2)}',
                            icon: Icons.attach_money,
                            color: const Color(0xFF7D8B6A), // Sage green
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ...orders.map(
                            (order) => FadeTransition(
                          opacity: _fadeAnimation!,
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(
                                color: Color(0xFFE2B570),
                                width: 1.5,
                              ),
                            ),
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            color: const Color(0xFFFDF6E3).withOpacity(0.9),
                            shadowColor: Colors.black.withOpacity(0.2),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFE2B570).withOpacity(0.2),
                                child: Text(
                                  order.id.toString(),
                                  style: GoogleFonts.lora(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF3A2A2A),
                                  ),
                                ),
                              ),
                              title: Text(
                                'Order #${order.id}',
                                style: GoogleFonts.lora(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: const Color(0xFF3A2A2A),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Customer: ${order.customerName ?? 'Unknown'}',
                                    style: GoogleFonts.lora(
                                      color: const Color(0xFF3A2A2A),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Date: ${order.timestamp?.toLocal().toString().split('.')[0] ?? 'N/A'}',
                                    style: GoogleFonts.lora(
                                      fontSize: 12,
                                      color: const Color(0xFF3A2A2A),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                '₹${order.total.toStringAsFixed(2)}',
                                style: GoogleFonts.lora(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: const Color(0xFF7D8B6A),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                    ],
                  );
                },
              ),
            ),
          ),
        )
            : const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFE2B570),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.4),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.lora(
                      color: color.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.lora(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}