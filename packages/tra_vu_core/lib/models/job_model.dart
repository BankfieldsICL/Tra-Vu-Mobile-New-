import 'package:tra_vu_core/models/job_status.dart';

import 'shared_models.dart';
import 'user_model.dart';
import 'driver_models.dart';

class JobModel extends BaseModel {
  final JobType type;
  final JobStatus status;
  final String? customerId;
  final UserModel? customer;
  final String? driverId;
  final DriverModel? driver;
  final String? guestEmail;
  final String? guestPhone;
  final LocationModel pickupLocation;
  final LocationModel? dropoffLocation;
  final int? estimatedPrice; // Minor units
  final int? finalPrice; // Minor units
  final String currency;
  final MatchingMode matchingMode;
  final PaymentMode paymentMode;
  final String? guestSessionId;
  final Map<String, dynamic>? packageDetails;

  const JobModel({
    required super.id,
    required super.tenantId,
    required super.createdAt,
    required super.updatedAt,
    required this.type,
    this.status = JobStatus.created,
    this.customerId,
    this.customer,
    this.driverId,
    this.driver,
    this.guestEmail,
    this.guestPhone,
    required this.pickupLocation,
    this.dropoffLocation,
    this.estimatedPrice,
    this.finalPrice,
    this.currency = 'USD',
    this.matchingMode = MatchingMode.instant,
    this.paymentMode = PaymentMode.wallet,
    this.guestSessionId,
    this.packageDetails,
  });

  factory JobModel.fromMap(Map<String, dynamic> map) {
    return JobModel(
      id: map['id'] as String,
      tenantId: map['tenantId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      type: JobTypeExtension.fromString(map['type'] as String),
      status: map['status'] != null
          ? JobStatusExtension.fromString(map['status'] as String)
          : JobStatus.created,
      customerId: map['customerId'] as String?,
      customer: map['customer'] != null
          ? UserModel.fromMap(map['customer'] as Map<String, dynamic>)
          : null,
      driverId: map['driverId'] as String?,
      driver: map['driver'] != null
          ? DriverModel.fromMap(map['driver'] as Map<String, dynamic>)
          : null,
      guestEmail: map['guestEmail'] as String?,
      guestPhone: map['guestPhone'] as String?,
      pickupLocation: LocationModel.fromMap(
        map['pickupLocation'] as Map<String, dynamic>,
      ),
      dropoffLocation: map['dropoffLocation'] != null
          ? LocationModel.fromMap(
              map['dropoffLocation'] as Map<String, dynamic>,
            )
          : null,
      estimatedPrice: map['estimatedPrice'] != null
          ? int.tryParse(map['estimatedPrice'].toString())
          : null,
      finalPrice: map['finalPrice'] != null
          ? int.tryParse(map['finalPrice'].toString())
          : null,
      currency: map['currency'] as String? ?? 'USD',
      matchingMode: map['matchingMode'] != null
          ? MatchingModeExtension.fromString(map['matchingMode'] as String)
          : MatchingMode.instant,
      paymentMode: map['paymentMode'] != null
          ? PaymentModeExtension.fromString(map['paymentMode'] as String)
          : PaymentMode.wallet,
      guestSessionId: map['guestSessionId'] as String?,
      packageDetails: map['packageDetails'] as Map<String, dynamic>?,
    );
  }

  factory JobModel.fromJson(Map<String, dynamic> json) =>
      JobModel.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      ...super.toBaseMap(),
      'type': type.name.toUpperCase(),
      'status': status.name.toUpperCase(),
      if (customerId != null) 'customerId': customerId,
      if (customer != null) 'customer': customer!.toMap(),
      if (driverId != null) 'driverId': driverId,
      if (driver != null) 'driver': driver!.toMap(),
      'guestEmail': guestEmail,
      'guestPhone': guestPhone,
      'pickupLocation': pickupLocation.toMap(),
      if (dropoffLocation != null) 'dropoffLocation': dropoffLocation!.toMap(),
      'estimatedPrice': estimatedPrice,
      'finalPrice': finalPrice,
      'currency': currency,
      'matchingMode': matchingMode.name,
      'paymentMode': paymentMode.name,
      'guestSessionId': guestSessionId,
      if (packageDetails != null) 'packageDetails': packageDetails,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  JobModel copyWith({
    String? id,
    String? tenantId,
    DateTime? createdAt,
    DateTime? updatedAt,
    JobType? type,
    JobStatus? status,
    String? customerId,
    UserModel? customer,
    String? driverId,
    DriverModel? driver,
    String? guestEmail,
    String? guestPhone,
    LocationModel? pickupLocation,
    LocationModel? dropoffLocation,
    int? estimatedPrice,
    int? finalPrice,
    String? currency,
    MatchingMode? matchingMode,
    PaymentMode? paymentMode,
    String? guestSessionId,
    Map<String, dynamic>? packageDetails,
  }) {
    return JobModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      type: type ?? this.type,
      status: status ?? this.status,
      customerId: customerId ?? this.customerId,
      customer: customer ?? this.customer,
      driverId: driverId ?? this.driverId,
      driver: driver ?? this.driver,
      guestEmail: guestEmail ?? this.guestEmail,
      guestPhone: guestPhone ?? this.guestPhone,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      finalPrice: finalPrice ?? this.finalPrice,
      currency: currency ?? this.currency,
      matchingMode: matchingMode ?? this.matchingMode,
      paymentMode: paymentMode ?? this.paymentMode,
      guestSessionId: guestSessionId ?? this.guestSessionId,
      packageDetails: packageDetails ?? this.packageDetails,
    );
  }
}
