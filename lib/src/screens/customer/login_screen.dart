import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../admin/admin_login_screen.dart';
import 'menu_screen.dart';

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;
  late AnimationController _animationController;
  Animation<double>? _fadeAnimation; // Changed to nullable to avoid late initialization error

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
    _checkLoggedIn();
  }

  Future<void> _checkLoggedIn() async {
    final authService = AuthService();
    final user = await authService.getUserFromPrefs();

    if (user != null && mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MenuScreen()),
      );
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if ((_isLogin && (email.isEmpty || password.isEmpty)) ||
        (!_isLogin && (name.isEmpty || email.isEmpty || password.isEmpty))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in all required fields',
            style: GoogleFonts.lora(color: const Color(0xFFF5E6CC)),
          ),
          backgroundColor: const Color(0xFF3B2F2F),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = _isLogin
        ? await authService.signInCustomer(email, password)
        : await authService.signUpCustomer(name, email, password, phone);

    setState(() => _isLoading = false);

    if (user != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Welcome, ${user.name}!',
            style: GoogleFonts.lora(color: const Color(0xFFF5E6CC)),
          ),
          backgroundColor: const Color(0xFF3B2F2F),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MenuScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isLogin ? 'Login failed' : 'Registration failed',
            style: GoogleFonts.lora(color: const Color(0xFFF5E6CC)),
          ),
          backgroundColor: const Color(0xFF3B2F2F),
        ),
      );
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
              Color(0xFF3B2F2F), // Rich espresso brown
              Color(0xFF5C4033), // Warm mocha
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _fadeAnimation != null
                ? FadeTransition(
              opacity: _fadeAnimation!,
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                color: const Color(0xFFF5E6CC).withOpacity(0.95), // Semi-transparent cream
                child: Container(
                  padding: const EdgeInsets.all(32),
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/logo.jpg',
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Tea Time Stories',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3B2F2F),
                          shadows: [
                            Shadow(
                              blurRadius: 8.0,
                              color: Colors.black.withOpacity(0.2),
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _isLogin ? 'Customer Login' : 'Customer Sign Up',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3B2F2F),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (!_isLogin)
                        _buildTextField(_nameController, 'Your Name', Icons.person_outline, const Color(
                            0xFF070400)),
                      if (!_isLogin) const SizedBox(height: 16),
                      _buildTextField(_emailController, 'Email', Icons.email_outlined, const Color(
                          0xFF070501)),
                      const SizedBox(height: 16),
                      _buildTextField(_passwordController, 'Password', Icons.lock_outline, const Color(
                          0xFF0E0101), isPassword: true),
                      const SizedBox(height: 16),
                      if (!_isLogin)
                        _buildTextField(_phoneController, 'Phone Number', Icons.phone_outlined, const Color(
                            0xFF050200)),
                      const SizedBox(height: 32),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF3B2F2F),
                              Color(0xFF5C4033),
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
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            minimumSize: const Size(double.infinity, 56),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Color(0xFFF5E6CC),
                              strokeWidth: 2.5,
                            ),
                          )
                              : Text(
                            _isLogin ? 'Login' : 'Register',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFF5E6CC),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin ? 'New here? Register instead' : 'Already have an account? Login',
                          style: GoogleFonts.lora(
                            fontSize: 16,
                            color: const Color(0xFF020000),
                          ),
                        ),
                      ),
                      const Divider(color: Color(0xFF000000)),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminLoginScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.admin_panel_settings_outlined, color: Color(
                            0xFF000000)),
                        label: Text(
                          'Login as Admin',
                          style: GoogleFonts.lora(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF090400),
                          ),
                        ),
                      ),
                    ],
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
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, Color iconColor, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.lora(
          color: const Color(0xFF3B2F2F).withOpacity(0.7),
          fontSize: 16,
        ),
        prefixIcon: Icon(icon, color: iconColor),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
          icon: Icon(Icons.clear, color: iconColor),
          onPressed: () => setState(() => controller.clear()),
        )
            : null,
        filled: true,
        fillColor: const Color(0xFFF5E6CC).withOpacity(0.5),
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
          borderSide: const BorderSide(color: Color(0xFFD4A373), width: 2),
        ),
      ),
      style: GoogleFonts.lora(color: const Color(0xFF3B2F2F)),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}