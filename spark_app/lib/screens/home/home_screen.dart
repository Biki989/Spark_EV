import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/station_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/bottom_nav.dart';
import '../map/map_screen.dart';
import '../booking/booking_history_screen.dart';
import '../favorites/favorites_screen.dart';
import '../reviews/reviews_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MapScreen(),
    const BookingHistoryScreen(),
    const FavoritesScreen(),
    const ReviewsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final position = await LocationService.getCurrentPosition();
      if (mounted) {
        context.read<StationProvider>().loadStations(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        context.read<BookingProvider>().loadBookings();
        context.read<FavoritesProvider>().loadFavorites();
      }
    } catch (e) {
      debugPrint('Location error: $e');
      if (mounted) {
        // Fallback to loading stations without precise location
        context.read<StationProvider>().loadStations();
        context.read<BookingProvider>().loadBookings();
        context.read<FavoritesProvider>().loadFavorites();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
