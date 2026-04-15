// ===========================================================================
// Tra-Vu API Endpoints Constants
// ===========================================================================
// This file contains all the endpoint paths used by the Tra-Vu Flutter client.
// Prepend with the base URL and version prefix (default /v1).
// ===========================================================================

import 'package:tra_vu_core/config/api_config.dart';

class ApiEndpoints {
  // Base versioning
  static const String version = ApiConfig.version;

  // Auth (Automatically mounted under /auth)
  static const String authSignup = '$version/auth/signup';
  static const String authSignin = '$version/auth/signin';
  static const String authVerify = '$version/auth/verify';
  static const String authResend = '$version/auth/resend-verification';
  static const String authRefresh = '$version/auth/refresh';
  static const String authLogout = '$version/auth/logout';
  static const String authMe = '$version/auth/me';

  // Businesses
  static const String businesses = '$version/businesses';
  static const String businessProfile = '$version/businesses/me';

  // Users
  static const String users = '$version/users';
  static const String userProfile = '$version/users/me';
  static String user(String id) => '$version/users/$id';

  // Drivers
  static const String drivers = '$version/drivers';
  static const String driverProfile = '$version/drivers/me';
  static String driver(String id) => '$version/drivers/$id';
  static String driverStatus(String id) => '$version/drivers/$id/status';

  // Vehicles
  static const String vehicles = '$version/vehicles';
  static const String vehiclesByDriver = '$version/vehicles/by-driver';
  static String vehicle(String id) => '$version/vehicles/$id';

  // Jobs
  static const String jobs = '$version/jobs';
  static String job(String id) => '$version/jobs/$id';
  static String jobStatus(String id) => '$version/jobs/$id/status';
  static String jobCancel(String id) => '$version/jobs/$id/cancel';
  static String jobBid(String id) => '$version/jobs/$id/bid';
  static String jobAcceptBid(String jobId, String bidId) =>
      '$version/jobs/$jobId/bid/$bidId/accept';

  // Trips (Carpooling)
  static const String trips = '$version/trips';
  static String tripJoin(String id) => '$version/trips/$id/join';
  static String tripApproveMember(String memberId) =>
      '$version/trips/members/$memberId/approve';
  static String tripRejectMember(String memberId) =>
      '$version/trips/members/$memberId/reject';
  static String tripBoardMember(String memberId) =>
      '$version/trips/members/$memberId/board';
  static String tripNoShowMember(String memberId) =>
      '$version/trips/members/$memberId/no-show';

  // Tracking
  static String trackingLocation(String jobId) =>
      '$version/tracking/$jobId/location';
  static const String trackingNamespace = '/tracking';

  // Payments
  static const String paymentInitialize = '$version/payments/initialize';
  static String paymentBalance(String userId) =>
      '$version/payments/balance/$userId';
  static String paymentHistory(String userId) =>
      '$version/payments/history/$userId';

  // Pricing
  static const String pricingRules = '$version/pricing/rules';
}
