import 'package:geolocator/geolocator.dart';

import 'supabase_service.dart';

class WeatherContextRepository {
  Future<Map<String, dynamic>?> currentFromDeviceLocation() async {
    final client = SupabaseService.client;
    if (client == null || client.auth.currentUser == null) return null;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw StateError('Turn on location services to match the weather.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw StateError('Location permission is needed to match the weather.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw StateError(
        'Location permission is disabled. Enable it in Settings to match the weather.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 12),
      ),
    );
    final response = await client.functions.invoke(
      'weather-context',
      body: {'latitude': position.latitude, 'longitude': position.longitude},
    );
    final data = response.data;
    if (data is! Map) return null;
    return Map<String, dynamic>.from(data);
  }
}
