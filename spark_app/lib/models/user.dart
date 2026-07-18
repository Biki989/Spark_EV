class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? avatarUrl;
  final String? stripeCustomerId;
  final String? stripeConnectAccountId;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.stripeCustomerId,
    this.stripeConnectAccountId,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'driver',
      avatarUrl: json['avatar_url'],
      stripeCustomerId: json['stripe_customer_id'],
      stripeConnectAccountId: json['stripe_connect_account_id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'avatar_url': avatarUrl,
  };

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';
  bool get isDriver => role == 'driver';
}
