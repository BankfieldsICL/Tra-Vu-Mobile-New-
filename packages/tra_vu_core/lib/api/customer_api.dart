import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

class CustomerApi extends GetxService {
  late final Dio _dio;
  final ApiClient _apiClient = Get.find<ApiClient>();

  CustomerApi() {
    _dio = _apiClient.dio;
  }

  // --- BUSINESSES ---
  // Future<Map<String, dynamic>> registerBusiness({
  //   required String name,
  //   String? webhookUrl,
  //   String? plan,
  // }) async {
  //   final response = await _dio.post(ApiEndpoints.businesses, data: {
  //     'name': name,
  //     if (webhookUrl != null) 'webhookUrl': webhookUrl,
  //     if (plan != null) 'plan': plan,
  //   });
  //   return response.data as Map<String, dynamic>;
  // }

  // Future<Map<String, dynamic>> getBusinessProfile({required String apiKey}) async {
  //   final response = await _dio.get(
  //     ApiEndpoints.businessProfile,
  //     options: Options(headers: {'x-api-key': apiKey}),
  //   );
  //   return response.data as Map<String, dynamic>;
  // }

  // --- USERS ---
  Future<UserModel> getProfile() async {
    final response = await _dio.get(ApiEndpoints.userProfile);
    return UserModel.fromMap(_extractEntityMap(response.data, 'profile')!);
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.patch(ApiEndpoints.userProfile, data: data);
    return UserModel.fromMap(_extractEntityMap(response.data, 'profile') ?? _extractEntityMap(response.data)!);
  }

  // --- JOBS ---
  Future<JobModel> createJob({
    required JobType type,
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffAddress,
    int? estimatedPrice, // in minor units
    Map<String, dynamic>? packageDetails,
    MatchingMode matchingMode = MatchingMode.instant,
    String currency = 'USD',
    PaymentMode paymentMode = PaymentMode.wallet,
    String? guestEmail,
    String? guestPhone,
    String? guestSessionId,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.jobs,
      data: {
        'type': type.name,
        'pickupLocation': {
          'lat': pickupLat,
          'lng': pickupLng,
          'address': pickupAddress,
        },
        'dropoffLocation': {
          'lat': dropoffLat,
          'lng': dropoffLng,
          'address': dropoffAddress,
        },
        if (estimatedPrice != null) 'estimatedPrice': estimatedPrice,
        if (packageDetails != null) 'packageDetails': packageDetails,
        'matchingMode': matchingMode.name,
        'currency': currency,
        'paymentMode': paymentMode.name,
        if (guestEmail != null) 'guestEmail': guestEmail,
        if (guestPhone != null) 'guestPhone': guestPhone,
        if (guestSessionId != null) 'guestSessionId': guestSessionId,
      },
    );
    final data = _extractEntityMap(response.data);
    return JobModel.fromMap(data!);
  }

