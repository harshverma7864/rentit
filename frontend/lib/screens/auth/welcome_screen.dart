import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_widgets.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'phone_screen.dart';

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
              Color(0xFF2D1212),
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
                        color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
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
                        colors: [AppTheme.textPrimary, AppTheme.accentCyan],
                      ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
                const SizedBox(height: 8),
                const Text(
                  'Rent. Use. Return.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.accentCyan,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                  ),
                ).animate().fadeIn(delay: 450.ms),
                const SizedBox(height: 12),
                const Text(
                  'Rent anything you need,\nanytime, anywhere.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 600.ms),
                const Spacer(flex: 2),
                GlassButton(
                  text: 'Sign In',
                  icon: Icons.login_rounded,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3),
                const SizedBox(height: 14),
                GlassButton(
                  text: 'Create Account',
                  icon: Icons.person_add_rounded,
                  color: AppTheme.accentCyan,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    );
                  },
                ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.3),
                const SizedBox(height: 18),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PhoneScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone_rounded, size: 18, color: AppTheme.textSecondary),
                  label: const Text(
                    'Sign in with OTP',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ).animate().fadeIn(delay: 1000.ms),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
