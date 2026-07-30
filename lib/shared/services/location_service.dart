import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService extends ChangeNotifier {
  Position? _currentPosition;
  bool _isLoading = false;
  String _error = '';

  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get hasLocation => _currentPosition != null;

  Future<Position?> getCurrentLocation() async {
    if (_isLoading) return _currentPosition;

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error = 'Location services are disabled';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Location permission denied';
          _isLoading = false;
          notifyListeners();
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error = 'Location permission permanently denied';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _isLoading = false;
      notifyListeners();

      return _currentPosition;
    } catch (e) {
      debugPrint('[ResQ] LocationService error: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  double calculateDistance(double lat, double lon) {
    if (_currentPosition == null) return double.infinity;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lon,
    ) / 1000;
  }
}