  Future<List<JobModel>> getJobs() async {
    final response = await _dio.get(ApiEndpoints.jobs);
    final body = response.data as Map<String, dynamic>;
    final data = body['data'];
    final List list = data is List ? data : (body['jobs'] as List? ?? []);
    return list
        .map((e) => JobModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<JobModel> getJob(String id) async {
    final response = await _dio.get(ApiEndpoints.job(id));
    return JobModel.fromMap(_extractEntityMap(response.data)!);
  }

  Future<JobModel> cancelJob(String id) async {
    final response = await _dio.post(ApiEndpoints.jobCancel(id));
    return JobModel.fromMap(_extractEntityMap(response.data)!);
  }

  Future<JobModel> acceptBid(String jobId, String bidId) async {
    final response = await _dio.post(ApiEndpoints.jobAcceptBid(jobId, bidId));
    return JobModel.fromMap(_extractEntityMap(response.data)!);
  }

  // --- TRIPS ---
  Future<List<TripModel>> searchTrips({
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    String? pickupAddress,
    String? dropoffAddress,
    double? radiusKm,
  }) async {
    final queryParams = <String, dynamic>{};
    if (pickupLat != null) queryParams['pickupLat'] = pickupLat;
    if (pickupLng != null) queryParams['pickupLng'] = pickupLng;
    if (dropoffLat != null) queryParams['dropoffLat'] = dropoffLat;
    if (dropoffLng != null) queryParams['dropoffLng'] = dropoffLng;
    if (pickupAddress != null) queryParams['pickupAddress'] = pickupAddress;
    if (dropoffAddress != null) queryParams['dropoffAddress'] = dropoffAddress;
    if (radiusKm != null) queryParams['radiusKm'] = radiusKm;

    final response = await _dio.get(
      ApiEndpoints.trips,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    // Safely unwrap the response — could be a bare List or {data: [...]}
    final raw = response.data;
    final List list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map) {
      final data = raw['data'];
      list = data is List ? data : [];
    } else {
      list = [];
    }

    return list
        .whereType<Map>()
        .map((e) => TripModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<TripMemberModel> requestToJoinTrip(
    String tripId,
    int seatsRequested,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.tripJoin(tripId),
      data: {'seatsRequested': seatsRequested},
    );
    return TripMemberModel.fromMap(_extractEntityMap(response.data)!);
  }

  Future<List<TripMemberModel>> getMyTripMemberships() async {
    try {
      final response = await _dio.get('${ApiEndpoints.trips}/members/me');

      final raw = response.data;
      final List list;
      if (raw is List) {
        list = raw;
      } else if (raw is Map) {
        final data = raw['data'];
        list = data is List ? data : [];
      } else {
        list = [];
      }

      return list
          .whereType<Map>()
          .map((e) => TripMemberModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return []; // Backend returns 404 when no memberships exist
      }
      rethrow;
    }
  }

  // --- PAYMENTS & PRICING ---
  Future<PaymentLinkModel> initializePayment({
    required int amount,
    required String currency,
    required String provider,
    required PaymentMode paymentMode,
    required String referenceType,
    required String referenceId,
    String? guestContact,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.paymentInitialize,
      data: {
        'amount': amount,
        'currency': currency,
        'provider': provider,
        'paymentMode': paymentMode.name,
        'referenceType': referenceType,
        'referenceId': referenceId,
        if (guestContact != null) 'guestContact': guestContact,
        if (metadata != null) 'metadata': metadata,
      },
    );
    return PaymentLinkModel.fromMap(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getBalance(
    String userId, {
    String currency = 'USD',
  }) async {
    final response = await _dio.get(
      ApiEndpoints.paymentBalance(userId),
      queryParameters: {'currency': currency},
    );
    print('Balance response: ${response.data}');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<List<TransactionModel>> getPaymentHistory(
    String userId, {
    String currency = 'USD',
  }) async {
    final response = await _dio.get(
      ApiEndpoints.paymentHistory(userId),
      queryParameters: {'currency': currency},
    );
    final List list = response.data['data'] as List;
    print('Payment history response: $list');
    return list
        .map((e) => TransactionModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<PricingRuleModel> getActivePricingRules({
    String currency = 'USD',
  }) async {
    final response = await _dio.get(
      ApiEndpoints.pricingRules,
      queryParameters: {'currency': currency},
    );
    return PricingRuleModel.fromMap(response.data as Map<String, dynamic>);
  }

  // --- TRACKING ---
  Future<Map<String, dynamic>> getLastLocation(String jobId) async {
    final response = await _dio.get(ApiEndpoints.trackingLocation(jobId));
    return response.data as Map<String, dynamic>;
  }

  // --- HELPERS ---

  Map<String, dynamic>? _extractEntityMap(dynamic body, [String? entityKey]) {
    if (body == null) return null;
    final Map<String, dynamic> map = body is Map<String, dynamic> ? body : {};

    // 1. Try to extract from 'data' wrapper
    final data = map['data'];
    if (data is Map<String, dynamic>) {
      if (entityKey != null && data.containsKey(entityKey)) {
        return data[entityKey] as Map<String, dynamic>;
      }
      return data;
    }

    // 2. Try identifying by key
    if (entityKey != null && map.containsKey(entityKey)) {
      return map[entityKey] as Map<String, dynamic>;
    }

    // 3. Fallback to the body itself
    return map;
  }
}
