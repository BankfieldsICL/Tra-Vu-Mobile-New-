import 'shared_models.dart';
import 'user_model.dart';
import 'driver_models.dart';

class TripModel extends BaseModel {
  final String driverId;
  final DriverModel? driver;
  final int totalSeats;
  final int availableSeats;
  final TripStatus status;
  final DateTime departureTime;
  final RouteModel route;

  const TripModel({
    required super.id,
    required super.tenantId,
    required super.createdAt,
    required super.updatedAt,
    required this.driverId,
    this.driver,
    required this.totalSeats,
    required this.availableSeats,
    this.status = TripStatus.planned,
    required this.departureTime,
    required this.route,
  });

  factory TripModel.fromMap(Map<String, dynamic> map) {
    return TripModel(
      id: map['id'] as String,
      tenantId: map['tenantId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      driverId: map['driverId'] as String,
      driver: map['driver'] != null
          ? DriverModel.fromMap(map['driver'] as Map<String, dynamic>)
          : null,
      totalSeats: map['totalSeats'] as int,
      availableSeats: map['availableSeats'] as int,
      status: map['status'] != null
          ? TripStatusExtension.fromString(map['status'] as String)
          : TripStatus.planned,
      departureTime: DateTime.parse(map['departureTime'] as String),
      route: RouteModel.fromMap(map['route'] as Map<String, dynamic>),
    );
  }

  factory TripModel.fromJson(Map<String, dynamic> json) =>
      TripModel.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      ...super.toBaseMap(),
      'driverId': driverId,
      if (driver != null) 'driver': driver!.toMap(),
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'status': status.name.toUpperCase(),
      'departureTime': departureTime.toIso8601String(),
      'route': route.toMap(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  TripModel copyWith({
    String? id,
    String? tenantId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? driverId,
    DriverModel? driver,
    int? totalSeats,
    int? availableSeats,
    TripStatus? status,
    DateTime? departureTime,
    RouteModel? route,
  }) {
    return TripModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      driverId: driverId ?? this.driverId,
      driver: driver ?? this.driver,
      totalSeats: totalSeats ?? this.totalSeats,
      availableSeats: availableSeats ?? this.availableSeats,
      status: status ?? this.status,
      departureTime: departureTime ?? this.departureTime,
      route: route ?? this.route,
    );
  }
}

class TripMemberModel extends BaseModel {
  final String tripId;
  final TripModel? trip;
  final String userId;
  final UserModel? user;
  final int seatsRequested;
  final TripMemberStatus status;
  final String? boardingOtp;

  const TripMemberModel({
    required super.id,
    required super.tenantId,
    required super.createdAt,
    required super.updatedAt,
    required this.tripId,
    this.trip,
    required this.userId,
    this.user,
    required this.seatsRequested,
    this.status = TripMemberStatus.pending,
    this.boardingOtp,
  });

  factory TripMemberModel.fromMap(Map<String, dynamic> map) {
    return TripMemberModel(
      id: map['id'] as String,
      tenantId: map['tenantId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      tripId: map['tripId'] as String,
      trip: map['trip'] != null
          ? TripModel.fromMap(map['trip'] as Map<String, dynamic>)
          : null,
      userId: map['userId'] as String,
      user: map['user'] != null
          ? UserModel.fromMap(map['user'] as Map<String, dynamic>)
          : null,
      seatsRequested: map['seatsRequested'] as int,
      status: map['status'] != null
          ? TripMemberStatusExtension.fromString(map['status'] as String)
          : TripMemberStatus.pending,
      boardingOtp: map['boardingOtp'] as String?,
    );
  }

  factory TripMemberModel.fromJson(Map<String, dynamic> json) =>
      TripMemberModel.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      ...super.toBaseMap(),
      'tripId': tripId,
      if (trip != null) 'trip': trip!.toMap(),
      'userId': userId,
      if (user != null) 'user': user!.toMap(),
      'seatsRequested': seatsRequested,
      'status': status.name,
      if (boardingOtp != null) 'boardingOtp': boardingOtp,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  TripMemberModel copyWith({
    String? id,
    String? tenantId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? tripId,
    TripModel? trip,
    String? userId,
    UserModel? user,
    int? seatsRequested,
    TripMemberStatus? status,
    String? boardingOtp,
  }) {
    return TripMemberModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tripId: tripId ?? this.tripId,
      trip: trip ?? this.trip,
      userId: userId ?? this.userId,
      user: user ?? this.user,
      seatsRequested: seatsRequested ?? this.seatsRequested,
      status: status ?? this.status,
      boardingOtp: boardingOtp ?? this.boardingOtp,
    );
  }
}
