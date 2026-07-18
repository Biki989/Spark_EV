import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/review.dart';
import '../../services/api_service.dart';
import '../../widgets/rating_stars.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  List<Review> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final response = await ApiService.get('/reviews/user');
      setState(() {
        _reviews = (response['reviews'] as List).map((r) => Review.fromJson(r)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Reviews')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: SparkTheme.primaryGreen))
          : _reviews.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No reviews yet', style: TextStyle(fontSize: 18, color: Colors.grey[500])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReviews,
                  color: SparkTheme.primaryGreen,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reviews.length,
                    itemBuilder: (context, index) {
                      final review = _reviews[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(review.stationName ?? 'Station', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                              const SizedBox(height: 8),
                              RatingStars(rating: review.rating.toDouble(), size: 18),
                              if (review.comment != null && review.comment!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(review.comment!, style: TextStyle(color: Colors.grey[600])),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
