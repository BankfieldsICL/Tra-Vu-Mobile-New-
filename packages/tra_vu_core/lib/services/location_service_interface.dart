import 'package:tra_vu_core/models/place_model.dart';

/// Abstract contract for place-search and reverse-geocoding providers.
///
/// Implement this interface to swap between Nominatim (OSM), Google Places,
/// Mapbox, or any future search backend without touching UI code.
abstract class LocationServiceInterface {
  /// Returns up to [limit] places matching [query].
  /// Returns an empty list on error — never throws.
  Future<List<Place>> search(String query, {int limit = 5});

  /// Reverse-geocodes [lat]/[lng] to the nearest known address.
  /// Returns null if the provider cannot resolve the coordinates.
  Future<Place?> reverseGeocode(double lat, double lng);
}
