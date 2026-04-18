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
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../models/item_model.dart';

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
  String _subcategory = '';
  String _condition = 'good';
  int _maxRentalDays = 30;
  int _quantity = 1;
  List<String> _imagePaths = [];

  // Delivery options
  bool _selfPickup = true;
  bool _sellerDelivery = false;
  bool _inAppDelivery = false;

  // Dynamic spec values (populated from category schema)
  final Map<String, dynamic> _specValues = {};
  final Map<String, TextEditingController> _specTextControllers = {};

  // Address
  AddressModel? _selectedAddress;
  double? _lat, _lng;

  @override
  void initState() {
    super.initState();
    // Fetch category schemas
    context.read<ItemProvider>().fetchCategorySpecs();
  }

  CategorySpec? get _currentCategorySpec =>
      context.read<ItemProvider>().specForCategory(_category);

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
    for (final c in _specTextControllers.values) {
      c.dispose();
    }
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
      if (_imagePaths.length >= 5) break;
      setState(() {
        _imagePaths.add(img.path);
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

    final deliveryOpts = <String>[];
    if (_selfPickup) deliveryOpts.add('self_pickup');
    if (_sellerDelivery) deliveryOpts.add('seller_delivery');
    if (_inAppDelivery) deliveryOpts.add('in_app_delivery');

    // Build specs from dynamic fields
    final spec = _currentCategorySpec;
    final specs = <String, dynamic>{};
    if (spec != null) {
      for (final field in spec.fields) {
        if (field.type == 'text' || field.type == 'number') {
          final ctrl = _specTextControllers[field.key];
          if (ctrl != null && ctrl.text.trim().isNotEmpty) {
            specs[field.key] = field.type == 'number'
                ? num.tryParse(ctrl.text.trim()) ?? ctrl.text.trim()
                : ctrl.text.trim();
          }
        } else {
          final val = _specValues[field.key];
          if (val != null && val.toString().isNotEmpty) {
            specs[field.key] = val;
          }
        }
      }
    }

    // Determine effective category (subcategory for categories that have them)
    final hasSubcats = spec != null && spec.subcategories.isNotEmpty;
    final effectiveCategory = hasSubcats && _subcategory.isNotEmpty ? _subcategory : _category;

    final data = {
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'category': effectiveCategory,
      'pricePerDay': double.tryParse(_pricePerDayCtrl.text) ?? 0,
      'pricePerHour': double.tryParse(_pricePerHourCtrl.text) ?? 0,
      'pricePerWeek': double.tryParse(_pricePerWeekCtrl.text) ?? 0,
      'securityDeposit': double.tryParse(_depositCtrl.text) ?? 0,
      'condition': _condition,
      'rules': _rulesCtrl.text.trim(),
      'deliveryAvailable': _sellerDelivery || _inAppDelivery,
      'deliveryFee': double.tryParse(_deliveryFeeCtrl.text) ?? 0,
      'deliveryOptions': deliveryOpts,
      'maxRentalDays': _maxRentalDays,
      'quantity': _quantity,
      'specs': specs,
      'location': {
        'type': 'Point',
        'coordinates': [_lng ?? _selectedAddress?.location?.longitude ?? 0, _lat ?? _selectedAddress?.location?.latitude ?? 0],
        'city': _cityCtrl.text.trim(),
        'address': _selectedAddress?.addressLine1 ?? '',
        'addressLine1': _selectedAddress?.addressLine1 ?? '',
        'addressLine2': _selectedAddress?.addressLine2 ?? '',
        'street': _selectedAddress?.street ?? '',
        'state': _selectedAddress?.state ?? '',
        'pincode': _selectedAddress?.pincode ?? '',
        'landmark': _selectedAddress?.landmark ?? '',
      },
    };

    final success = await context.read<ItemProvider>().createItem(data, imagePaths: _imagePaths);
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

  /// Dynamically build a form widget for a single spec field.
  Widget _buildSpecField(SpecField field) {
    switch (field.type) {
      case 'select':
        final selected = _specValues[field.key]?.toString() ?? '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.label,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: field.options.map((opt) {
                final isSelected = selected == opt;
                return ChoiceChip(
                  label: Text(opt.isNotEmpty
                      ? opt[0].toUpperCase() + opt.substring(1)
                      : opt),
                  selected: isSelected,
                  onSelected: (_) =>
                      setState(() => _specValues[field.key] = opt),
                  selectedColor: AppTheme.primaryBlue,
                  labelStyle: TextStyle(
                      color:
                          isSelected ? Colors.white : AppTheme.textPrimary),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        );
      case 'boolean':
        final val = _specValues[field.key] == true;
        return Column(
          children: [
            SwitchListTile(
              title: Text(field.label,
                  style: const TextStyle(color: AppTheme.textPrimary)),
              value: val,
              onChanged: (v) =>
                  setState(() => _specValues[field.key] = v),
              activeTrackColor:
                  AppTheme.primaryBlue.withValues(alpha: 0.5),
              activeThumbColor: AppTheme.primaryBlue,
            ),
            const SizedBox(height: 12),
          ],
        );
      case 'number':
      case 'text':
      default:
        _specTextControllers.putIfAbsent(
            field.key, () => TextEditingController());
        return Column(
          children: [
            GlassTextField(
              controller: _specTextControllers[field.key]!,
              labelText: field.label,
              hintText: field.label,
              keyboardType: field.type == 'number'
                  ? TextInputType.number
                  : TextInputType.text,
            ),
            const SizedBox(height: 16),
          ],
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
                    ..._imagePaths.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final imgPath = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(imgPath),
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
                                    _imagePaths.removeAt(idx)),
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
                    if (_imagePaths.length < 5)
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
              Consumer<ItemProvider>(
                builder: (context, provider, _) {
                  final cats = provider.categorySpecs;
                  if (cats.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Container(
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
                        value: cats.any((c) => c.id == _category) ? _category : cats.last.id,
                        isExpanded: true,
                        dropdownColor: AppTheme.cardBg,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        icon: const Icon(Icons.expand_more_rounded,
                            color: AppTheme.accentCyan),
                        items: cats
                            .map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Row(
                                    children: [
                                      Text(c.icon,
                                          style: const TextStyle(fontSize: 18)),
                                      const SizedBox(width: 12),
                                      Text(c.name),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() {
                          _category = v!;
                          _subcategory = '';
                          _specValues.clear();
                          for (final c in _specTextControllers.values) {
                            c.clear();
                          }
                        }),
                      ),
                    ),
                  );
                },
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),

              // Dynamic subcategory + spec fields
              Consumer<ItemProvider>(
                builder: (context, provider, _) {
                  final spec = provider.specForCategory(_category);
                  if (spec == null) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subcategories (if any)
                      if (spec.subcategories.isNotEmpty) ...[
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
                              value: _subcategory.isEmpty ? null : _subcategory,
                              isExpanded: true,
                              dropdownColor: AppTheme.cardBg,
                              style: const TextStyle(color: AppTheme.textPrimary),
                              hint: Text('Select ${spec.name.toLowerCase()} type',
                                  style: const TextStyle(color: AppTheme.textHint)),
                              icon: const Icon(Icons.expand_more_rounded,
                                  color: AppTheme.accentCyan),
                              items: spec.subcategories
                                  .map((s) => DropdownMenuItem(
                                        value: s.id,
                                        child: Text(s.name),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _subcategory = v ?? ''),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Dynamic spec fields
                      ...spec.fields.map((field) => _buildSpecField(field)),
                    ],
                  );
                },
              ),

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

              // Quantity
              Text(
                'Quantity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ).animate().fadeIn(delay: 620.ms),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceGlass,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.accentBlue.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            color: AppTheme.accentCyan),
                        const SizedBox(width: 12),
                        const Text(
                          'Available Units',
                          style: TextStyle(color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                          icon: Icon(Icons.remove_circle_outline,
                              color: _quantity > 1
                                  ? AppTheme.accentCyan
                                  : AppTheme.textHint),
                          iconSize: 28,
                        ),
                        Text(
                          '$_quantity',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _quantity++),
                          icon: const Icon(Icons.add_circle_outline,
                              color: AppTheme.accentCyan),
                          iconSize: 28,
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 640.ms),
              const SizedBox(height: 24),

              // Location / Address
              Text(
                'Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ).animate().fadeIn(delay: 650.ms),
              const SizedBox(height: 12),

              // Address picker from saved addresses
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  final addresses = auth.user?.addresses ?? [];
                  if (addresses.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceGlass,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.2)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedAddress?.id,
                              isExpanded: true,
                              dropdownColor: AppTheme.cardBg,
                              hint: Text('Select saved address', style: TextStyle(color: AppTheme.textHint)),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Enter manually')),
                                ...addresses.map((a) => DropdownMenuItem(
                                  value: a.id,
                                  child: Text('${a.label}: ${a.addressLine1}, ${a.city}', overflow: TextOverflow.ellipsis),
                                )),
                              ],
                              onChanged: (v) {
                                setState(() {
                                  if (v == null) {
                                    _selectedAddress = null;
                                  } else {
                                    _selectedAddress = addresses.firstWhere((a) => a.id == v);
                                    _cityCtrl.text = _selectedAddress!.city;
                                    _lat = _selectedAddress!.location?.latitude;
                                    _lng = _selectedAddress!.location?.longitude;
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              GlassTextField(
                controller: _cityCtrl,
                labelText: 'City',
                hintText: 'e.g., Mumbai',
                prefixIcon: Icons.location_city_rounded,
              ),
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
              const SizedBox(height: 16),

              // Delivery Options
              Text(
                'Delivery Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ).animate().fadeIn(delay: 700.ms),
              const SizedBox(height: 12),

              GlassCard(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    CheckboxListTile(
                      value: _selfPickup,
                      onChanged: (v) => setState(() => _selfPickup = v ?? true),
                      title: const Text('Self Pickup', style: TextStyle(color: AppTheme.textPrimary)),
                      subtitle: Text('Buyer picks up the item', style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
                      secondary: const Icon(Icons.directions_walk, color: AppTheme.accentCyan),
                      activeColor: AppTheme.accentCyan,
                    ),
                    CheckboxListTile(
                      value: _sellerDelivery,
                      onChanged: (v) => setState(() => _sellerDelivery = v ?? false),
                      title: const Text('Seller Delivery', style: TextStyle(color: AppTheme.textPrimary)),
                      subtitle: Text('You deliver to the buyer', style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
                      secondary: const Icon(Icons.local_shipping, color: AppTheme.accentCyan),
                      activeColor: AppTheme.accentCyan,
                    ),
                    CheckboxListTile(
                      value: _inAppDelivery,
                      onChanged: (v) => setState(() => _inAppDelivery = v ?? false),
                      title: const Text('In-App Delivery', style: TextStyle(color: AppTheme.textPrimary)),
                      subtitle: Text('RentPe handles delivery & damage protection', style: TextStyle(color: Colors.green[300], fontSize: 12)),
                      secondary: const Icon(Icons.verified_user, color: Colors.green),
                      activeColor: AppTheme.accentCyan,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 710.ms),

              if (_sellerDelivery) ...[
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
