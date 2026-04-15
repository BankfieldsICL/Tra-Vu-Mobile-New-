/// A provider-agnostic representation of a geocoded place.
///
/// Works with Nominatim (OSM), Google Places, Mapbox, or any other provider
/// that can be wrapped in a [LocationServiceInterface] implementation.
class Place {
  final String id;
  final String displayName;
  final double lat;
  final double lon;

  const Place({
    required this.id,
    required this.displayName,
    required this.lat,
    required this.lon,
  });

  @override
  String toString() => 'Place(id: $id, name: $displayName, lat: $lat, lon: $lon)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Place &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
