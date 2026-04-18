import 'package:flutter/material.dart';
import '../models/dispute_model.dart';
import '../services/api_service.dart';

class DisputeProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<DisputeModel> _disputes = [];
  DisputeModel? _selectedDispute;
  bool _isLoading = false;
  String? _error;

  List<DisputeModel> get disputes => _disputes;
  DisputeModel? get selectedDispute => _selectedDispute;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMyDisputes() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.get('/disputes');
      _disputes = (data['disputes'] as List)
          .map<DisputeModel>((e) => DisputeModel.fromJson(e))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createDispute({
    required String bookingId,
    required String reason,
    required String description,
    List<String> imagePaths = const [],
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fields = <String, String>{
        'bookingId': bookingId,
        'reason': reason,
        'description': description,
      };

      await _api.multipartPost(
        '/disputes',
        fields: fields,
        filePaths: imagePaths,
        fileField: 'images',
      );

      _isLoading = false;
      notifyListeners();
      await fetchMyDisputes();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<DisputeModel?> fetchDisputeById(String id) async {
    try {
      final data = await _api.get('/disputes/$id');
      final dispute = DisputeModel.fromJson(data['dispute']);
      _selectedDispute = dispute;
      notifyListeners();
      return dispute;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
