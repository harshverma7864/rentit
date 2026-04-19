import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../providers/item_provider.dart';
import '../../models/item_model.dart';
import '../items/item_detail_screen.dart';

class BrowseScreen extends StatefulWidget {
  final String? initialCategory;

  const BrowseScreen({super.key, this.initialCategory});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategory;
  String _sortBy = 'latest';
  double? _selectedRadius; // null = everywhere
  double? _userLatitude;
  double? _userLongitude;
  bool _locationLoading = false;

  // Dynamic spec filters (key → selected value)
  final Map<String, String?> _specFilters = {};
  bool _showFilters = false;

  String? _selectedSubcategory;

  final List<Map<String, dynamic>> _radiusOptions = [
    {'label': '5 km', 'value': 5.0},
    {'label': '10 km', 'value': 10.0},
    {'label': '15 km', 'value': 15.0},
    {'label': 'Everywhere', 'value': null},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    context.read<ItemProvider>().fetchCategorySpecs();
    _search();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters => _specFilters.values.any((v) => v != null);

  CategorySpec? get _currentSpec =>
      context.read<ItemProvider>().specForCategory(_selectedCategory);

  bool get _hasFilterableFields {
    final spec = _currentSpec;
    return spec != null && spec.filterableFields.isNotEmpty;
  }

  void _search() {
    // When a subcategory is picked, search by subcategory
    String? searchCategory = _selectedCategory;
    final spec = _currentSpec;
    if (spec != null && spec.subcategories.isNotEmpty && _selectedSubcategory != null) {
      searchCategory = _selectedSubcategory;
    }

    // Build spec filter map (only non-null values)
    final specFilterMap = <String, String>{};
    for (final entry in _specFilters.entries) {
      if (entry.value != null && entry.value!.isNotEmpty) {
        specFilterMap[entry.key] = entry.value!;
      }
    }

    context.read<ItemProvider>().fetchItems(
          refresh: true,
          search: _searchController.text.isNotEmpty
              ? _searchController.text
              : null,
          category: searchCategory,
          latitude: _selectedRadius != null ? _userLatitude : null,
          longitude: _selectedRadius != null ? _userLongitude : null,
          radius: _selectedRadius,
          sort: _sortBy == 'price_asc'
              ? 'price_asc'
              : _sortBy == 'price_desc'
                  ? 'price_desc'
                  : null,
          specFilters: specFilterMap.isNotEmpty ? specFilterMap : null,
        );
  }

  Future<void> _getUserLocation() async {
    setState(() => _locationLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable location services')),
          );
        }
        setState(() {
          _selectedRadius = null;
          _locationLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        setState(() {
          _selectedRadius = null;
          _locationLoading = false;
        });
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      setState(() {
        _userLatitude = position.latitude;
        _userLongitude = position.longitude;
        _locationLoading = false;
      });
      _search();
    } catch (e) {
      setState(() {
        _selectedRadius = null;
        _locationLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    }
  }

  void _onRadiusSelected(double? radius) {
    setState(() => _selectedRadius = radius);
    if (radius == null) {
      // Everywhere — no location needed
      _search();
    } else if (_userLatitude != null && _userLongitude != null) {
      // Already have location
      _search();
    } else {
      // Need to fetch location first
      _getUserLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryDark, AppTheme.primaryDeep],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Search header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: AppTheme.textPrimary,
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(color: AppTheme.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Search items...',
                              prefixIcon: Icon(Icons.search_rounded,
                                  color: AppTheme.accentCyan),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear,
                                          color: AppTheme.textHint),
                                      onPressed: () {
                                        _searchController.clear();
                                        _search();
                                      },
                                    )
                                  : null,
                            ),
                            onSubmitted: (_) => _search(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.sort_rounded,
                          color: AppTheme.accentCyan),
                      color: AppTheme.cardBg,
                      onSelected: (value) {
                        setState(() => _sortBy = value);
                        _search();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'latest',
                          child: Text('Latest First'),
                        ),
                        const PopupMenuItem(
                          value: 'price_asc',
                          child: Text('Price: Low to High'),
                        ),
                        const PopupMenuItem(
                          value: 'price_desc',
                          child: Text('Price: High to Low'),
                        ),
                      ],
                    ),
                    if (_hasFilterableFields)
                      IconButton(
                        onPressed: () => setState(() => _showFilters = !_showFilters),
                        icon: Icon(
                          Icons.tune_rounded,
                          color: _hasActiveFilters
                              ? AppTheme.primaryBlue
                              : AppTheme.accentCyan,
                        ),
                      ),
                  ],
                ),
              ),

              // Category chips
              Consumer<ItemProvider>(
                builder: (context, provider, _) {
                  final cats = provider.categorySpecs;
                  return SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: cats.length + 1, // +1 for "All"
                      itemBuilder: (context, index) {
                        final isAll = index == 0;
                        final cat = isAll ? null : cats[index - 1];
                        final catId = isAll ? null : cat!.id;
                        final isSelected = _selectedCategory == catId;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = catId;
                                _selectedSubcategory = null;
                                _specFilters.clear();
                                _showFilters = false;
                              });
                              _search();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryBlue
                                    : AppTheme.surfaceGlass,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.accentCyan
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(isAll ? '✨' : cat!.icon, style: const TextStyle(fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Text(
                                    isAll ? 'All' : cat!.name,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.textSecondary,
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              // Radius filter chips
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: _selectedRadius != null
                            ? AppTheme.accentCyan
                            : AppTheme.textHint,
                        size: 18,
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        itemCount: _radiusOptions.length,
                        itemBuilder: (context, index) {
                          final option = _radiusOptions[index];
                          final isSelected =
                              _selectedRadius == option['value'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: _locationLoading
                                  ? null
                                  : () =>
                                      _onRadiusSelected(option['value']),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryBlue
                                      : AppTheme.surfaceGlass,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.accentCyan
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    if (_locationLoading &&
                                        option['value'] == _selectedRadius)
                                      Padding(
                                        padding: EdgeInsets.only(right: 6),
                                        child: SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppTheme.accentCyan,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      option['label'] as String,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : AppTheme.textSecondary,
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Subcategory chips (only when category has subcategories)
              Consumer<ItemProvider>(
                builder: (context, provider, _) {
                  final spec = provider.specForCategory(_selectedCategory);
                  if (spec == null || spec.subcategories.isEmpty) return const SizedBox.shrink();
                  return SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: spec.subcategories.length + 1,
                      itemBuilder: (context, index) {
                        final isAll = index == 0;
                        final sub = isAll ? null : spec.subcategories[index - 1];
                        final isSelected = isAll
                            ? _selectedSubcategory == null
                            : _selectedSubcategory == sub!.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedSubcategory = isAll ? null : sub!.id;
                              });
                              _search();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primaryBlue.withValues(alpha: 0.8) : AppTheme.surfaceGlass,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: isSelected ? AppTheme.accentCyan : Colors.transparent),
                              ),
                              child: Center(
                                child: Text(
                                  isAll ? 'All ${spec.name}' : sub!.name,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              // Dynamic spec filters panel
              if (_showFilters)
                Consumer<ItemProvider>(
                  builder: (context, provider, _) {
                    final spec = provider.specForCategory(_selectedCategory);
                    if (spec == null) return const SizedBox.shrink();
                    final filterableFields = spec.filterableFields;
                    if (filterableFields.isEmpty) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceGlass,
                        border: Border(
                          bottom: BorderSide(color: AppTheme.accentBlue.withValues(alpha: 0.1)),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...filterableFields.map((field) {
                            if (field.type == 'select' && field.options.isNotEmpty) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(field.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [null, ...field.options].map((opt) {
                                      final isSelected = _specFilters[field.key] == opt;
                                      return GestureDetector(
                                        onTap: () { setState(() => _specFilters[field.key] = opt); _search(); },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppTheme.primaryBlue : AppTheme.surfaceGlassLight,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: isSelected ? AppTheme.accentCyan : AppTheme.accentBlue.withValues(alpha: 0.2)),
                                          ),
                                          child: Text(
                                            opt == null ? 'All' : (opt.isNotEmpty ? opt[0].toUpperCase() + opt.substring(1) : opt),
                                            style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppTheme.textPrimary),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              );
                            }
                            // text filterable fields  – skip in chip UI for now
                            return const SizedBox.shrink();
                          }),
                          if (_hasActiveFilters)
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  setState(() => _specFilters.clear());
                                  _search();
                                },
                                child: Text('Clear All Filters', style: TextStyle(color: AppTheme.accentCyan, fontSize: 13)),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),

              // Items grid
              Expanded(
                child: Consumer<ItemProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading && provider.items.isEmpty) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accentCyan,
                        ),
                      );
                    }

                    if (provider.items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 64, color: AppTheme.textHint),
                            const SizedBox(height: 16),
                            Text(
                              'No items found',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: provider.items.length,
                      itemBuilder: (context, index) {
                        final item = provider.items[index];
                        return _BrowseItemCard(item: item);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrowseItemCard extends StatelessWidget {
  final ItemModel item;

  const _BrowseItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ItemDetailScreen(itemId: item.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.accentBlue.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.3),
                    AppTheme.accentCyan.withValues(alpha: 0.2),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: item.imageUrls.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20)),
                            child: Image.network(
                              item.imageUrls.first,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 120,
                              errorBuilder: (_, __, ___) => Text(
                                item.categoryIcon,
                                style: const TextStyle(fontSize: 40),
                              ),
                            ),
                          )
                        : Text(
                            item.categoryIcon,
                            style: const TextStyle(fontSize: 40),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryDark.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.conditionLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.accentCyan,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (item.location?.city != null)
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 12, color: AppTheme.textHint),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            item.location!.city,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textHint,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            '₹${item.pricePerDay.toInt()}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.accentCyan,
                            ),
                          ),
                          Text(
                            '/day',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textHint,
                            ),
                          ),
                        ],
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: AppTheme.textHint),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
