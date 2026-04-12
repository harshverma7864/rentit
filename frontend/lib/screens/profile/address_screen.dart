import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';

class AddressScreen extends StatefulWidget {
  final AddressModel? editAddress;
  const AddressScreen({super.key, this.editAddress});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelCtrl = TextEditingController();
  final _line1Ctrl = TextEditingController();
  final _line2Ctrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  double? _lat, _lng;
  bool _isDefault = false;
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    if (widget.editAddress != null) {
      final a = widget.editAddress!;
      _labelCtrl.text = a.label;
      _line1Ctrl.text = a.addressLine1;
      _line2Ctrl.text = a.addressLine2;
      _streetCtrl.text = a.street;
      _cityCtrl.text = a.city;
      _stateCtrl.text = a.state;
      _pincodeCtrl.text = a.pincode;
      _landmarkCtrl.text = a.landmark;
      _lat = a.location?.latitude;
      _lng = a.location?.longitude;
      _isDefault = a.isDefault;
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _line1Ctrl.dispose();
    _line2Ctrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _landmarkCtrl.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() => _isDetecting = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _lat = pos.latitude;
      _lng = pos.longitude;

      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          if (_line1Ctrl.text.isEmpty) _line1Ctrl.text = p.street ?? '';
          if (_cityCtrl.text.isEmpty) _cityCtrl.text = p.locality ?? '';
          if (_stateCtrl.text.isEmpty) _stateCtrl.text = p.administrativeArea ?? '';
          if (_pincodeCtrl.text.isEmpty) _pincodeCtrl.text = p.postalCode ?? '';
          if (_streetCtrl.text.isEmpty) _streetCtrl.text = p.subLocality ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDetecting = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final data = {
      'label': _labelCtrl.text.trim().isEmpty ? 'Home' : _labelCtrl.text.trim(),
      'addressLine1': _line1Ctrl.text.trim(),
      'addressLine2': _line2Ctrl.text.trim(),
      'street': _streetCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'state': _stateCtrl.text.trim(),
      'pincode': _pincodeCtrl.text.trim(),
      'landmark': _landmarkCtrl.text.trim(),
      'latitude': _lat ?? 0,
      'longitude': _lng ?? 0,
      'isDefault': _isDefault,
    };

    bool success;
    if (widget.editAddress != null) {
      success = await auth.updateAddress(widget.editAddress!.id, data);
    } else {
      success = await auth.addAddress(data);
    }

    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Failed to save address')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editAddress != null ? 'Edit Address' : 'Add Address'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GlassTextField(
                controller: _labelCtrl,
                hintText: 'Label (e.g. Home, Office)',
              ),
              const SizedBox(height: 12),
              GlassTextField(
                controller: _line1Ctrl,
                hintText: 'Address Line 1 *',
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              GlassTextField(
                controller: _line2Ctrl,
                hintText: 'Address Line 2',
              ),
              const SizedBox(height: 12),
              GlassTextField(
                controller: _streetCtrl,
                hintText: 'Street / Locality',
              ),
              const SizedBox(height: 12),
              GlassTextField(
                controller: _landmarkCtrl,
                hintText: 'Landmark',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GlassTextField(
                      controller: _cityCtrl,
                      hintText: 'City *',
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassTextField(
                      controller: _stateCtrl,
                      hintText: 'State',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GlassTextField(
                controller: _pincodeCtrl,
                hintText: 'Pincode',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GlassButton(
                      onPressed: _isDetecting ? null : _detectLocation,
                      child: _isDetecting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.my_location, size: 18),
                                SizedBox(width: 8),
                                Text('Detect Location'),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_lat != null)
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v ?? false),
                title: const Text('Set as default address'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: GlassButton(
                  onPressed: _save,
                  child: Text(widget.editAddress != null ? 'Update Address' : 'Save Address'),
                ),
              ),
            ].animate(interval: 50.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
          ),
        ),
      ),
    );
  }
}

class AddressListScreen extends StatelessWidget {
  const AddressListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Addresses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const AddressScreen()),
              );
              if (result == true) {
                // Refresh happens in auth provider automatically
              }
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final addresses = auth.user?.addresses ?? [];
          if (addresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text('No addresses saved', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                  const SizedBox(height: 16),
                  GlassButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressScreen()));
                    },
                    child: const Text('Add Address'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final addr = addresses[index];
              return GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    addr.isDefault ? Icons.home : Icons.location_on,
                    color: addr.isDefault ? AppTheme.accentCyan : Colors.grey,
                  ),
                  title: Text(
                    '${addr.label}${addr.isDefault ? ' (Default)' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(addr.fullAddress, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: PopupMenuButton(
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      if (!addr.isDefault)
                        const PopupMenuItem(value: 'default', child: Text('Set Default')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AddressScreen(editAddress: addr)),
                        );
                      } else if (value == 'default') {
                        await auth.setDefaultAddress(addr.id);
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Address'),
                            content: const Text('Are you sure?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await auth.deleteAddress(addr.id);
                        }
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
