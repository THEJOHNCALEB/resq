import 'dart:convert';
import 'package:flutter/services.dart';
import '../../features/continue_to_care/data/models/emergency_facility.dart';
import '../../core/constants/app_constants.dart';
import 'location_service.dart';

class EmergencyFacilitiesService {
  final LocationService _locationService;
  List<EmergencyFacility> _allFacilities = [];

  EmergencyFacilitiesService(this._locationService);

  List<EmergencyFacility> get allFacilities => _allFacilities;

  Future<void> loadFacilities() async {
    try {
      final jsonString = await rootBundle.loadString(
        AppConstants.defaultMedicalFacilitiesFile,
      );
      final List<dynamic> jsonList = json.decode(jsonString);
      _allFacilities = jsonList
          .map((json) => EmergencyFacility.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _allFacilities = [];
    }
  }

  List<EmergencyFacility> getSortedByDistance() {
    if (_locationService.currentPosition == null) {
      return _allFacilities;
    }

    return _allFacilities.map((facility) {
      final distance = _locationService.calculateDistance(
        facility.latitude,
        facility.longitude,
      );
      return facility.copyWithDistance(distance);
    }).toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  }

  List<EmergencyFacility> getNearest({int limit = 5}) {
    return getSortedByDistance().take(limit).toList();
  }

  EmergencyFacility? getNearestFacility() {
    final sorted = getSortedByDistance();
    return sorted.isNotEmpty ? sorted.first : null;
  }
}
