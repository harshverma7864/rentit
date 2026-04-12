import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../services/api_service.dart';

class ReviewProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<ReviewModel> _reviews = [];
  bool _isLoading = false;
  String? _error;

  List<ReviewModel> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
}
