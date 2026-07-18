import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/station.dart';
import '../../models/review.dart';
import '../../providers/station_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/charger_type_badge.dart';
import '../booking/booking_screen.dart';

class StationDetailsScreen extends StatefulWidget {
  final String stationId;

  const StationDetailsScreen({super.key, required this.stationId});

  @override
  State<StationDetailsScreen> createState() => _StationDetailsScreenState();
}

class _StationDetailsScreenState extends State<StationDetailsScreen> {
  List<Map<String, dynamic>> _availability = [];
  List<Review> _reviews = [];
  bool _loadingAvailability = true;

  @override
  void initState() {
    super.initState();
    context.read<StationProvider>().loadStationDetails(widget.stationId);
    _loadAvailability();
    _loadReviews();
  }

  Future<void> _loadAvailability() async {
    try {
      final response = await ApiService.get('/stations/${widget.stationId}/availability', auth: false);
      setState(() {
        _availability = List<Map<String, dynamic>>.from(response['availability']);
        _loadingAvailability = false;
      });
    } catch (e) {
      setState(() => _loadingAvailability = false);
    }
  }

  Future<void> _loadReviews() async {
    try {
      final response = await ApiService.get('/reviews/station/${widget.stationId}', auth: false);
      setState(() {
        _reviews = (response['reviews'] as List).map((r) => Review.fromJson(r)).toList();
      });
    } catch (e) { /* ignore */ }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<StationProvider>(
        builder: (context, provider, _) {
          final station = provider.selectedStation;
          if (provider.isLoading || station == null) {
            return const Center(child: CircularProgressIndicator(color: SparkTheme.primaryGreen));
          }
          return CustomScrollView(
            slivers: [
              // Hero header
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [SparkTheme.getChargerColor(station.chargerType), SparkTheme.darkBg],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          const Icon(Icons.ev_station, size: 56, color: Colors.white),
                          const SizedBox(height: 12),
                          Text(station.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  Consumer<FavoritesProvider>(
                    builder: (context, fav, _) {
                      final isFav = fav.isFavorite(station.id);
                      return IconButton(
                        icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.white),
                        onPressed: () => fav.toggleFavorite(station.id),
                      );
                    },
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info section
                      _buildInfoCard(station),
                      const SizedBox(height: 20),

                      // Stats row
                      _buildStatsRow(station),
                      const SizedBox(height: 20),

                      // Availability section
                      _buildAvailabilitySection(),
                      const SizedBox(height: 20),

                      // Reviews section
                      _buildReviewsSection(station),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<StationProvider>(
        builder: (context, provider, _) {
          final station = provider.selectedStation;
          if (station == null) return const SizedBox.shrink();
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(station.formattedPrice, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: SparkTheme.primaryGreen)),
                      Text(station.formattedPower, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => BookingScreen(station: station, availability: _availability),
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Text('Book Now'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(Station station) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: SparkTheme.primaryGreen),
                const SizedBox(width: 8),
                Expanded(child: Text(station.address, style: const TextStyle(fontSize: 14))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ChargerTypeBadge(type: station.chargerType, isLarge: true),
                const SizedBox(width: 12),
                if (station.distance != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: SparkTheme.grey100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.near_me, size: 14, color: SparkTheme.grey600),
                        const SizedBox(width: 4),
                        Text(station.formattedDistance, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(Station station) {
    return Row(
      children: [
        _StatCard(icon: Icons.bolt, label: 'Power', value: station.formattedPower, color: SparkTheme.warningYellow),
        const SizedBox(width: 12),
        _StatCard(icon: Icons.electrical_services, label: 'Ports', value: '${station.ports}', color: SparkTheme.infoBlue),
        const SizedBox(width: 12),
        _StatCard(icon: Icons.star, label: 'Rating', value: station.rating.toStringAsFixed(1), color: Colors.amber),
      ],
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Availability', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (_loadingAvailability)
          const Center(child: CircularProgressIndicator(color: SparkTheme.primaryGreen))
        else if (_availability.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('No availability data', style: TextStyle(color: Colors.grey[500])),
              ),
            ),
          )
        else
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _availability.length > 10 ? 10 : _availability.length,
              itemBuilder: (context, index) {
                final slot = _availability[index];
                final isAvailable = slot['status'] == 'available';
                return Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isAvailable ? SparkTheme.primaryGreen.withOpacity(0.1) : SparkTheme.grey100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isAvailable ? SparkTheme.primaryGreen : SparkTheme.grey200,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        slot['start_time']?.toString().substring(0, 5) ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isAvailable ? SparkTheme.primaryGreen : SparkTheme.grey400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isAvailable ? SparkTheme.pinAvailable : SparkTheme.pinFull,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Port ${slot['port']}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildReviewsSection(Station station) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const Spacer(),
            if (station.reviewCount > 0)
              Text('${station.reviewCount} reviews', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ],
        ),
        const SizedBox(height: 12),
        if (_reviews.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text('No reviews yet', style: TextStyle(color: Colors.grey[500]))),
            ),
          )
        else
          ...List.generate(_reviews.length > 3 ? 3 : _reviews.length, (index) {
            final review = _reviews[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: SparkTheme.primaryGreen.withOpacity(0.2),
                          child: Text(
                            (review.userName ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(color: SparkTheme.primaryGreen, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(review.userName ?? 'User', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const Spacer(),
                        RatingStars(rating: review.rating.toDouble(), size: 14),
                      ],
                    ),
                    if (review.comment != null && review.comment!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(review.comment!, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}
