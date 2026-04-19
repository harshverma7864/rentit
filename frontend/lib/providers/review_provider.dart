import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../services/api_service.dart';

class ReviewProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<ReviewModel> _reviews = [];
  List<ReviewModel> _itemReviews = [];
  bool _isLoading = false;
  String? _error;
  double _avgRating = 0;
  int _totalReviews = 0;

  List<ReviewModel> get reviews => _reviews;
  List<ReviewModel> get itemReviews => _itemReviews;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get avgRating => _avgRating;
  int get totalReviews => _totalReviews;

  Future<void> fetchReviewsForUser(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.get('/reviews/user/$userId');
      _reviews = (data['reviews'] as List)
          .map<ReviewModel>((e) => ReviewModel.fromJson(e))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createReview({
    required String bookingId,
    required int rating,
    String comment = '',
  }) async {
    try {
      await _api.post('/reviews', body: {
        'bookingId': bookingId,
        'rating': rating,
        'comment': comment,
      });
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ---- Item reviews ----

  Future<void> fetchItemReviews(String itemId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.get('/reviews/item/$itemId');
      _itemReviews = (data['reviews'] as List)
          .map<ReviewModel>((e) => ReviewModel.fromJson(e))
          .toList();
      _avgRating = (data['avgRating'] ?? 0).toDouble();
      _totalReviews = data['totalReviews'] ?? 0;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createItemReview({
    required String itemId,
    required int rating,
    String comment = '',
  }) async {
    try {
      await _api.post('/reviews/item/$itemId', body: {
        'rating': rating,
        'comment': comment,
      });
      await fetchItemReviews(itemId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
