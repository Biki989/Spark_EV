class Booking {
  final String id;
  final String userId;
  final String stationId;
  final int port;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final String? paymentId;
  final double? totalAmount;
  final String currency;
  final String? stationName;
  final String? stationAddress;
  final String? chargerType;
  final double? powerKw;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;

  Booking({
    required this.id,
    required this.userId,
    required this.stationId,
    required this.port,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.paymentId,
    this.totalAmount,
    this.currency = 'CHF',
    this.stationName,
    this.stationAddress,
    this.chargerType,
    this.powerKw,
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      stationId: json['station_id'] ?? '',
      port: json['port'] ?? 1,
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      status: json['status'] ?? 'confirmed',
      paymentId: json['payment_id'],
      totalAmount: json['total_amount'] != null
          ? double.tryParse(json['total_amount'].toString())
          : null,
      currency: json['currency'] ?? 'CHF',
      stationName: json['station_name'],
      stationAddress: json['address'],
      chargerType: json['charger_type'],
      powerKw: json['power_kw'] != null
          ? double.tryParse(json['power_kw'].toString())
          : null,
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  bool get isUpcoming => status == 'confirmed' && startTime.isAfter(DateTime.now());
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled' || status == 'no_show';

  Duration get timeUntilStart => startTime.difference(DateTime.now());
  String get formattedAmount => totalAmount != null ? 'CHF ${totalAmount!.toStringAsFixed(2)}' : 'N/A';
}
