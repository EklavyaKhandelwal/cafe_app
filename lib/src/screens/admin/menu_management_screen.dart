import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/menu_service.dart';
import '../../models/menu_item.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String _selectedCategory = 'Beverages';
  final List<String> _categories = ['Beverages', 'Snacks', 'Desserts', 'Main Course', 'Other'];
  bool _isProcessing = false;
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

  Future<void> _addMenuItem() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final priceText = _priceController.text.trim();
    final imageUrl = _imageUrlController.text.trim();

    if (name.isEmpty || priceText.isEmpty || imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(_buildSnackBar('Please fill in all required fields'));
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(_buildSnackBar('Enter a valid positive price'));
      return;
    }

    setState(() => _isProcessing = true);

    final menuItem = MenuItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      price: price,
      imageUrl: imageUrl,
      category: _selectedCategory,
    );

    try {
      await Provider.of<MenuService>(context, listen: false).addMenuItem(menuItem);
      _clearFields();
      ScaffoldMessenger.of(context).showSnackBar(_buildSnackBar('Menu item added'));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(_buildSnackBar('Failed to add menu item: $e'));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _clearFields() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _imageUrlController.clear();
    setState(() => _selectedCategory = 'Beverages');
  }

  Future<void> _deleteMenuItem(String id) async {
    setState(() => _isProcessing = true);
    try {
      await Provider.of<MenuService>(context, listen: false).deleteMenuItem(id);
      ScaffoldMessenger.of(context).showSnackBar(_buildSnackBar('Menu item deleted'));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(_buildSnackBar('Failed to delete menu item: $e'));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  SnackBar _buildSnackBar(String message) {
    return SnackBar(
      content: Text(
        message,
        style: GoogleFonts.lora(color: const Color(0xFFF5E6CC)),
      ),
      backgroundColor: const Color(0xFF2E1F1F),
      behavior: SnackBarBehavior.floating,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
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
                    'Menu Management',
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
            ],
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(
                        color: Color(0xFFE2B570), // Refined gold
                        width: 1.5,
                      ),
                    ),
                    color: const Color(0xFFFDF6E3).withOpacity(0.9), // Soft ivory
                    shadowColor: Colors.black.withOpacity(0.2),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Add New Menu Item',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF3A2A2A), // Darker espresso
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            _nameController,
                            'Item Name',
                            Icons.fastfood,
                            keyboardType: TextInputType.text,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            _descriptionController,
                            'Description',
                            Icons.description,
                            keyboardType: TextInputType.text,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            _priceController,
                            'Price (₹)',
                            Icons.currency_rupee,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            _imageUrlController,
                            'Image URL',
                            Icons.image,
                            keyboardType: TextInputType.text,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              labelStyle: GoogleFonts.lora(
                                color: const Color(0xFF3A2A2A),
                              ),
                              prefixIcon: const Icon(
                                Icons.category,
                                color: Color(0xFFE2B570),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2B570),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2B570),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFFDF6E3).withOpacity(0.5),
                            ),
                            style: GoogleFonts.lora(
                              color: const Color(0xFF3A2A2A),
                              fontSize: 16,
                            ),
                            dropdownColor: const Color(0xFFFDF6E3),
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xFF7D8B6A), // Sage green
                            ),
                            items: _categories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedCategory = value);
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(
                                Icons.add,
                                color: Color(0xFFF5E6CC),
                              ),
                              label: _isProcessing
                                  ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFF5E6CC),
                                ),
                              )
                                  : Text(
                                'Add Item',
                                style: GoogleFonts.lora(
                                  color: const Color(0xFFF5E6CC),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: _isProcessing ? null : _addMenuItem,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E1F1F),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Current Menu',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF5E6CC),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<MenuItem>>(
                    future: Provider.of<MenuService>(context).fetchMenu(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFE2B570),
                            ),
                          ),
                        );
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return _buildInfoText('Failed to load menu items.');
                      }
                      final items = snapshot.data ?? [];
                      if (items.isEmpty) {
                        return _buildInfoText('No menu items found.');
                      }
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF6E3).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: const Border(
                            top: BorderSide(color: Color(0xFFE2B570), width: 1.5),
                            bottom: BorderSide(color: Color(0xFFE2B570), width: 1.5),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 16,
                            color: Color(0xFF7D8B6A),
                          ),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return FadeTransition(
                              opacity: _fadeAnimation!,
                              child: ListTile(
                                tileColor: const Color(0xFFFDF6E3).withOpacity(0.9),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                    color: Color(0xFFE2B570),
                                    width: 1.5,
                                  ),
                                ),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item.imageUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.broken_image,
                                      size: 40,
                                      color: Color(0xFFE2B570),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  item.name,
                                  style: GoogleFonts.lora(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF3A2A2A),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '₹${item.price.toStringAsFixed(2)}',
                                      style: GoogleFonts.lora(
                                        color: const Color(0xFF3A2A2A),
                                      ),
                                    ),
                                    Text(
                                      'Category: ${item.category.isNotEmpty ? item.category : 'None'}',
                                      style: GoogleFonts.lora(
                                        color: const Color(0xFF3A2A2A),
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Color(0xFF914747),
                                  ),
                                  onPressed: _isProcessing ? null : () => _deleteMenuItem(item.id),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
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

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.lora(color: const Color(0xFF3A2A2A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.lora(
          color: const Color(0xFF3A2A2A),
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFFE2B570),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE2B570),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE2B570),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFFDF6E3).withOpacity(0.5),
      ),
    );
  }

  Widget _buildInfoText(String text) => Padding(
    padding: const EdgeInsets.all(32.0),
    child: Center(
      child: Text(
        text,
        style: GoogleFonts.lora(
          color: const Color(0xFFF5E6CC),
          fontSize: 20,
          fontStyle: FontStyle.italic,
        ),
      ),
    ),
  );

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
