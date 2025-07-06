import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teatimestories/main.dart';
import '../../services/auth_service.dart';
import 'menu_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();

    Timer(const Duration(seconds: 4), () async {
      final authService = AuthService();
      final user = await authService.getUserFromPrefs();

      if (!mounted) return;

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MenuScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomPaint(
                    painter: CoffeeCupPainter(),
                    size: const Size(200, 200),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Tea Time Stories',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF5E6CC), // Cream text
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'A Place for Conversation & Shared Moments',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lora(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFFD4A373), // Gold accent
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CoffeeCupPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cupPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        colors: [Color(0xFFF5E6CC), Color(0xFFD4A373)], // Cream to gold gradient
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final handlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFFD4A373) // Gold handle
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    final steamPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0x80FFFFFF) // Semi-transparent white steam
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

    // Draw shadow
    final shadowPath = Path()
      ..moveTo(size.width * 0.28, size.height * 0.82)
      ..lineTo(size.width * 0.72, size.height * 0.82)
      ..lineTo(size.width * 0.62, size.height * 0.28)
      ..lineTo(size.width * 0.38, size.height * 0.28)
      ..close();
    canvas.drawPath(shadowPath.shift(const Offset(5, 5)), shadowPaint);

    // Draw cup
    final cupPath = Path()
      ..moveTo(size.width * 0.3, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.2, size.height * 0.5, size.width * 0.3, size.height * 0.2)
      ..lineTo(size.width * 0.7, size.height * 0.2)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.5, size.width * 0.7, size.height * 0.8)
      ..close();
    canvas.drawPath(cupPath, cupPaint);

    // Draw handle
    final handlePath = Path()
      ..moveTo(size.width * 0.7, size.height * 0.35)
      ..quadraticBezierTo(
        size.width * 0.85, size.height * 0.5,
        size.width * 0.7, size.height * 0.65,
      );
    canvas.drawPath(handlePath, handlePaint);

    // Draw saucer
    final saucerRect = Rect.fromLTWH(
      size.width * 0.2,
      size.height * 0.8,
      size.width * 0.6,
      size.height * 0.12,
    );
    canvas.drawOval(saucerRect, cupPaint);

    // Draw steam with animation effect
    final steamPath1 = Path()
      ..moveTo(size.width * 0.45, size.height * 0.2)
      ..quadraticBezierTo(
        size.width * 0.4, size.height * 0.1,
        size.width * 0.45, size.height * 0.05,
      );
    canvas.drawPath(steamPath1, steamPaint);

    final steamPath2 = Path()
      ..moveTo(size.width * 0.55, size.height * 0.2)
      ..quadraticBezierTo(
        size.width * 0.6, size.height * 0.1,
        size.width * 0.55, size.height * 0.05,
      );
    canvas.drawPath(steamPath2, steamPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}