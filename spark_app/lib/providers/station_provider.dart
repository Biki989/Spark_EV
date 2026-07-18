import 'package:flutter/material.dart';
import '../models/station.dart';
import '../services/api_service.dart';

class StationProvider with ChangeNotifier {
  List<Station> _stations = [];
  Station? _selectedStation;
  bool _isLoading = false;
  String? _error;

  // Filters
  String? _chargerTypeFilter;
  double? _minPowerFilter;
  double? _maxPriceFilter;
  double _radiusFilter = 10.0;

  List<Station> get stations => _stations;
  Station? get selectedStation => _selectedStation;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get chargerTypeFilter => _chargerTypeFilter;
  double get radiusFilter => _radiusFilter;

  Future<void> loadStations({double? latitude, double? longitude}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final queryParams = <String, String>{};
      if (latitude != null) queryParams['latitude'] = latitude.toString();
      if (longitude != null) queryParams['longitude'] = longitude.toString();
      queryParams['radius'] = _radiusFilter.toString();
      if (_chargerTypeFilter != null) queryParams['charger_type'] = _chargerTypeFilter!;
      if (_minPowerFilter != null) queryParams['min_power'] = _minPowerFilter.toString();
      if (_maxPriceFilter != null) queryParams['max_price'] = _maxPriceFilter.toString();

      final response = await ApiService.get('/stations', queryParams: queryParams, auth: false);
      _stations = (response['stations'] as List).map((s) => Station.fromJson(s)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadStationDetails(String stationId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/stations/$stationId', auth: false);
      _selectedStation = Station.fromJson(response['station']);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void setFilters({String? chargerType, double? minPower, double? maxPrice, double? radius}) {
    _chargerTypeFilter = chargerType;
    _minPowerFilter = minPower;
    _maxPriceFilter = maxPrice;
    if (radius != null) _radiusFilter = radius;
    notifyListeners();
  }

  void clearFilters() {
    _chargerTypeFilter = null;
    _minPowerFilter = null;
    _maxPriceFilter = null;
    _radiusFilter = 10.0;
    notifyListeners();
  }
}
