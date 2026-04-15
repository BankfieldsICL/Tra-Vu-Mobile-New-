import 'shared_models.dart';
import 'user_model.dart';

class DriverModel extends BaseModel {
  final String userId;
  final DriverStatus status;
  final String? licenseNumber;
  final bool isVerified;
  final double rating;
  final UserModel? user; // Optional nested relationship

  const DriverModel({
    required super.id,
    required super.tenantId,
    required super.createdAt,
    required super.updatedAt,
    required this.userId,
    this.status = DriverStatus.offline,
    this.licenseNumber,
    this.isVerified = false,
    this.rating = 5.0,
    this.user,
  });

  factory DriverModel.fromMap(Map<String, dynamic> map) {
    return DriverModel(
      id: map['id'] as String,
      tenantId: map['tenantId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      userId: map['userId'] as String,
      status: map['status'] != null
          ? DriverStatusExtension.fromString(map['status'] as String)
          : DriverStatus.offline,
      licenseNumber: map['licenseNumber'] as String?,
      isVerified: map['isVerified'] as bool? ?? false,
      rating: double.tryParse(map['rating']?.toString() ?? '5.0') ?? 5.0,
      user: map['user'] != null
          ? UserModel.fromMap(map['user'] as Map<String, dynamic>)
          : null,
    );
  }

  factory DriverModel.fromJson(Map<String, dynamic> json) =>
      DriverModel.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      ...super.toBaseMap(),
      'userId': userId,
      'status': status.name,
      'licenseNumber': licenseNumber,
      'isVerified': isVerified,
      'rating': rating,
      if (user != null) 'user': user!.toMap(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  DriverModel copyWith({
    String? id,
    String? tenantId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    DriverStatus? status,
    String? licenseNumber,
    bool? isVerified,
    double? rating,
    UserModel? user,
  }) {
    return DriverModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      isVerified: isVerified ?? this.isVerified,
      rating: rating ?? this.rating,
      user: user ?? this.user,
    );
  }
}

class VehicleModel extends BaseModel {
  final String driverId;
  final String make;
  final String model;
  final int year;
  final String licensePlate;
  final String type; // e.g., 'standard', 'xl', 'luxury', 'moto'

  const VehicleModel({
    required super.id,
    required super.tenantId,
    required super.createdAt,
    required super.updatedAt,
    required this.driverId,
    required this.make,
    required this.model,
    required this.year,
    required this.licensePlate,
    this.type = 'standard',
  });

  factory VehicleModel.fromMap(Map<String, dynamic> map) {
    return VehicleModel(
      id: map['id'] as String,
      tenantId: map['tenantId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      driverId: map['driverId'] as String,
      make: map['make'] as String,
      model: map['model'] as String,
      year: map['year'] as int,
      licensePlate: map['licensePlate'] as String,
      type: map['type'] as String? ?? 'standard',
    );
  }

  factory VehicleModel.fromJson(Map<String, dynamic> json) =>
      VehicleModel.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      ...super.toBaseMap(),
      'driverId': driverId,
      'make': make,
      'model': model,
      'year': year,
      'licensePlate': licensePlate,
      'type': type,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  VehicleModel copyWith({
    String? id,
    String? tenantId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? driverId,
    String? make,
    String? model,
    int? year,
    String? licensePlate,
    String? type,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      driverId: driverId ?? this.driverId,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      licensePlate: licensePlate ?? this.licensePlate,
      type: type ?? this.type,
    );
  }
}
