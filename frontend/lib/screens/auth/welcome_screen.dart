import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_widgets.dart';
import 'register_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryDark,
              AppTheme.primaryDeep,
              Color(0xFF0D47A1),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                // Logo / Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryBlue,
                        AppTheme.accentCyan,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.5),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.handshake_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .scale(begin: const Offset(0.5, 0.5)),
                const SizedBox(height: 32),
                Text(
                  'RentPe',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [Colors.white, AppTheme.accentCyan],
                      ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
                const SizedBox(height: 8),
                Text(
                  'Rent. Flex. Repeat.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.accentCyan,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                  ),
                ).animate().fadeIn(delay: 450.ms),
                const SizedBox(height: 12),
                Text(
                  'Rent anything, from anyone,\nanywhere near you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 600.ms),
                const Spacer(flex: 2),
                GlassButton(
                  text: 'Get Started',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    );
                  },
                ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.3),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(color: AppTheme.textSecondary),
                      children: [
                        TextSpan(
                          text: 'Sign In',
                          style: TextStyle(
                            color: AppTheme.accentCyan,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 1100.ms),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
