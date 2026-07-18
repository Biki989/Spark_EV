class Station {
  final String id;
  final String ownerId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String chargerType;
  final double powerKw;
  final double pricePerKwh;
  final int ports;
  final double rating;
  final int reviewCount;
  final List<String> photos;
  final String verificationStatus;
  final bool isActive;
  final String? ownerName;
  final double? distance;
  final int? availableSlots;
  final DateTime? createdAt;

  Station({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.chargerType,
    required this.powerKw,
    required this.pricePerKwh,
    required this.ports,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.photos = const [],
    this.verificationStatus = 'pending',
    this.isActive = true,
    this.ownerName,
    this.distance,
    this.availableSlots,
    this.createdAt,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] ?? '',
      ownerId: json['owner_id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] is String)
          ? double.parse(json['latitude'])
          : (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] is String)
          ? double.parse(json['longitude'])
          : (json['longitude'] ?? 0.0).toDouble(),
      chargerType: json['charger_type'] ?? 'Type2',
      powerKw: (json['power_kw'] is String)
          ? double.parse(json['power_kw'])
          : (json['power_kw'] ?? 0.0).toDouble(),
      pricePerKwh: (json['price_per_kwh'] is String)
          ? double.parse(json['price_per_kwh'])
          : (json['price_per_kwh'] ?? 0.0).toDouble(),
      ports: json['ports'] ?? 1,
      rating: (json['rating'] is String)
          ? double.parse(json['rating'])
          : (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      photos: json['photos'] != null ? List<String>.from(json['photos']) : [],
      verificationStatus: json['verification_status'] ?? 'pending',
      isActive: json['is_active'] ?? true,
      ownerName: json['owner_name'],
      distance: json['distance'] != null
          ? (json['distance'] is String
              ? double.parse(json['distance'])
              : json['distance'].toDouble())
          : null,
      availableSlots: json['available_slots'] != null
          ? int.tryParse(json['available_slots'].toString())
          : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'charger_type': chargerType,
    'power_kw': powerKw,
    'price_per_kwh': pricePerKwh,
    'ports': ports,
    'photos': photos,
  };

  String get formattedDistance {
    if (distance == null) return '';
    if (distance! < 1) return '${(distance! * 1000).round()}m';
    return '${distance!.toStringAsFixed(1)}km';
  }

  String get formattedPrice => 'CHF ${pricePerKwh.toStringAsFixed(2)}/kWh';
  String get formattedPower => '${powerKw.toStringAsFixed(0)} kW';
}
