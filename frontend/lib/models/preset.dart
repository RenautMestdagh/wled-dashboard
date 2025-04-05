class Preset {
  final int id;
  final String name;
  final DateTime createdAt;
  final int instanceCount;

  Preset({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.instanceCount,
  });

  factory Preset.fromJson(Map<String, dynamic> json) {
    return Preset(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
      instanceCount: json['instance_count'] ?? json['instances']?.length ?? 0, // Use instances array length
    );
  }
}