import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_widgets.dart';
import '../../providers/auth_provider.dart';
import '../main_nav_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _codeSent = false;
  bool _isSending = false;
  bool _isVerifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isSending = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    try {
      await auth.sendOtp(widget.phoneNumber);
      if (mounted) {
        setState(() {
          _codeSent = true;
          _isSending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSending = false;
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) return;

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOtpAndLogin(_otpController.text);

    if (!mounted) return;

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
        (route) => false,
      );
    } else {
      setState(() {
        _error = auth.error ?? 'Verification failed';
        _isVerifying = false;
      });
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
            colors: [AppTheme.primaryDark, AppTheme.primaryDeep],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: AppTheme.textPrimary,
                ),
                const SizedBox(height: 32),
                Text(
                  'Verify\nPhone',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    height: 1.2,
                  ),
                ).animate().fadeIn().slideX(begin: -0.2),
                const SizedBox(height: 8),
                Text(
                  'Enter the 6-digit code sent to',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 4),
                Text(
                  widget.phoneNumber,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentCyan,
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 48),
                if (_isSending)
                  const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: AppTheme.accentCyan),
                        SizedBox(height: 16),
                        Text(
                          'Sending verification code...',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                else if (_codeSent) ...[
                  PinCodeTextField(
                    appContext: context,
                    length: 6,
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    animationType: AnimationType.fade,
                    textStyle: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(12),
                      fieldHeight: 56,
                      fieldWidth: 46,
                      activeFillColor: AppTheme.surfaceGlass,
                      inactiveFillColor: AppTheme.surfaceGlass,
                      selectedFillColor: AppTheme.surfaceGlass,
                      activeColor: AppTheme.accentCyan,
                      inactiveColor: Colors.white.withValues(alpha: 0.1),
                      selectedColor: AppTheme.primaryBlue,
                    ),
                    enableActiveFill: true,
                    onCompleted: (_) => _verifyOtp(),
                    onChanged: (_) {},
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                  const SizedBox(height: 32),
                  GlassButton(
                    text: 'Verify',
                    icon: Icons.verified_rounded,
                    isLoading: _isVerifying,
                    onPressed: _verifyOtp,
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: _isSending ? null : _sendOtp,
                      child: Text(
                        'Resend Code',
                        style: TextStyle(
                          color: AppTheme.accentCyan,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: AppTheme.error, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().shake(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
