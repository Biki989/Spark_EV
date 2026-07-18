import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/station_card.dart';
import '../station/station_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: Consumer<FavoritesProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: SparkTheme.primaryGreen));
          }
          if (provider.favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No favorites yet', style: TextStyle(fontSize: 18, color: Colors.grey[500])),
                  const SizedBox(height: 8),
                  Text('Tap the heart on a station to save it', style: TextStyle(color: Colors.grey[400])),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadFavorites(),
            color: SparkTheme.primaryGreen,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: provider.favorites.length,
              itemBuilder: (context, index) {
                final station = provider.favorites[index];
                return StationCard(
                  station: station,
                  isFavorite: true,
                  onFavorite: () => provider.toggleFavorite(station.id),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => StationDetailsScreen(stationId: station.id),
                  )),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
