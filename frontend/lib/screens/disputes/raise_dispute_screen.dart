import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_widgets.dart';
import '../../providers/dispute_provider.dart';

class RaiseDisputeScreen extends StatefulWidget {
  final String bookingId;

  const RaiseDisputeScreen({super.key, required this.bookingId});

  @override
  State<RaiseDisputeScreen> createState() => _RaiseDisputeScreenState();
}

class _RaiseDisputeScreenState extends State<RaiseDisputeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<String> _imagePaths = [];
  final _picker = ImagePicker();

  final List<String> _reasonOptions = [
    'Item not as described',
    'Item damaged',
    'Item not received',
    'Seller unresponsive',
    'Payment issue',
    'Other',
  ];
  String? _selectedReason;

  @override
  void dispose() {
    _reasonController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      setState(() {
        for (final img in images) {
          if (_imagePaths.length < 5) _imagePaths.add(img.path);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final reason = _selectedReason ?? _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter a reason')),
      );
      return;
    }

    final provider = context.read<DisputeProvider>();
    final success = await provider.createDispute(
      bookingId: widget.bookingId,
      reason: reason,
      description: _descriptionController.text.trim(),
      imagePaths: _imagePaths,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dispute raised successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to raise dispute'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.primaryDark, AppTheme.primaryDeep],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Raise Dispute')),
        body: Consumer<DisputeProvider>(
          builder: (context, provider, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What went wrong?',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select a reason for your dispute. Our team will review it manually.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 20),

                    // Reason chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _reasonOptions.map((r) {
                        final isSelected = _selectedReason == r;
                        return ChoiceChip(
                          label: Text(r),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedReason = r),
                          selectedColor: AppTheme.primaryBlue,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                          backgroundColor: AppTheme.surfaceGlass,
                          side: BorderSide(
                            color: isSelected ? AppTheme.primaryBlue : AppTheme.surfaceGlassLight,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      style: TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Explain the issue in detail...',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Description is required';
                        if (v.trim().length < 10) return 'Please provide more details';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Images
                    Text(
                      'Evidence (optional)',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ..._imagePaths.map((path) => Container(
                                width: 100,
                                height: 100,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: FileImage(File(path)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: Align(
                                  alignment: Alignment.topRight,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _imagePaths.remove(path)),
                                    child: Container(
                                      margin: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.error,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              )),
                          if (_imagePaths.length < 5)
                            GestureDetector(
                              onTap: _pickImages,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceGlass,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.surfaceGlassLight),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate, color: AppTheme.textSecondary),
                                    SizedBox(height: 4),
                                    Text('Add', style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Warning
                    GlassCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppTheme.warning, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'False disputes may result in account restrictions. Please only raise genuine issues.',
                              style: TextStyle(
                                color: AppTheme.warning.withValues(alpha: 0.9),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: provider.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: provider.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Submit Dispute',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
