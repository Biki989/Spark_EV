import 'package:flutter/material.dart';
import '../models/station.dart';
import '../services/api_service.dart';

class FavoritesProvider with ChangeNotifier {
  List<Station> _favorites = [];
  final Set<String> _favoriteIds = {};
  bool _isLoading = false;

  List<Station> get favorites => _favorites;
  bool get isLoading => _isLoading;

  bool isFavorite(String stationId) => _favoriteIds.contains(stationId);

  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/favorites');
      _favorites = (response['favorites'] as List).map((f) => Station.fromJson(f)).toList();
      _favoriteIds.clear();
      for (var station in _favorites) {
        _favoriteIds.add(station.id);
      }
    } catch (e) {
      // Silently fail
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleFavorite(String stationId) async {
    try {
      if (_favoriteIds.contains(stationId)) {
        await ApiService.delete('/favorites/$stationId');
        _favoriteIds.remove(stationId);
        _favorites.removeWhere((s) => s.id == stationId);
      } else {
        await ApiService.post('/favorites', body: {'station_id': stationId});
        _favoriteIds.add(stationId);
        await loadFavorites(); // Reload to get full station data
      }
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }
}
