class MakerModel {
  final int id;
  final String name;
  final String username;
  final String email;
  final String appKey;
  final String? token;

  MakerModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.appKey,
    this.token,
  });

  factory MakerModel.fromJson(Map<String, dynamic> json) {
    return MakerModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      appKey: json['app_key']?.toString() ?? '',
      token: json['token']?.toString(),
    );
  }
}
