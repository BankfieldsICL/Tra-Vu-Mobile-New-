// ===========================================================================
// Tra-Vu Shared Models & Enums
// ===========================================================================

/// Base class for all models that mirror a BaseTenantEntity.
abstract class BaseModel {
  final String id;
  final String tenantId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BaseModel({
    required this.id,
    required this.tenantId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toBaseMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

// ---------------------------------------------------------------------------
// ENUMS
// ---------------------------------------------------------------------------

enum JobType { ride, carpool, delivery }

extension JobTypeExtension on JobType {
  static JobType fromString(String type) {
    return JobType.values.firstWhere(
      (e) => e.name.toLowerCase() == type.toLowerCase(),
      orElse: () => JobType.ride,
    );
  }

  String get displayName {
    switch (this) {
      case JobType.ride:
        return "Ride";
      case JobType.carpool:
        return "Carpool";
      case JobType.delivery:
        return "Delivery";
    }
  }
}

enum DriverStatus { offline, online, on_trip }

extension DriverStatusExtension on DriverStatus {
  static DriverStatus fromString(String status) {
    return DriverStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == status.toLowerCase(),
      orElse: () => DriverStatus.offline,
    );
  }

  String get displayName {
    switch (this) {
      case DriverStatus.offline:
        return "Offline";
      case DriverStatus.online:
        return "Online";
      case DriverStatus.on_trip:
        return "On Trip";
    }
  }
}

enum TripStatus { planned, active, completed, cancelled }

extension TripStatusExtension on TripStatus {
  static TripStatus fromString(String status) {
    return TripStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == status.toLowerCase(),
      orElse: () => TripStatus.planned,
    );
  }

  String get displayName {
    switch (this) {
      case TripStatus.planned:
        return "Planned";
      case TripStatus.active:
        return "Active";
      case TripStatus.completed:
        return "Completed";
      case TripStatus.cancelled:
        return "Cancelled";
    }
  }
}

enum TripMemberStatus { pending, approved, rejected, cancelled, boarded, noShow }

extension TripMemberStatusExtension on TripMemberStatus {
  static TripMemberStatus fromString(String status) {
    return TripMemberStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == status.toLowerCase(),
      orElse: () => TripMemberStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case TripMemberStatus.pending:
        return "Pending";
      case TripMemberStatus.approved:
        return "Approved";
      case TripMemberStatus.rejected:
        return "Rejected";
      case TripMemberStatus.cancelled:
        return "Cancelled";
      case TripMemberStatus.boarded:
        return "Boarded";
      case TripMemberStatus.noShow:
        return "No Show";
    }
  }
}

enum PaymentStatus {
  initialized,
  pending,
  processing,
  succeeded,
  failed,
  cancelled,
}

extension PaymentStatusExtension on PaymentStatus {
  static PaymentStatus fromString(String status) {
    return PaymentStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == status.toLowerCase(),
      orElse: () => PaymentStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case PaymentStatus.initialized:
        return "Initialized";
      case PaymentStatus.pending:
        return "Pending";
      case PaymentStatus.processing:
        return "Processing";
      case PaymentStatus.succeeded:
        return "Succeeded";
      case PaymentStatus.failed:
        return "Failed";
      case PaymentStatus.cancelled:
        return "Cancelled";
    }
  }
}

enum PaymentMode { wallet, direct }

extension PaymentModeExtension on PaymentMode {
  static PaymentMode fromString(String mode) {
    return PaymentMode.values.firstWhere(
      (e) => e.name.toLowerCase() == mode.toLowerCase(),
      orElse: () => PaymentMode.wallet,
    );
  }

  String get displayName {
    switch (this) {
      case PaymentMode.wallet:
        return "My Wallet";
      case PaymentMode.direct:
        return "Direct Payment";
    }
  }
}

enum MatchingMode { instant, negotiated }

extension MatchingModeExtension on MatchingMode {
  static MatchingMode fromString(String mode) {
    return MatchingMode.values.firstWhere(
      (e) => e.name.toLowerCase() == mode.toLowerCase(),
      orElse: () => MatchingMode.instant,
    );
  }

  String get displayName {
    switch (this) {
      case MatchingMode.instant:
        return "Instant Matching";
      case MatchingMode.negotiated:
        return "Negotiated Price";
    }
  }
}

// ---------------------------------------------------------------------------
// DATA MODELS
// ---------------------------------------------------------------------------

enum AuthStrategy { email, phone, username, google, facebook, apple }

extension AuthStrategyExtension on AuthStrategy {}

class LocationModel {
  final double lat;
  final double lng;
  final String address;

  const LocationModel({
    required this.lat,
    required this.lng,
    required this.address,
  });

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      address: map['address'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {'lat': lat, 'lng': lng, 'address': address};
  }

  LocationModel copyWith({double? lat, double? lng, String? address}) {
    return LocationModel(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      address: address ?? this.address,
    );
  }
}

class RouteModel {
  final LocationModel start;
  final LocationModel end;
  final List<LocationModel> waypoints;

  const RouteModel({
    required this.start,
    required this.end,
    this.waypoints = const [],
  });

  factory RouteModel.fromMap(Map<String, dynamic> map) {
    return RouteModel(
      start: LocationModel.fromMap(map['start'] as Map<String, dynamic>),
      end: LocationModel.fromMap(map['end'] as Map<String, dynamic>),
      waypoints: (map['waypoints'] as List? ?? [])
          .map((e) => LocationModel.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'start': start.toMap(),
      'end': end.toMap(),
      'waypoints': waypoints.map((e) => e.toMap()).toList(),
    };
  }

  RouteModel copyWith({
    LocationModel? start,
    LocationModel? end,
    List<LocationModel>? waypoints,
  }) {
    return RouteModel(
      start: start ?? this.start,
      end: end ?? this.end,
      waypoints: waypoints ?? this.waypoints,
    );
  }
}
