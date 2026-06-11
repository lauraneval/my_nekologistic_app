class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.createdAt,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final DateTime createdAt;

  /// Expires 60s early as buffer against clock skew.
  DateTime get expiresAt => createdAt.add(Duration(seconds: expiresIn - 60));
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: json['access_token']?.toString() ?? '',
        refreshToken: json['refresh_token']?.toString() ?? '',
        expiresIn: (json['expires_in'] as num?)?.toInt() ?? 3600,
        createdAt: DateTime.now(),
      );
}
