import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_widgets.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  String? _avatarPath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() {
        _avatarPath = image.path;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      avatarPath: _avatarPath,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Profile updated!' : auth.error ?? 'Failed'),
          backgroundColor: success ? AppTheme.success : AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryDark, AppTheme.primaryDeep],
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Avatar
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.primaryBlue,
                        backgroundImage: _avatarPath != null
                            ? FileImage(File(_avatarPath!))
                            : (user?.avatarUrl != null && user!.avatarUrl.isNotEmpty
                                ? NetworkImage(user.avatarUrl)
                                : null),
                        child: (_avatarPath == null &&
                                (user?.avatarUrl == null || user!.avatarUrl.isEmpty))
                            ? Text(
                                (user?.name ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentCyan,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppTheme.primaryDark, width: 3),
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Tap to change photo',
                  style: TextStyle(color: AppTheme.textHint, fontSize: 13),
                ),
              ),
              const SizedBox(height: 32),

              GlassTextField(
                controller: _nameCtrl,
                labelText: 'Name',
                hintText: 'Enter your name',
                prefixIcon: Icons.person_outline_rounded,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              GlassTextField(
                controller: _phoneCtrl,
                labelText: 'Phone',
                hintText: 'Enter your phone number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),

              GlassButton(
                text: 'Save Changes',
                isLoading: _isLoading,
                onPressed: _save,
                icon: Icons.check_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
