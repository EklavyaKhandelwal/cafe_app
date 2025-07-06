import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:teatimestories/src/screens/customer/splashscreen.dart';
import 'package:teatimestories/src/screens/customer/login_screen.dart';
import 'package:teatimestories/src/screens/admin/admin_login_screen.dart';
import 'package:teatimestories/src/services/auth_service.dart';
import 'package:teatimestories/src/services/menu_service.dart';
import 'package:teatimestories/src/services/order_service.dart';
import 'package:teatimestories/src/widgets/cart_provider.dart';
import 'package:teatimestories/src/models/user.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teatimestories/src/screens/customer/cart_screen.dart';
import 'package:teatimestories/src/screens/customer/thank_you_screen.dart';

// Placeholder for MenuScreen (replace with your actual menu screen)
import 'package:teatimestories/src/screens/customer/menu_screen.dart'; // Adjust import as needed

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set brown theme for status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFF2E1F1F),
    statusBarIconBrightness: Brightness.light,
  ));

  await supabase.Supabase.initialize(
    url: 'https://yydwanttxuufqpiihqxq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl5ZHdhbnR0eHV1ZnFwaWlocXhxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgxNDcxODksImV4cCI6MjA2MzcyMzE4OX0.WphUk_TZDYBZmtflBpUcYQrFn4DsMprHdZm2qyEuCfY',
  );

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => MenuService()),
        ChangeNotifierProvider(create: (_) => OrderService()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        StreamProvider<User?>.value(
          initialData: null,
          value: supabase.Supabase.instance.client.auth.onAuthStateChange.map(
                (event) {
              final sessionUser = event.session?.user;
              if (sessionUser == null) return null;

              final metadata = sessionUser.userMetadata ?? {};
              return User(
                id: sessionUser.id,
                name: metadata['name'] ?? '',
                email: sessionUser.email ?? '',
                phone: metadata['phone'],
              );
            },
          ),
        ),
      ],
      child: const CafeOrderingApp(),
    ),
  );
}

class CafeOrderingApp extends StatelessWidget {
  const CafeOrderingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Café Ordering App',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF2E1F1F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E1F1F),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.loraTextTheme().apply(
          bodyColor: const Color(0xFFF5E6CC),
          displayColor: const Color(0xFFF5E6CC),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E1F1F),
          foregroundColor: Color(0xFFF5E6CC),
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const CustomerLoginScreen(),
        '/admin-login': (context) => const AdminLoginScreen(),
        '/home': (context) => const MenuScreen(), // Replace with your menu screen
        '/cart': (context) => const CartScreen(),
        '/thank-you': (context) => const ThankYouScreen(),
      },
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Role',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: 26,
            color: const Color(0xFFF5E6CC),
          ),
        ),
        backgroundColor: const Color(0xFF2E1F1F),
        elevation: 0,
      ),
      body: Container(
        color: const Color(0xFF3A2A2A),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                width: 380,
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF4A3726),
                      Color(0xFF2E1F1F),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Choose Your Role',
                      style: GoogleFonts.roboto(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF5E6CC),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildRoleButton(
                      context,
                      title: 'Login as Customer',
                      icon: Icons.person,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CustomerLoginScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildRoleButton(
                      context,
                      title: 'Login as Admin',
                      icon: Icons.admin_panel_settings,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminLoginScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(
      BuildContext context, {
        required String title,
        required IconData icon,
        required VoidCallback onPressed,
      }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
          ),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          backgroundColor: MaterialStateProperty.all(Colors.transparent),
          foregroundColor: MaterialStateProperty.all(Colors.transparent),
          overlayColor: MaterialStateProperty.all(
            const Color(0xFFD4A373).withOpacity(0.2),
          ),
          elevation: MaterialStateProperty.all(0),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF3B2F2F),
                Color(0xFF5C4033),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: const Color(0xFFF5E6CC)),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFF5E6CC),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
