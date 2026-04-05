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

  List<ItemModel> get items => _items;
  List<ItemModel> get myItems => _myItems;
  ItemModel? get selectedItem => _selectedItem;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _currentPage < _totalPages;

  Future<void> fetchItems({
    String? search,
    String? category,
    double? minPrice,
    double? maxPrice,
    double? latitude,
    double? longitude,
    double? radius,
    String? sort,
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

  Future<bool> createItem(Map<String, dynamic> itemData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.post('/items', body: itemData);
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

  Future<bool> updateItem(String id, Map<String, dynamic> itemData) async {
    try {
      await _api.patch('/items/$id', body: itemData);
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
}
