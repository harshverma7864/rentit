import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../services/api_service.dart';

class ItemProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<ItemModel> _items = [];
  List<ItemModel> _myItems = [];
  ItemModel? _selectedItem;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;

  /// Category schemas fetched from backend
  List<CategorySpec> _categorySpecs = [];
  List<CategorySpec> get categorySpecs => _categorySpecs;

  List<ItemModel> get items => _items;
  List<ItemModel> get myItems => _myItems;
  ItemModel? get selectedItem => _selectedItem;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _currentPage < _totalPages;

  /// Fetch category schemas (with spec field definitions) from the backend.
  Future<void> fetchCategorySpecs() async {
    if (_categorySpecs.isNotEmpty) return; // already cached
    try {
      final data = await _api.get('/items/categories');
      _categorySpecs = (data['categories'] as List)
          .map<CategorySpec>((e) => CategorySpec.fromJson(e))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  /// Get cached spec for a category id (resolves subcategories to parents).
  CategorySpec? specForCategory(String? categoryId) {
    if (categoryId == null) return null;
    // Direct match
    final direct = _categorySpecs.where((c) => c.id == categoryId);
    if (direct.isNotEmpty) return direct.first;
    // Check if it's a subcategory
    for (final spec in _categorySpecs) {
      if (spec.subcategories.any((s) => s.id == categoryId)) return spec;
    }
    return null;
  }

  Future<void> fetchItems({
    String? search,
    String? category,
    double? minPrice,
    double? maxPrice,
    double? latitude,
    double? longitude,
    double? radius,
    String? sort,
    Map<String, String>? specFilters,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _items = [];
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, String>{
        'page': _currentPage.toString(),
        'limit': '20',
      };
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (category != null) params['category'] = category;
      if (minPrice != null) params['minPrice'] = minPrice.toString();
      if (maxPrice != null) params['maxPrice'] = maxPrice.toString();
      if (latitude != null) params['latitude'] = latitude.toString();
      if (longitude != null) params['longitude'] = longitude.toString();
      if (radius != null) params['radius'] = radius.toString();
      if (sort != null) params['sort'] = sort;
      // Dynamic spec filters – sent as top-level query params
      if (specFilters != null) {
        for (final entry in specFilters.entries) {
          if (entry.value.isNotEmpty) params[entry.key] = entry.value;
        }
      }

      final data = await _api.get('/items', queryParams: params);
      final newItems = (data['items'] as List)
          .map<ItemModel>((e) => ItemModel.fromJson(e))
          .toList();

      if (refresh) {
        _items = newItems;
      } else {
        _items.addAll(newItems);
      }

      final pagination = data['pagination'] as Map<String, dynamic>;
      _totalPages = pagination['pages'] ?? 1;
      _currentPage++;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchItemById(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.get('/items/$id');
      _selectedItem = ItemModel.fromJson(data['item']);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.get('/items/mine');
      _myItems = (data['items'] as List)
          .map<ItemModel>((e) => ItemModel.fromJson(e))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createItem(Map<String, dynamic> itemData, {List<String> imagePaths = const []}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fields = <String, String>{};
      for (final entry in itemData.entries) {
        if (entry.key == 'images') continue; // handled as files
        if (entry.value is Map || entry.value is List) {
          fields[entry.key] = jsonEncode(entry.value);
        } else {
          fields[entry.key] = entry.value.toString();
        }
      }

      await _api.multipartPost('/items', fields: fields, filePaths: imagePaths);
      await fetchMyItems();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateItem(String id, Map<String, dynamic> itemData, {List<String> newImagePaths = const []}) async {
    try {
      final fields = <String, String>{};
      for (final entry in itemData.entries) {
        if (entry.key == 'images' && newImagePaths.isNotEmpty) continue;
        if (entry.value is Map || entry.value is List) {
          fields[entry.key] = jsonEncode(entry.value);
        } else {
          fields[entry.key] = entry.value.toString();
        }
      }

      await _api.multipartPatch('/items/$id', fields: fields, filePaths: newImagePaths);
      await fetchMyItems();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem(String id) async {
    try {
      await _api.delete('/items/$id');
      _myItems.removeWhere((i) => i.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ---- Boost ----

  List<ItemModel> _recommendedItems = [];
  List<ItemModel> get recommendedItems => _recommendedItems;

  Future<bool> boostItem(String itemId, String tier) async {
    try {
      await _api.post('/items/$itemId/boost', body: {'tier': tier});
      await fetchMyItems();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchRecommended({double? latitude, double? longitude}) async {
    try {
      final params = <String, String>{};
      if (latitude != null) params['latitude'] = latitude.toString();
      if (longitude != null) params['longitude'] = longitude.toString();

      final data = await _api.get('/items/recommended', queryParams: params);
      _recommendedItems = (data['items'] as List)
          .map<ItemModel>((e) => ItemModel.fromJson(e))
          .toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
