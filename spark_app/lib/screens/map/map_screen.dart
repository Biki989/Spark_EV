import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/station.dart';
import '../../providers/station_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/station_card.dart';
import '../../widgets/charger_type_badge.dart';
import '../../services/location_service.dart';
import '../station/station_details_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showList = false;
  String? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map placeholder (Mapbox integration point)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  SparkTheme.grey100,
                  SparkTheme.grey200,
                ],
              ),
            ),
            child: Consumer<StationProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: SparkTheme.primaryGreen));
                }
                if (provider.stations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.ev_station, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('No stations found nearby', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => _refreshStations(),
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  );
                }
                // Map with station pins - show as interactive grid for now
                return _buildMapView(provider.stations);
              },
            ),
          ),

          // Search bar overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search charging stations...',
                      prefixIcon: const Icon(Icons.search, color: SparkTheme.grey400),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _showList ? Icons.map : Icons.list,
                              color: SparkTheme.primaryGreen,
                            ),
                            onPressed: () => setState(() => _showList = !_showList),
                          ),
                          IconButton(
                            icon: const Icon(Icons.tune, color: SparkTheme.primaryGreen),
                            onPressed: _showFilterSheet,
                          ),
                        ],
                      ),
                      border: InputBorder.none,
                      filled: false,
                    ),
                  ),
                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
                    child: Row(
                      children: [
                        for (final type in ['CCS', 'Type2', 'Tesla', 'CHAdeMO']) ...[
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(type),
                              selected: _selectedFilter == type,
                              selectedColor: SparkTheme.getChargerColor(type).withOpacity(0.2),
                              checkmarkColor: SparkTheme.getChargerColor(type),
                              onSelected: (selected) {
                                setState(() => _selectedFilter = selected ? type : null);
                                context.read<StationProvider>().setFilters(chargerType: selected ? type : null);
                                _refreshStations();
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Station list overlay
          if (_showList)
            Positioned(
              top: MediaQuery.of(context).padding.top + 130,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Consumer<StationProvider>(
                  builder: (context, provider, _) {
                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 16),
                      itemCount: provider.stations.length,
                      itemBuilder: (context, index) {
                        final station = provider.stations[index];
                        return Consumer<FavoritesProvider>(
                          builder: (context, favProvider, _) {
                            return StationCard(
                              station: station,
                              isFavorite: favProvider.isFavorite(station.id),
                              onFavorite: () => favProvider.toggleFavorite(station.id),
                              onTap: () => _openStationDetails(station),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshStations,
        backgroundColor: SparkTheme.primaryGreen,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  Widget _buildMapView(List<Station> stations) {
    // Interactive map grid view showing stations as pins
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 140),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: stations.length,
        itemBuilder: (context, index) {
          final station = stations[index];
          return _MapPin(
            station: station,
            onTap: () => _openStationDetails(station),
          );
        },
      ),
    );
  }

  void _openStationDetails(Station station) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StationDetailsScreen(stationId: station.id),
      ),
    );
  }

  void _refreshStations() async {
    final position = await LocationService.getCurrentPosition();
    if (mounted) {
      context.read<StationProvider>().loadStations(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterSheet(
        onApply: (chargerType, minPower, maxPrice, radius) {
          context.read<StationProvider>().setFilters(
            chargerType: chargerType,
            minPower: minPower,
            maxPrice: maxPrice,
            radius: radius,
          );
          _refreshStations();
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  final Station station;
  final VoidCallback onTap;

  const _MapPin({required this.station, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = SparkTheme.getPinColor(
      station.availableSlots ?? 0,
      station.ports,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    station.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            ChargerTypeBadge(type: station.chargerType),
            const SizedBox(height: 6),
            Text(station.formattedPower, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text(station.formattedPrice, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SparkTheme.primaryGreen)),
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final Function(String?, double?, double?, double?) onApply;

  const _FilterSheet({required this.onApply});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _chargerType;
  double _radius = 10;
  double _maxPrice = 1.0;
  double _minPower = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Filter Stations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),

          const Text('Charger Type', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['CCS', 'Type2', 'Tesla', 'CHAdeMO'].map((type) {
              return ChoiceChip(
                label: Text(type),
                selected: _chargerType == type,
                onSelected: (s) => setState(() => _chargerType = s ? type : null),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          Text('Distance: ${_radius.toStringAsFixed(0)} km', style: const TextStyle(fontWeight: FontWeight.w600)),
          Slider(
            value: _radius,
            min: 1,
            max: 50,
            divisions: 49,
            activeColor: SparkTheme.primaryGreen,
            onChanged: (v) => setState(() => _radius = v),
          ),

          Text('Max Price: CHF ${_maxPrice.toStringAsFixed(2)}/kWh', style: const TextStyle(fontWeight: FontWeight.w600)),
          Slider(
            value: _maxPrice,
            min: 0.1,
            max: 2.0,
            divisions: 19,
            activeColor: SparkTheme.primaryGreen,
            onChanged: (v) => setState(() => _maxPrice = v),
          ),

          Text('Min Power: ${_minPower.toStringAsFixed(0)} kW', style: const TextStyle(fontWeight: FontWeight.w600)),
          Slider(
            value: _minPower,
            min: 0,
            max: 350,
            divisions: 35,
            activeColor: SparkTheme.primaryGreen,
            onChanged: (v) => setState(() => _minPower = v),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: () => widget.onApply(
              _chargerType,
              _minPower > 0 ? _minPower : null,
              _maxPrice < 2.0 ? _maxPrice : null,
              _radius,
            ),
            child: const Text('Apply Filters'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
