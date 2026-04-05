import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_widgets.dart';
import '../../providers/item_provider.dart';

class CreateItemScreen extends StatefulWidget {
  const CreateItemScreen({super.key});

  @override
  State<CreateItemScreen> createState() => _CreateItemScreenState();
}

class _CreateItemScreenState extends State<CreateItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _pricePerDayCtrl = TextEditingController();
  final _pricePerHourCtrl = TextEditingController();
  final _pricePerWeekCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _rulesCtrl = TextEditingController();
  final _deliveryFeeCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  String _category = 'other';
  String _condition = 'good';
  bool _deliveryAvailable = false;
  int _maxRentalDays = 30;
  List<String> _imageBase64List = [];

  final List<Map<String, String>> _categories = [
    {'id': 'clothing', 'name': 'Clothing & Fashion', 'icon': '👔'},
    {'id': 'electronics', 'name': 'Electronics', 'icon': '📱'},
    {'id': 'vehicles', 'name': 'Vehicles', 'icon': '🚗'},
    {'id': 'furniture', 'name': 'Furniture', 'icon': '🪑'},
    {'id': 'sports', 'name': 'Sports & Outdoors', 'icon': '⚽'},
    {'id': 'tools', 'name': 'Tools & Equipment', 'icon': '🔧'},
    {'id': 'party', 'name': 'Party & Events', 'icon': '🎉'},
    {'id': 'books', 'name': 'Books & Media', 'icon': '📚'},
    {'id': 'music', 'name': 'Musical Instruments', 'icon': '🎸'},
    {'id': 'other', 'name': 'Other', 'icon': '📦'},
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _pricePerDayCtrl.dispose();
    _pricePerHourCtrl.dispose();
    _pricePerWeekCtrl.dispose();
    _depositCtrl.dispose();
    _rulesCtrl.dispose();
    _deliveryFeeCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );
    for (final img in images) {
      if (_imageBase64List.length >= 5) break;
      final bytes = await File(img.path).readAsBytes();
      setState(() {
        _imageBase64List.add('data:image/jpeg;base64,${base64Encode(bytes)}');
      });
    }
  }

  Future<void> _detectLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          _cityCtrl.text = p.locality ?? p.subAdministrativeArea ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'category': _category,
      'images': _imageBase64List,
      'pricePerDay': double.tryParse(_pricePerDayCtrl.text) ?? 0,
      'pricePerHour': double.tryParse(_pricePerHourCtrl.text) ?? 0,
      'pricePerWeek': double.tryParse(_pricePerWeekCtrl.text) ?? 0,
      'securityDeposit': double.tryParse(_depositCtrl.text) ?? 0,
      'condition': _condition,
      'rules': _rulesCtrl.text.trim(),
      'deliveryAvailable': _deliveryAvailable,
      'deliveryFee': double.tryParse(_deliveryFeeCtrl.text) ?? 0,
      'maxRentalDays': _maxRentalDays,
      'location': {
        'type': 'Point',
        'coordinates': [0, 0],
        'city': _cityCtrl.text.trim(),
      },
    };

    final success = await context.read<ItemProvider>().createItem(data);
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Item listed successfully!'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('List an Item'),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
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
              // Image upload section
              Text(
                'Photos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ).animate().fadeIn(delay: 50.ms),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._imageBase64List.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final imgData = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                base64Decode(imgData.split(',').last),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => setState(() =>
                                    _imageBase64List.removeAt(idx)),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (_imageBase64List.length < 5)
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceGlass,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.accentCyan.withValues(alpha: 0.4),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_rounded,
                                  color: AppTheme.accentCyan, size: 28),
                              const SizedBox(height: 4),
                              Text('Add',
                                  style: TextStyle(
                                      color: AppTheme.accentCyan,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ).animate().fadeIn(delay: 75.ms),
              const SizedBox(height: 16),

              // Title
              GlassTextField(
                controller: _titleCtrl,
                labelText: 'Item Title',
                hintText: 'e.g., 3-Piece Wedding Suit',
                prefixIcon: Icons.title_rounded,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 16),

              // Category dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceGlass,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.accentBlue.withValues(alpha: 0.2),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _category,
                    isExpanded: true,
                    dropdownColor: AppTheme.cardBg,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    icon: const Icon(Icons.expand_more_rounded,
                        color: AppTheme.accentCyan),
                    items: _categories
                        .map((c) => DropdownMenuItem(
                              value: c['id'],
                              child: Row(
                                children: [
                                  Text(c['icon']!,
                                      style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 12),
                                  Text(c['name']!),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),

              // Description
              GlassTextField(
                controller: _descCtrl,
                labelText: 'Description',
                hintText: 'Describe your item in detail...',
                prefixIcon: Icons.description_outlined,
                maxLines: 4,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 24),

              // Pricing section
              Text(
                'Pricing',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GlassTextField(
                      controller: _pricePerDayCtrl,
                      labelText: 'Per Day (₹)',
                      hintText: '0',
                      prefixIcon: Icons.currency_rupee_rounded,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassTextField(
                      controller: _depositCtrl,
                      labelText: 'Deposit (₹)',
                      hintText: '0',
                      prefixIcon: Icons.shield_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 450.ms),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GlassTextField(
                      controller: _pricePerHourCtrl,
                      labelText: 'Per Hour (₹)',
                      hintText: 'Optional',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassTextField(
                      controller: _pricePerWeekCtrl,
                      labelText: 'Per Week (₹)',
                      hintText: 'Optional',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 24),

              // Condition
              Text(
                'Condition',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ).animate().fadeIn(delay: 550.ms),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _ConditionChip('new', 'Brand New', _condition,
                      (v) => setState(() => _condition = v)),
                  _ConditionChip('like_new', 'Like New', _condition,
                      (v) => setState(() => _condition = v)),
                  _ConditionChip('good', 'Good', _condition,
                      (v) => setState(() => _condition = v)),
                  _ConditionChip('fair', 'Fair', _condition,
                      (v) => setState(() => _condition = v)),
                ],
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 24),

              // City
              GlassTextField(
                controller: _cityCtrl,
                labelText: 'City',
                hintText: 'e.g., Mumbai',
                prefixIcon: Icons.location_city_rounded,
              ).animate().fadeIn(delay: 650.ms),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _detectLocation,
                  icon: const Icon(Icons.my_location_rounded,
                      size: 16, color: AppTheme.accentCyan),
                  label: const Text('Use current location',
                      style: TextStyle(
                          color: AppTheme.accentCyan, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 8),

              // Delivery
              GlassCard(
                margin: EdgeInsets.zero,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_shipping_outlined,
                            color: AppTheme.accentCyan),
                        const SizedBox(width: 12),
                        const Text(
                          'Delivery Available',
                          style: TextStyle(color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    Switch(
                      value: _deliveryAvailable,
                      onChanged: (v) => setState(() => _deliveryAvailable = v),
                      activeColor: AppTheme.accentCyan,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 700.ms),

              if (_deliveryAvailable) ...[
                const SizedBox(height: 12),
                GlassTextField(
                  controller: _deliveryFeeCtrl,
                  labelText: 'Delivery Fee (₹)',
                  hintText: '0',
                  prefixIcon: Icons.currency_rupee_rounded,
                  keyboardType: TextInputType.number,
                ),
              ],
              const SizedBox(height: 16),

              // Rules
              GlassTextField(
                controller: _rulesCtrl,
                labelText: 'Rental Rules (Optional)',
                hintText: 'Any special rules or conditions...',
                prefixIcon: Icons.rule_outlined,
                maxLines: 3,
              ).animate().fadeIn(delay: 750.ms),
              const SizedBox(height: 32),

              // Submit
              Consumer<ItemProvider>(
                builder: (context, provider, _) => GlassButton(
                  text: 'List Item',
                  isLoading: provider.isLoading,
                  onPressed: _submit,
                  icon: Icons.add_circle_outline_rounded,
                ),
              ).animate().fadeIn(delay: 800.ms),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConditionChip extends StatelessWidget {
  final String value;
  final String label;
  final String selected;
  final ValueChanged<String> onTap;

  const _ConditionChip(this.value, this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withValues(alpha: 0.3)
              : AppTheme.surfaceGlass,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.accentCyan : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.accentCyan : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
