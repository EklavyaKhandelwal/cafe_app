import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teatimestories/src/config/supabase.dart';
import 'package:teatimestories/src/screens/customer/login_screen.dart';
import 'package:teatimestories/src/screens/customer/orderstatusscreen.dart';
import 'package:teatimestories/src/services/auth_service.dart';
import '../../services/menu_service.dart';
import '../../models/menu_item.dart';
import '../../widgets/cart_provider.dart';
import '../../widgets/menu_card.dart';
import 'cart_screen.dart';
import 'package:animations/animations.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  late Future<List<MenuItem>> _menuFuture;
  TabController? _tabController;
  List<String> _categories = ['All'];
  List<MenuItem> _allItems = [];
  List<MenuItem> _filteredItems = [];
  String _searchQuery = '';
  bool _isInit = false;
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _menuFuture = _loadMenu();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _menuFuture.then((items) {
        final categorySet = <String>{'All'};
        for (var item in items) {
          if (item.category.isNotEmpty) {
            categorySet.add(item.category);
          }
        }
        setState(() {
          _categories = categorySet.toList();
          _tabController?.dispose();
          _tabController = TabController(length: _categories.length, vsync: this);
          _tabController!.addListener(_filterItems);
          _allItems = items;
          _filteredItems = items;
        });
      });
      _isInit = true;
    }
  }

  Future<List<MenuItem>> _loadMenu() async {
    try {
      final items = await Provider.of<MenuService>(context, listen: false).fetchMenu();
      return items;
    } catch (e) {
      throw Exception('Failed to load menu: $e');
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterItems();
    });
  }

  void _filterItems() {
    if (_tabController == null || _tabController!.indexIsChanging) return;
    final selectedCategory = _categories[_tabController!.index];
    setState(() {
      _filteredItems = _allItems.where((item) {
        final matchesCategory = selectedCategory == 'All' || item.category == selectedCategory;
        final matchesSearch = item.name.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  Future<void> _refreshMenu() async {
    setState(() {
      _menuFuture = _loadMenu();
    });
  }

  void _goToAllCategory() {
    if (_tabController != null && _tabController!.index != 0) {
      setState(() {
        _tabController!.index = 0;
        _filteredItems = _allItems.where((item) {
          final matchesSearch = item.name.toLowerCase().contains(_searchQuery.toLowerCase());
          return matchesSearch;
        }).toList();
        _selectedIndex = 0;
      });
    }
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const ProfileScreen(),
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

  @override
  void dispose() {
    _tabController?.removeListener(_filterItems);
    _tabController?.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 100.0,
      floating: true,
      pinned: true,
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Center( // This ensures full horizontal centering
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.restaurant_menu,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(height: 1),
              Text(
                'Café Menu',
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  shadows: [
                    Shadow(
                      blurRadius: 6.0,
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        background: Container(
          color: Color(0xFF2E1F1F),
        ),
      ),
      elevation: 2,
      backgroundColor: Color(0xFF2E1F1F),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list, color: Colors.white),
          onPressed: () {
            // Add filter options dialog if needed
          },
        ),
      ],
    );

  }

// Continue with your original build and widget structure..


Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search for dishes...',
            prefixIcon: const Icon(Icons.search, color: Color(0xFFE2B570)),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear, color: Color(0xFFE2B570)),
              onPressed: () {
                _searchController.clear();
                _filterItems();
              },
            )
                : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.9),
            hintStyle: GoogleFonts.lato(
              color: const Color(0xFF3A2A2A).withOpacity(0.5),
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2B570), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          style: GoogleFonts.lato(color: const Color(0xFF3A2A2A), fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    if (_categories.length <= 1) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicator: BoxDecoration(
            color: const Color(0xFFE2B570),
            borderRadius: BorderRadius.circular(16),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFFF5E6CC).withOpacity(0.7),
          padding: const EdgeInsets.symmetric(vertical: 4),
          labelStyle: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: _categories
              .map(
                (c) => Tab(
              child: Text(c),
            ),
          )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.65,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final item = _filteredItems[index];
            return FadeTransition(
              opacity: _fadeAnimation!,
              child: GestureDetector(
                onTap: () {
                  // Optionally navigate to item details
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFFFDF6E3).withOpacity(0.9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: MenuCard(
                    key: ValueKey(item.id),
                    menuItem: item,
                    onAddToCart: () {
                      Provider.of<CartProvider>(context, listen: false).addToCart(item);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${item.name} added to cart!',
                            style: GoogleFonts.lato(color: const Color(0xFFF5E6CC)),
                          ),
                          backgroundColor: const Color(0xFF2E1F1F),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          childCount: _filteredItems.length,
        ),
      ),
    );
  }

  Widget _buildCartIconWithBadge() {
    final cartCount = context.watch<CartProvider>().totalItems;
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(Icons.shopping_cart_outlined, size: 28, color: Color(
            0xFF3A2B04)),
        if (cartCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE2B570),
              ),
              child: Text(
                '$cartCount',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  color: const Color(0xFF2E1F1F),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 0) {
            _goToAllCategory();
          } else if (index == 1) {
            final customerId = SupabaseConfig.client.auth.currentUser?.id;
            if (customerId != null) {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      OrderStatusScreen(customerId: customerId),
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
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Please log in to view order status.",
                    style: GoogleFonts.lato(color: const Color(0xFFF5E6CC)),
                  ),
                  backgroundColor: const Color(0xFF2E1F1F),
                  behavior: SnackBarBehavior.floating,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }
          } else if (index == 2) {
            _navigateToProfile();
          }
        },
        backgroundColor: const Color(0xFFFDF6E3),
        selectedItemColor: const Color(0xFFE2B570),
        unselectedItemColor: const Color(0xFF3A2A2A).withOpacity(0.6),
        selectedLabelStyle: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w500),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 4,
        items: [
          BottomNavigationBarItem(
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(_selectedIndex == 0 ? 6 : 0),
              child: const Icon(Icons.home_rounded, size: 24),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(_selectedIndex == 1 ? 6 : 0),
              child: const Icon(Icons.receipt_long_rounded, size: 24),
            ),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(_selectedIndex == 2 ? 6 : 0),
              child: const Icon(Icons.account_circle_rounded, size: 24),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF2E1F1F),
          ),
          child: FutureBuilder<List<MenuItem>>(
            future: _menuFuture,
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error loading menu',
                        style: GoogleFonts.lato(
                          color: const Color(0xFFF5E6CC),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshMenu,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE2B570),
                          foregroundColor: const Color(0xFF2E1F1F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return FadeTransition(
                opacity: _fadeAnimation!,
                child: CustomScrollView(
                  slivers: [
                    _buildAppBar(),
                    _buildSearchBar(),
                    _buildCategoryTabs(),
                    _buildGrid(),
                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const CartScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SharedAxisTransition(
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  transitionType: SharedAxisTransitionType.scaled,
                  child: child,
                );
              },
            ),
          );
        },
        backgroundColor: const Color(0xFFE2B570),
        elevation: 4,
        child: _buildCartIconWithBadge(),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final AuthService authService = AuthService();
  String? userName;
  String? userEmail;
  String? userPhone;
  bool _isLoading = true;
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
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await authService.getUserFromPrefs();
    setState(() {
      userName = user?.name ?? 'Guest';
      userPhone = user?.phone ?? 'Not provided';
      userEmail = user?.email ?? 'Not provided';
      _isLoading = false;
    });
  }

  void _logout(BuildContext context) async {
    await authService.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CustomerLoginScreen()),
          (route) => false,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          child: _fadeAnimation != null
              ? FadeTransition(
            opacity: _fadeAnimation!,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  expandedHeight: 100.0,
                  floating: true,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'Profile',
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
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFFF5E6CC)),
                      onPressed: () {
                        // Navigate to edit profile screen
                      },
                    ),
                  ],
                ),
              ],
              body: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _isLoading
                      ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFE2B570),
                    ),
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeTransition(
                        opacity: _fadeAnimation!,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF6E3).withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2B570), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: const Color(0xFFE2B570).withOpacity(0.2),
                                child: const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Color(0xFFE2B570),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                userName ?? 'Guest',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF3A2A2A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Customer Account',
                                style: GoogleFonts.lora(
                                  color: const Color(0xFF3A2A2A).withOpacity(0.7),
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      FadeTransition(
                        opacity: _fadeAnimation!,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF6E3).withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2B570), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Account Details',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF3A2A2A),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                leading: const Icon(Icons.email, color: Color(0xFFE2B570)),
                                title: Text(
                                  userEmail ?? 'Not provided',
                                  style: GoogleFonts.lora(color: const Color(0xFF3A2A2A)),
                                ),
                              ),
                              ListTile(
                                leading: const Icon(Icons.phone, color: Color(0xFFE2B570)),
                                title: Text(
                                  userPhone ?? 'Not provided',
                                  style: GoogleFonts.lora(color: const Color(0xFF3A2A2A)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      FadeTransition(
                        opacity: _fadeAnimation!,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF6E3).withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2B570), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.settings, color: Color(0xFFE2B570)),
                                title: Text(
                                  'Settings',
                                  style: GoogleFonts.lora(color: const Color(0xFF3A2A2A)),
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios,
                                    size: 16, color: Color(0xFFE2B570)),
                                onTap: () {
                                  // Navigate to settings screen
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.history, color: Color(0xFFE2B570)),
                                title: Text(
                                  'Order History',
                                  style: GoogleFonts.lora(color: const Color(0xFF3A2A2A)),
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios,
                                    size: 16, color: Color(0xFFE2B570)),
                                onTap: () {
                                  final customerId = SupabaseConfig.client.auth.currentUser?.id;
                                  if (customerId != null) {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder:
                                            (context, animation, secondaryAnimation) =>
                                            OrderStatusScreen(customerId: customerId),
                                        transitionsBuilder:
                                            (context, animation, secondaryAnimation, child) {
                                          return SharedAxisTransition(
                                            animation: animation,
                                            secondaryAnimation: secondaryAnimation,
                                            transitionType: SharedAxisTransitionType.horizontal,
                                            child: child,
                                          );
                                        },
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Please log in to view order history.',
                                          style: GoogleFonts.lora(color: const Color(0xFFF5E6CC)),
                                        ),
                                        backgroundColor: const Color(0xFF2E1F1F),
                                        behavior: SnackBarBehavior.floating,
                                        elevation: 4,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      FadeTransition(
                        opacity: _fadeAnimation!,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF2E1F1F),
                                Color(0xFF4A3726),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: TextButton.icon(
                            onPressed: () => _logout(context),
                            icon: const Icon(Icons.logout, color: Color(0xFFF5E6CC)),
                            label: Text(
                              'Logout',
                              style: GoogleFonts.playfairDisplay(
                                color: const Color(0xFFF5E6CC),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              alignment: Alignment.centerLeft,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
      ),
    );
  }
}