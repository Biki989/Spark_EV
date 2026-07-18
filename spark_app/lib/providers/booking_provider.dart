import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/api_service.dart';

class BookingProvider with ChangeNotifier {
  List<Booking> _bookings = [];
  Booking? _currentBooking;
  bool _isLoading = false;
  String? _error;

  List<Booking> get bookings => _bookings;
  Booking? get currentBooking => _currentBooking;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Booking> get upcomingBookings => _bookings.where((b) => b.isUpcoming).toList();
  List<Booking> get pastBookings => _bookings.where((b) => b.isCompleted || b.isCancelled).toList();

  Future<void> loadBookings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/bookings');
      _bookings = (response['bookings'] as List).map((b) => Booking.fromJson(b)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Booking?> createBooking({
    required String stationId,
    required int port,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.post('/bookings', body: {
        'station_id': stationId,
        'port': port,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
      });
      final booking = Booking.fromJson(response['booking']);
      _currentBooking = booking;
      _bookings.insert(0, booking);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return booking;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    try {
      await ApiService.post('/bookings/$bookingId/cancel');
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index >= 0) {
        await loadBookings(); // Reload to get updated status
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
