import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../services/api_service.dart';

class FavoriteProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<ItemModel> _favorites = [];
  final Set<String> _favoriteIds = {};
  bool _isLoading = false;
  String? _error;

  List<ItemModel> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool isFavorite(String itemId) => _favoriteIds.contains(itemId);

  Future<void> fetchFavorites() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.get('/favorites');
      _favorites = (data['items'] as List)
          .map<ItemModel>((e) => ItemModel.fromJson(e))
          .toList();
      _favoriteIds
        ..clear()
        ..addAll(_favorites.map((e) => e.id));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String itemId) async {
    // Optimistic toggle
    final wasFav = _favoriteIds.contains(itemId);
    if (wasFav) {
      _favoriteIds.remove(itemId);
      _favorites.removeWhere((i) => i.id == itemId);
    } else {
      _favoriteIds.add(itemId);
    }
    notifyListeners();

    try {
      final data = await _api.post('/favorites/$itemId/toggle');
      final nowFav = data['favorited'] == true;
      if (nowFav != !wasFav) {
        // Server disagreed, resync
        await fetchFavorites();
      }
    } catch (e) {
      // Revert on error
      if (wasFav) {
        _favoriteIds.add(itemId);
      } else {
        _favoriteIds.remove(itemId);
      }
      _error = e.toString();
      notifyListeners();
    }
  }
}
