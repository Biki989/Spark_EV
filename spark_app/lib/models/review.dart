class Review {
  final String id;
  final String userId;
  final String stationId;
  final int rating;
  final String? comment;
  final String? userName;
  final String? avatarUrl;
  final String? stationName;
  final DateTime? createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.stationId,
    required this.rating,
    this.comment,
    this.userName,
    this.avatarUrl,
    this.stationName,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      stationId: json['station_id'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      userName: json['user_name'],
      avatarUrl: json['avatar_url'],
      stationName: json['station_name'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }
}

class Payment {
  final String id;
  final String bookingId;
  final String userId;
  final double amount;
  final String currency;
  final String? stripePaymentIntentId;
  final String status;
  final String? stationName;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? createdAt;

  Payment({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.amount,
    this.currency = 'CHF',
    this.stripePaymentIntentId,
    required this.status,
    this.stationName,
    this.startTime,
    this.endTime,
    this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? '',
      bookingId: json['booking_id'] ?? '',
      userId: json['user_id'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      currency: json['currency'] ?? 'CHF',
      stripePaymentIntentId: json['stripe_payment_intent_id'],
      status: json['status'] ?? 'pending',
      stationName: json['station_name'],
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time']) : null,
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  String get formattedAmount => 'CHF ${amount.toStringAsFixed(2)}';
}
