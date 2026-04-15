import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../models/models.dart';
import '../models/job_status.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

class DriverApi extends GetxService {
  late final Dio _dio;
  final ApiClient _apiClient = Get.find<ApiClient>();

  DriverApi() {
    _dio = _apiClient.dio;
  }

  // --- USERS ---
  Future<UserModel> getProfile() async {
    final response = await _dio.get(ApiEndpoints.userProfile);
    final body = response.data as Map<String, dynamic>;
    final payload = body['data'];
    final source = payload is Map<String, dynamic> ? payload : body;
    final profile = source['profile'];
    return UserModel.fromMap(
      profile is Map<String, dynamic> ? profile : source,
    );
  }

  Future<UserModel> updateMyProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
  }) async {
    final data = {
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (email != null) 'email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
    };

    bool exists = false;
    try {
      await getProfile();
      exists = true;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        exists = false;
      } else {
        rethrow;
      }
    }

    if (exists) {
      final response = await _dio.patch(ApiEndpoints.userProfile, data: data);
      return _parseUserResponse(response.data as Map<String, dynamic>);
    } else {
      final userId = Get.find<AuthService>().currentUserId.value;
      final postData = {
        ...data,
        if (userId != null) 'authUid': userId,
      };
      final response = await _dio.post(ApiEndpoints.users, data: postData);
      return _parseUserResponse(response.data as Map<String, dynamic>);
    }
  }

  UserModel _parseUserResponse(Map<String, dynamic> body) {
    final payload = body['data'];
    final source = payload is Map<String, dynamic> ? payload : body;
    final profile = source['profile'];
    return UserModel.fromMap(
      profile is Map<String, dynamic> ? profile : source,
    );
  }

  // --- DRIVERS ---
  Future<DriverModel> createDriverProfile({
    required String userId,
    String? licenseNumber,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.drivers,
      data: {
        'userId': userId,
        if (licenseNumber != null) 'licenseNumber': licenseNumber,
      },
    );
    return _parseDriverResponse(response.data as Map<String, dynamic>);
  }

  Future<DriverModel?> getMyDriverProfile() async {
    try {
      final response = await _dio.get(ApiEndpoints.driverProfile);
      debugPrint('[Driver API] drivers/me response: ${response.data}');
      return _parseDriverResponse(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      debugPrint(
        '[Driver API] drivers/me error: ${error.response?.statusCode} ${error.response?.data}',
      );
      if (error.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<List<DriverModel>> getDrivers() async {
    final response = await _dio.get(ApiEndpoints.drivers);
    final List list = _extractList(response.data);
    return list
        .map((e) => DriverModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<DriverModel> getDriver(String id) async {
    final response = await _dio.get(ApiEndpoints.driver(id));
    return _parseDriverResponse(response.data as Map<String, dynamic>);
  }

  Future<DriverModel> updateDriverStatus(String id, DriverStatus status) async {
    final response = await _dio.patch(
      ApiEndpoints.driverStatus(id),
      data: {'status': status.name.toLowerCase()},
    );
    return _parseDriverResponse(response.data as Map<String, dynamic>);
  }

  // --- VEHICLES ---
  Future<VehicleModel> createVehicle({
    required String driverId,
    required String make,
    required String model,
    required int year,
    required String licensePlate,
    String type = 'standard',
  }) async {
    final response = await _dio.post(
      ApiEndpoints.vehicles,
      data: {
        'driverId': driverId,
        'make': make,
        'model': model,
        'year': year,
        'licensePlate': licensePlate,
        'type': type,
      },
    );
    return _parseVehicleResponse(response.data as Map<String, dynamic>);
  }

  Future<List<VehicleModel>> getVehicles() async {
    final response = await _dio.get(ApiEndpoints.vehicles);
    final List list = _extractList(response.data);
    return list
        .map((e) => VehicleModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<VehicleModel>> getVehiclesByDriver(String driverId) async {
    final response = await _dio.get(
      ApiEndpoints.vehiclesByDriver,
      queryParameters: {'driverId': driverId},
    );
    final List list = _extractList(response.data);
    return list
        .map((e) => VehicleModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  DriverModel _parseDriverResponse(Map<String, dynamic> body) {
    final source = _extractEntityMap(body, ['driver']);
    return DriverModel.fromMap(source);
  }

  JobModel _parseJobResponse(Map<String, dynamic> body) {
    final source = _extractEntityMap(body, ['job', 'delivery', 'ride', 'carpool']);
    return JobModel.fromMap(source);
  }

  TripModel _parseTripResponse(Map<String, dynamic> body) {
    final source = _extractEntityMap(body, ['trip']);
    return TripModel.fromMap(source);
  }

  TripMemberModel _parseTripMemberResponse(Map<String, dynamic> body) {
    final source = _extractEntityMap(body, ['member', 'tripMember']);
    return TripMemberModel.fromMap(source);
  }

  VehicleModel _parseVehicleResponse(Map<String, dynamic> body) {
    final source = _extractEntityMap(body, ['vehicle']);
    return VehicleModel.fromMap(source);
  }

  Map<String, dynamic> _extractEntityMap(
    Map<String, dynamic> body,
    List<String> nestedKeys,
  ) {
    final payload = body['data'];
    final source = payload is Map<String, dynamic> ? payload : body;

    for (final key in nestedKeys) {
      final nested = source[key];
      if (nested is Map<String, dynamic>) {
        return nested;
      }
    }

    return source;
  }

  List _extractList(dynamic rawData) {
    if (rawData is List) {
      return rawData;
    }

    if (rawData is Map<String, dynamic>) {
      final data = rawData['data'];
      if (data is List) {
        return data;
      }
      if (data is Map<String, dynamic>) {
        final candidates = [data['items'], data['results'], data['drivers'], data['vehicles']];
        for (final candidate in candidates) {
          if (candidate is List) {
            return candidate;
          }
        }
      }

      final directCandidates = [rawData['items'], rawData['results'], rawData['drivers'], rawData['vehicles']];
      for (final candidate in directCandidates) {
        if (candidate is List) {
          return candidate;
        }
      }
    }

    return const [];
  }

  Future<void> removeVehicle(String id) async {
    await _dio.delete(ApiEndpoints.vehicle(id));
  }

  // --- JOBS ---
  Future<List<JobModel>> getJobs() async {
    final response = await _dio.get(ApiEndpoints.jobs);
    final List list = _extractList(response.data);
    return list
        .map((e) => JobModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<JobModel> getJob(String id) async {
    final response = await _dio.get(ApiEndpoints.job(id));
    debugPrint('[Driver API] Fetched job details: ${response.data}');
    return _parseJobResponse(response.data as Map<String, dynamic>);
  }

  Future<JobModel> updateJobStatus(String id, JobStatus status) async {
    final response = await _dio.patch(
      ApiEndpoints.jobStatus(id),
      data: {'status': status.name.toUpperCase()},
    );
    return _parseJobResponse(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> submitBid(String jobId, int amount) async {
    final response = await _dio.post(
      ApiEndpoints.jobBid(jobId),
      data: {'amount': amount},
    );
    return response.data as Map<String, dynamic>;
  }

  // --- TRIPS ---
  Future<List<TripModel>> getMyTrips() async {
    final response = await _dio.get(ApiEndpoints.trips);
    final List list = _extractList(response.data);
    return list
        .map((e) => TripModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<TripModel> createTrip({
    required int totalSeats,
    required DateTime departureTime,
    required RouteModel route,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.trips,
      data: {
        'totalSeats': totalSeats,
        'departureTime': departureTime.toIso8601String(),
        'route': route.toMap(),
      },
    );
    return _parseTripResponse(response.data as Map<String, dynamic>);
  }

  Future<List<TripMemberModel>> getTripMembers(String tripId) async {
    final response = await _dio.get('${ApiEndpoints.trips}/$tripId/members');
    final List list = _extractList(response.data);
    return list.map((e) {
      final map = e as Map<String, dynamic>;
      final unwrapped = _extractEntityMap(map, ['member', 'tripMember']);
      return TripMemberModel.fromMap(unwrapped);
    }).toList();
  }

  Future<TripMemberModel> approveTripMember(String memberId) async {
    final response = await _dio.patch(ApiEndpoints.tripApproveMember(memberId));
    return _parseTripMemberResponse(response.data as Map<String, dynamic>);
  }

  Future<TripMemberModel> rejectTripMember(String memberId) async {
    final response = await _dio.patch(ApiEndpoints.tripRejectMember(memberId));
    return _parseTripMemberResponse(response.data as Map<String, dynamic>);
  }

  Future<TripMemberModel> boardTripMember(String memberId, String otp) async {
    final response = await _dio.patch(
      ApiEndpoints.tripBoardMember(memberId),
      data: {'otp': otp},
    );
    return _parseTripMemberResponse(response.data as Map<String, dynamic>);
  }

  Future<TripMemberModel> markTripMemberNoShow(String memberId) async {
    final response = await _dio.patch(ApiEndpoints.tripNoShowMember(memberId));
    return _parseTripMemberResponse(response.data as Map<String, dynamic>);
  }

  // --- PAYMENTS ---
  Future<Map<String, dynamic>> getBalance(
    String userId, {
    String currency = 'USD',
  }) async {
    final response = await _dio.get(
      ApiEndpoints.paymentBalance(userId),
      queryParameters: {'currency': currency},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<PaymentIntentModel>> getPaymentHistory(
    String userId, {
    String currency = 'USD',
  }) async {
    final response = await _dio.get(
      ApiEndpoints.paymentHistory(userId),
      queryParameters: {'currency': currency},
    );
    final List list = _extractList(response.data);
    return list
        .map((e) => PaymentIntentModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
