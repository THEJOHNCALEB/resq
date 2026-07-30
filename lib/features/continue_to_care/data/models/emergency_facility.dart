class EmergencyFacility {
  final String name;
  final String type;
  final double latitude;
  final double longitude;
  final String address;
  final String phone;
  final String hours;
  final List<String> services;
  final double distanceKm;

  const EmergencyFacility({
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.phone,
    required this.hours,
    required this.services,
    this.distanceKm = 0,
  });

  factory EmergencyFacility.fromJson(Map<String, dynamic> json) {
    return EmergencyFacility(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      hours: json['hours'] as String? ?? '',
      services: List<String>.from(json['services'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'phone': phone,
      'hours': hours,
      'services': services,
    };
  }

  EmergencyFacility copyWithDistance(double distanceKm) {
    return EmergencyFacility(
      name: name,
      type: type,
      latitude: latitude,
      longitude: longitude,
      address: address,
      phone: phone,
      hours: hours,
      services: services,
      distanceKm: distanceKm,
    );
  }
}
