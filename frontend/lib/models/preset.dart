class Preset {
  final int id;
  final String name;
  final int instanceCount;

  Preset({
    required this.id,
    required this.name,
    required this.instanceCount,
  });

  factory Preset.fromJson(Map<String, dynamic> json) {
    return Preset(
      id: json['id'],
      name: json['name'],
      instanceCount: json['instance_count'] ?? json['instances']?.length ?? 0, // Use instances array length
    );
  }
}