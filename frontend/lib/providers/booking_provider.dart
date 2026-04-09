import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../services/api_service.dart';

class BookingProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<BookingModel> _myRentals = [];
  List<BookingModel> _myListingBookings = [];
  BookingModel? _selectedBooking;
  bool _isLoading = false;
  String? _error;

  List<BookingModel> get myRentals => _myRentals;
  List<BookingModel> get myListingBookings => _myListingBookings;
  BookingModel? get selectedBooking => _selectedBooking;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get pendingRequestsCount =>
      _myListingBookings.where((b) => b.status == 'pending').length;

  Future<void> fetchMyRentals({String? status}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final params = <String, String>{'role': 'renter'};
      if (status != null) params['status'] = status;

      final data = await _api.get('/bookings', queryParams: params);
      _myRentals = (data['bookings'] as List)
          .map<BookingModel>((e) => BookingModel.fromJson(e))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyListingBookings({String? status}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final params = <String, String>{'role': 'owner'};
      if (status != null) params['status'] = status;

      final data = await _api.get('/bookings', queryParams: params);
      _myListingBookings = (data['bookings'] as List)
          .map<BookingModel>((e) => BookingModel.fromJson(e))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createBooking({
    required String itemId,
    required DateTime startDate,
    required DateTime endDate,
    String deliveryOption = 'pickup',
    int quantity = 1,
    String? renterNote,
    DateTime? scheduledPickupTime,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'itemId': itemId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'deliveryOption': deliveryOption,
        'quantity': quantity,
      };
      if (renterNote != null) body['renterNote'] = renterNote;
      if (scheduledPickupTime != null) {
        body['scheduledPickupTime'] = scheduledPickupTime.toIso8601String();
      }

      await _api.post('/bookings', body: body);
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

  Future<bool> respondToBooking(String id,
      {required String status, String? ownerNote, String? estimatedDeliveryTime}) async {
    try {
      final body = <String, dynamic>{'status': status};
      if (ownerNote != null) body['ownerNote'] = ownerNote;
      if (estimatedDeliveryTime != null) body['estimatedDeliveryTime'] = estimatedDeliveryTime;

      await _api.patch('/bookings/$id/respond', body: body);
      await fetchMyListingBookings();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelBooking(String id) async {
    try {
      await _api.patch('/bookings/$id/cancel');
      await fetchMyRentals();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeBooking(String id) async {
    try {
      await _api.patch('/bookings/$id/complete');
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDeliveryStatus(String id, String deliveryStatus) async {
    try {
      await _api.patch('/bookings/$id/delivery-status', body: {'deliveryStatus': deliveryStatus});
      await fetchMyListingBookings();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<BookingModel?> fetchBookingById(String id) async {
    try {
      final data = await _api.get('/bookings/$id');
      final booking = BookingModel.fromJson(data['booking']);
      _selectedBooking = booking;
      notifyListeners();
      return booking;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> negotiatePrice(String id, double price, {String? message}) async {
    try {
      final body = <String, dynamic>{'proposedPrice': price};
      if (message != null) body['message'] = message;
      await _api.patch('/bookings/$id/negotiate', body: body);
      await fetchMyRentals();
      await fetchMyListingBookings();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> acceptNegotiation(String id) async {
    try {
      await _api.patch('/bookings/$id/accept-negotiation');
      await fetchMyRentals();
      await fetchMyListingBookings();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
