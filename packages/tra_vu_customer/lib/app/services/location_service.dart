import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:tra_vu_core/models/models.dart';
import 'package:tra_vu_core/models/place_model.dart';
import 'package:tra_vu_core/services/location_service_interface.dart';

/// OpenStreetMap / Nominatim implementation of [LocationServiceInterface].
///
/// Drop-in replacement for the previous Google Places-backed service.
/// To switch back to Google (or Mapbox), create a new class implementing
/// [LocationServiceInterface] and register it in place of this one.
class OsmLocationService implements LocationServiceInterface {
  static const String _searchUrl = 'https://nominatim.openstreetmap.org/search';
  static const String _reverseUrl = 'https://nominatim.openstreetmap.org/reverse';
  static const String _userAgent = 'TraVuCustomerApp/1.0 (contact@tra-vu.com)';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: {
        'User-Agent': _userAgent,
        'Accept-Language': 'en',
      },
    ),
  );

  // In-memory cache: query string → results
  final Map<String, List<Place>> _cache = {};

  // Debounce support
  Timer? _debounceTimer;
  String? _pendingQuery;

  OsmLocationService();

  // ─── LocationServiceInterface ──────────────────────────────────────────────

  @override
  Future<List<Place>> search(String query, {int limit = 5}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    if (_cache.containsKey(trimmed)) {
      return _cache[trimmed]!;
    }

    await _enforceRateLimit();

    try {
      // Do NOT use a typed generic (e.g. get<List>) with Dio 5.x —
      // it wraps the body in a cast that silently returns null when the
      // runtime type doesn't match exactly.  Cast manually instead.
      final response = await _dio.get(
        _searchUrl,
        queryParameters: {
          'q': trimmed,
          'format': 'json',
          'limit': limit,
          'addressdetails': 0,
        },
      );

      debugPrint('OsmLocationService.search[$trimmed] → status ${response.statusCode}, data type: ${response.data?.runtimeType}');

      if (response.data == null) return const [];

      final rawList = response.data is List
          ? response.data as List<dynamic>
          : <dynamic>[];

      final places = rawList
          .whereType<Map<String, dynamic>>()
          .map(_mapToPlace)
          .toList();

      debugPrint('OsmLocationService: parsed ${places.length} place(s) for "$trimmed"');
      _cache[trimmed] = places;
      return places;
    } on DioException catch (e) {
      debugPrint('OsmLocationService.search DioError [${e.type}]: ${e.message}\nResponse: ${e.response?.data}');
      return const [];
    } catch (e, st) {
      debugPrint('OsmLocationService.search unexpected error: $e\n$st');
      return const [];
    }
  }

  // Nominatim rate limit tracking across all endpoints
  static DateTime? _lastRequestTime;

  Future<void> _enforceRateLimit() async {
    final now = DateTime.now();
    if (_lastRequestTime != null) {
      final diff = now.difference(_lastRequestTime!);
      if (diff.inMilliseconds < 1200) {
        await Future.delayed(Duration(milliseconds: 1200 - diff.inMilliseconds));
      }
    }
    _lastRequestTime = DateTime.now();
  }

  @override
  Future<Place?> reverseGeocode(double lat, double lng) async {
    await _enforceRateLimit();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _reverseUrl,
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'json',
          'zoom': 18,
          'addressdetails': 0,
        },
      );

      final data = response.data;
      if (data == null) return null;
      return _mapToPlace(data);
    } on DioException catch (e) {
      debugPrint('OsmLocationService.reverseGeocode error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('OsmLocationService.reverseGeocode unexpected error: $e');
      return null;
    }
  }

  // ─── Debounced search (for use from UI text fields) ───────────────────────

  /// Debounces rapid keystrokes by 350 ms before calling [search].
  /// Pass [onResults] to receive results asynchronously.
  void searchWithDebounce(
    String query, {
    required void Function(List<Place> results) onResults,
    required void Function(bool loading) onLoading,
    Duration delay = const Duration(milliseconds: 1200),
  }) {
    _debounceTimer?.cancel();
    _pendingQuery = query.trim();

    if (_pendingQuery!.isEmpty) {
      onResults(const []);
      return;
    }

    // Return cached results immediately, no debounce needed
    if (_cache.containsKey(_pendingQuery)) {
      onResults(_cache[_pendingQuery]!);
      return;
    }

    onLoading(true);
    // Capture query by value so a later keystroke can't overwrite it
    // before the timer fires.
    final capturedQuery = _pendingQuery!;
    _debounceTimer = Timer(delay, () async {
      final results = await search(capturedQuery);
      onResults(results);
      onLoading(false);
    });
  }

  // ─── Legacy adapter helpers ───────────────────────────────────────────────

  /// Converts a [Place] to a [LocationModel] for compatibility with the
  /// existing location/job data layer used throughout the codebase.
  static LocationModel placeToLocationModel(Place place) {
    return LocationModel(
      lat: place.lat,
      lng: place.lon,
      address: place.displayName,
    );
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  Place _mapToPlace(Map<String, dynamic> json) {
    final id = json['place_id']?.toString() ??
        json['osm_id']?.toString() ??
        '${json['lat']}_${json['lon']}';

    final displayName = json['display_name']?.toString() ??
        json['name']?.toString() ??
        'Unknown location';

    final lat = double.tryParse(json['lat']?.toString() ?? '') ?? 0.0;
    final lon = double.tryParse(json['lon']?.toString() ?? '') ?? 0.0;

    return Place(
      id: id,
      displayName: displayName,
      lat: lat,
      lon: lon,
    );
  }

  void dispose() {
    _debounceTimer?.cancel();
    _dio.close();
  }
}
