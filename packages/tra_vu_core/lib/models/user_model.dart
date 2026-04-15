import 'shared_models.dart';

class UserModel extends BaseModel {
  final String firstName;
  final String lastName;
  final String? email;
  final String? phoneNumber;
  final bool isEmailVerified;
  final String? authUid;
  final double rating;

  const UserModel({
    required super.id,
    required super.tenantId,
    required super.createdAt,
    required super.updatedAt,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phoneNumber,
    this.isEmailVerified = false,
    this.authUid,
    this.rating = 5.0,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      tenantId: map['tenantId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      email: map['email'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      isEmailVerified: map['isEmailVerified'] as bool? ?? false,
      authUid: map['authUid'] as String?,
      rating: double.tryParse(map['rating']?.toString() ?? '5.0') ?? 5.0,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      UserModel.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      ...super.toBaseMap(),
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'isEmailVerified': isEmailVerified,
      'authUid': authUid,
      'rating': rating,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  UserModel copyWith({
    String? id,
    String? tenantId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    bool? isEmailVerified,
    String? authUid,
    double? rating,
  }) {
    return UserModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      authUid: authUid ?? this.authUid,
      rating: rating ?? this.rating,
    );
  }
}
