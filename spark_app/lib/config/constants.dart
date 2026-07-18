class AppConstants {
  static const String appName = 'Spark';
  static const String appTagline = 'EV Charging, Simplified';
  
  // API
  static const String apiBaseUrl = 'http://192.168.1.72:3000/api';
  
  // Mapbox
  static const String mapboxAccessToken = 'YOUR_MAPBOX_ACCESS_TOKEN';
  static const double defaultLatitude = 46.9480; // Bern, Switzerland
  static const double defaultLongitude = 7.4474;
  static const double defaultZoom = 12.0;
  
  // Booking
  static const int lateCancelMinutes = 15;
  static const int maxBookingDurationHours = 4;
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Currency
  static const String currency = 'CHF';
  static const String currencySymbol = 'CHF';
  
  // Charger Types
  static const List<String> chargerTypes = ['CCS', 'Type2', 'Tesla', 'CHAdeMO'];
  
  // Map
  static const double searchRadiusKm = 10.0;
}
