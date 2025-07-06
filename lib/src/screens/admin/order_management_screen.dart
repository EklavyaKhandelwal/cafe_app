import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teatimestories/src/models/menu_item.dart';
import 'package:teatimestories/src/screens/admin/admin_login_screen.dart';
import 'package:teatimestories/src/services/menu_service.dart';
import '../../services/order_service.dart';
import '../../models/order.dart';
import 'menu_management_screen.dart';
import 'sales_report_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animations/animations.dart';

class OrderManagementScreen extends StatefulWidget {
  final bool isAdmin;

  const OrderManagementScreen({super.key, required this.isAdmin});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
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
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshOrders(BuildContext context) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _animationController.reset();
    _animationController.forward();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() => _selectedIndex = index);

    if (index == 1) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MenuManagementScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SharedAxisTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.horizontal,
              child: child,
            );
          },
        ),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const SalesReportScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SharedAxisTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.horizontal,
              child: child,
            );
          },
        ),
      );
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = const Color(0xFF4CAF50); // Vibrant green for completed
        break;
      case 'pending':
        color = const Color(0xFFFFC107); // Amber for pending
        break;
      case 'preparing':
        color = const Color(0xFF2196F3); // Bright blue for preparing
        break;
      case 'ready':
        color = const Color(0xFF00BCD4); // Cyan for ready
        break;
      case 'cancelled':
        color = const Color(0xFFF44336); // Strong red for cancelled
        break;
      default:
        color = const Color(0xFF757575); // Grey as a neutral default
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        status,
        style: GoogleFonts.lora(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  // UPDATED: Trim whitespace before validation and capitalization
  bool _isValidStatus(String? status) {
    const validStatuses = [
      'Pending',
      'Preparing',
      'Ready',
      'Completed',
      'Cancelled'
    ];
    // Trim and capitalize before checking
    return status != null && validStatuses.contains(_capitalize(status.trim()));
  }

  // UPDATED: Trim whitespace before capitalizing
  String _capitalize(String s) {
    if (s.isEmpty) return s;
    final trimmed = s.trim(); // Trim leading/trailing whitespace
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1).toLowerCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final orderService = Provider.of<OrderService>(context, listen: false);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3B2F2F), // Rich espresso brown
              Color(0xFF5C4033), // Warm mocha
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
                    'Manage Orders',
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
                          Color(0xFF3B2F2F),
                          Color(0xFF5C4033),
                        ],
                      ),
                    ),
                  ),
                ),
                elevation: 0,
                backgroundColor: Colors.transparent,
                centerTitle: true,
                actions: [
                  if (widget.isAdmin)
                    IconButton(
                      icon: const Icon(Icons.logout, color: Color(0xFFF5E6CC)),
                      tooltip: 'Logout',
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('admin_logged_in', false);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Logged out successfully',
                                style: GoogleFonts.lora(color: const Color(0xFFF5E6CC)),
                              ),
                              backgroundColor: const Color(0xFF3B2F2F),
                              behavior: SnackBarBehavior.floating,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );

                          await Future.delayed(const Duration(milliseconds: 800));

                          Navigator.of(context).popUntil((route) => route.isFirst);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                          );
                        }
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.filter_list, color: Color(0xFFF5E6CC), size: 28),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Filter not implemented yet',
                            style: GoogleFonts.lora(color: const Color(0xFFF5E6CC)),
                          ),
                          backgroundColor: const Color(0xFF3B2F2F),
                          behavior: SnackBarBehavior.floating,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                    tooltip: 'Filter Orders',
                  ),
                ],
              ),
            ],
            body: RefreshIndicator(
              onRefresh: () => _refreshOrders(context),
              color: const Color(0xFFD4A373),
              backgroundColor: const Color(0xFF3B2F2F),
              child: FutureBuilder<List<MenuItem>>(
                future: Provider.of<MenuService>(context, listen: false).fetchMenu(),
                builder: (context, menuSnapshot) {
                  if (menuSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD4A373),
                      ),
                    );
                  }

                  if (!menuSnapshot.hasData || menuSnapshot.hasError) {
                    return Center(
                      child: Text(
                        'Failed to load menu',
                        style: GoogleFonts.lora(
                          color: const Color(0xFFF5E6CC),
                          fontSize: 20,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    );
                  }

                  final menuItems = menuSnapshot.data!;

                  return StreamBuilder<List<Order>>(
                    stream: orderService.streamOrders(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFD4A373),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading orders',
                            style: GoogleFonts.lora(
                              color: const Color(0xFFF5E6CC),
                              fontSize: 20,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        );
                      }

                      final orders = snapshot.data ?? [];
                      if (orders.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.coffee,
                                color: Color(0xFFD4A373),
                                size: 70,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No orders found.',
                                style: GoogleFonts.playfairDisplay(
                                  color: const Color(0xFFF5E6CC),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        physics: const BouncingScrollPhysics(),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          final statusOptions = [
                            'Pending',
                            'Preparing',
                            'Ready',
                            'Completed',
                            'Cancelled'
                          ];
                          // `_isValidStatus` and `_capitalize` now handle trimming
                          final currentStatus = _isValidStatus(order.status)
                              ? _capitalize(order.status!)
                              : 'Pending';

                          return FadeTransition(
                            opacity: _fadeAnimation!,
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: const BorderSide(
                                  color: Color(0xFFD4A373),
                                  width: 1.5,
                                ),
                              ),
                              elevation: 5,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              color: const Color(0xFFF5E6CC).withOpacity(0.9),
                              shadowColor: Colors.black.withOpacity(0.2),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: const Color(0xFFD4A373).withOpacity(0.2),
                                      child: const Icon(
                                        Icons.fastfood,
                                        color: Color(0xFFD4A373),
                                        size: 30,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            constraints: const BoxConstraints(maxHeight: 100),
                                            child: Scrollbar(
                                              thumbVisibility: true,
                                              thickness: 4,
                                              radius: const Radius.circular(8),
                                              child: ListView.builder(
                                                padding: EdgeInsets.zero,
                                                shrinkWrap: true,
                                                itemCount: order.items.length,
                                                itemBuilder: (context, itemIndex) {
                                                  final itemName = order.items[itemIndex].getName(menuItems);
                                                  return Text(
                                                    '• $itemName',
                                                    style: GoogleFonts.lora(
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 16,
                                                      color: const Color(0xFF3B2F2F),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.person_outline,
                                                color: Color(0xFF3B2F2F),
                                                size: 18,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  order.customerName ?? 'Unknown',
                                                  style: GoogleFonts.lora(
                                                    color: const Color(0xFF3B2F2F),
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  softWrap: true,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.access_time_outlined,
                                                color: Color(0xFF3B2F2F),
                                                size: 18,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  order.timestamp.toLocal().toString().split('.')[0],
                                                  style: GoogleFonts.lora(
                                                    color: const Color(0xFF3B2F2F),
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  softWrap: true,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.table_restaurant_outlined,
                                                color: Color(0xFF3B2F2F),
                                                size: 18,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'Table: ${order.tableNumber}',
                                                  style: GoogleFonts.lora(
                                                    color: const Color(0xFF3B2F2F),
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  softWrap: true,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (currentStatus.toLowerCase() == 'preparing') ...[
                                            const SizedBox(height: 12),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: LinearProgressIndicator(
                                                value: 0.6,
                                                backgroundColor: const Color(0xFFD4A373).withOpacity(0.2),
                                                color: const Color(0xFFD4A373),
                                                minHeight: 6,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildStatusBadge(currentStatus),
                                        const SizedBox(height: 12),
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            minWidth: 80,
                                            maxWidth: 120,
                                          ),
                                          child: DropdownButton<String>(
                                            value: currentStatus,
                                            icon: const Icon(
                                              Icons.arrow_drop_down,
                                              color: Color(0xFF3B2F2F),
                                            ),
                                            iconSize: 26,
                                            elevation: 16,
                                            dropdownColor: const Color(0xFFF5E6CC),
                                            style: GoogleFonts.lora(
                                              color: const Color(0xFF3B2F2F),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            underline: Container(height: 0),
                                            onChanged: widget.isAdmin
                                                ? (String? newStatus) async {
                                              if (newStatus != null && newStatus != currentStatus) {
                                                // Ensure consistency when updating as well
                                                await orderService.updateOrderStatus(order.id, _capitalize(newStatus));
                                              }
                                            }
                                                : null,
                                            items: statusOptions.map((String status) {
                                              return DropdownMenuItem<String>(
                                                value: status, // This value must match 'currentStatus' exactly
                                                child: Text(
                                                  status,
                                                  style: const TextStyle(overflow: TextOverflow.ellipsis),
                                                ),
                                              );
                                            }).toList(),
                                            isDense: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        )
            : const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFD4A373),
          ),
        ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: const Color(0xFFD4A373),
          unselectedItemColor: const Color(0xFF3B2F2F),
          backgroundColor: const Color(0xFFF5E6CC).withOpacity(0.95),
          selectedLabelStyle: GoogleFonts.lora(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.lora(fontSize: 12),
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book),
              label: 'Menu',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Sales',
            ),
          ],
        ),
      ),
    );
  }
}