import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tra_vu_core/tra_vu_core.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/amount_formatter.dart';
import 'payment_webview.dart';

class WalletController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final CustomerApi _customerApi = Get.find<CustomerApi>();

  final RxDouble activeBaseUsd = 0.0.obs;
  final RxDouble activeLocalCurrency = 0.0.obs;
  final RxString localCurrencySymbol = '₦'.obs;
  final RxString baseCurrencyCode = 'USD'.obs;
  final RxString localCurrencyCode = 'NGN'.obs;
  final RxBool isLoading = true.obs;
  final RxnString loadError = RxnString();
  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;

  bool get _hasBaseBalance => activeBaseUsd.value != 0;
  bool get _hasLocalBalance => activeLocalCurrency.value != 0;

  bool get _showBaseAsPrimary => _hasBaseBalance || !_hasLocalBalance;

  double get primaryBalanceAmount =>
      _showBaseAsPrimary ? activeBaseUsd.value : activeLocalCurrency.value;

  String get primaryBalanceCurrencyCode =>
      _showBaseAsPrimary ? baseCurrencyCode.value : localCurrencyCode.value;

  String get primaryBalanceSymbol =>
      _currencySymbol(primaryBalanceCurrencyCode);

  double get secondaryBalanceAmount =>
      _showBaseAsPrimary ? activeLocalCurrency.value : activeBaseUsd.value;

  String get secondaryBalanceCurrencyCode =>
      _showBaseAsPrimary ? localCurrencyCode.value : baseCurrencyCode.value;

  String get secondaryBalanceSymbol =>
      _currencySymbol(secondaryBalanceCurrencyCode);

  String get formattedPrimaryBalance =>
      formatMajorAmount(primaryBalanceAmount, primaryBalanceCurrencyCode);

  String get formattedSecondaryBalance =>
      formatMajorAmount(secondaryBalanceAmount, secondaryBalanceCurrencyCode);

  @override
  void onInit() {
    super.onInit();
    loadWalletData();
  }

  Future<void> loadWalletData() async {
    isLoading.value = true;
    loadError.value = null;

    try {
      final userId = _authService.currentUserId.value;
      if (userId == null || userId.isEmpty) {
        throw StateError('No signed-in customer was found.');
      }

      final responses = await Future.wait([
        _customerApi.getBalance(userId, currency: 'USD'),
        _customerApi.getBalance(userId, currency: 'NGN'),
        _customerApi.getPaymentHistory(userId, currency: 'NGN'),
      ]);

      _applyBalanceResponse(responses[0], isBaseCurrency: true);
      _applyBalanceResponse(responses[1], isBaseCurrency: false);
      _applyHistoryResponse(responses[2] as List<TransactionModel>);
    } catch (error) {
      loadError.value = _readableErrorMessage(
        error,
        fallback: 'We could not load your wallet right now.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fundWallet(double amountMajor) async {
    final userId = _authService.currentUserId.value;
    if (userId == null || userId.isEmpty) {
      Get.snackbar('Error', 'You must be signed in to fund your wallet.');
      return;
    }

    final amount = (amountMajor).round();

    try {
      // Show loading overlay
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final intent = await _customerApi.initializePayment(
        amount: amount,
        currency: 'NGN',
        provider: 'paystack',
        paymentMode: PaymentMode.direct,
        referenceType: 'FUNDING',
        referenceId: userId,
      );

      debugPrint('Payment intent created: ${intent.toMap()}');

      Get.back(); // Dismiss loading overlay

      if (intent.paymentLink != null) {
        await Get.to(
          () => PaymentWebView(
            url: intent.paymentLink,
            title: 'Fund Wallet',
            onPageFinished: (url) {
              // Simple heuristic: if the URL contains keywords, we can auto-close
              // or notify the user. Usually the backend redirect URL is known.
              if (url.contains('success') ||
                  url.contains('verify') ||
                  url.contains('done')) {
                // In a real app, we'd wait a bit or show a success button
                Get.back();
              }
            },
            onNavigationRequest: (request) {
              // Here we can intercept specific URLs if needed
              debugPrint('Navigating to: ${request.url}');
              final url = request.url;

              debugPrint("Navigating to: $url");

              // Example: your backend callback URL
              if (url.contains("payment-landing")) {
                // You can also parse query params here if needed

                Future.microtask(() {
                  Get.back(result: {"status": "success", "url": url});
                });

                return NavigationDecision.prevent;
              }

              if (url.contains("payment-failed")) {
                Future.microtask(() {
                  Get.back(result: {"status": "failed", "url": url});
                });

                return NavigationDecision.prevent;
              }
            },
          ),
        );

        // Refresh wallet after returning from WebView
        loadWalletData();
      } else {
        Get.snackbar('Error', 'Could not initialize payment redirect.');
      }
    } catch (e) {
      Get.back(); // Dismiss loading overlay if still showing
      debugPrint('Error during wallet funding: $e');
      Get.snackbar(
        'Error',
        _readableErrorMessage(e, fallback: 'Payment failed'),
      );
    }
  }

  void _applyBalanceResponse(dynamic rawData, {required bool isBaseCurrency}) {
    final payload = _unwrapObject(rawData);
    if (payload == null) {
      return;
    }

    final amountMajor = _readBalanceAmount(
      payload['availableBalance'] ??
          payload['balance'] ??
          payload['amount'] ??
          payload['available'],
    ).toDouble();
    final currency =
        (payload['currency']?.toString() ?? (isBaseCurrency ? 'USD' : 'NGN'))
            .toUpperCase();
    // final amountMajor = amountMinor / 1;

    if (isBaseCurrency) {
      activeBaseUsd.value = amountMajor;
      baseCurrencyCode.value = currency;
    } else {
      activeLocalCurrency.value = amountMajor;
      localCurrencyCode.value = currency;
      localCurrencySymbol.value = _currencySymbol(currency);
    }
  }

  void _applyHistoryResponse(List<TransactionModel> rawData) {
    transactions.assignAll(rawData);
  }

  Map<String, dynamic>? _unwrapObject(dynamic rawData) {
    if (rawData is Map<String, dynamic>) {
      final data = rawData['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return rawData;
    }
    return null;
  }

  List<dynamic> _unwrapCollection(dynamic rawData) {
    if (rawData is List) {
      return rawData;
    }

    if (rawData is Map<String, dynamic>) {
      final data = rawData['data'];
      if (data is List) {
        return data;
      }

      if (data is Map<String, dynamic>) {
        final items = data['items'] ?? data['history'] ?? data['results'];
        if (items is List) {
          return items;
        }
      }
    }

    return const [];
  }

  int _readBalanceAmount(dynamic rawAmount) {
    if (rawAmount == null) {
      return 0;
    }

    if (rawAmount is int) {
      return rawAmount;
    }

    if (rawAmount is double) {
      return rawAmount.round();
    }

    return int.tryParse(rawAmount.toString()) ?? 0;
  }

  String formatMajorAmount(double amount, String currency) {
    return AmountFormatter.decimal(amount);
  }

  String formatMinorAmount(int amountMinor, String currency) {
    return AmountFormatter.decimal(amountMinor / 100);
  }

  String _formatSignedAmount({
    required int amountMinor,
    required String currency,
    required bool isCredit,
  }) {
    final major = formatMinorAmount(amountMinor.abs(), currency);
    final sign = isCredit ? '+' : '-';
    return '$sign$major';
  }

  String _titleForReferenceType(String referenceType) {
    switch (referenceType.toUpperCase()) {
      case 'JOB':
        return 'Trip or delivery payment';
      case 'FUNDING':
        return 'Wallet top-up';
      default:
        return referenceType
            .replaceAll('_', ' ')
            .toLowerCase()
            .split(' ')
            .map(
              (word) => word.isEmpty
                  ? word
                  : '${word[0].toUpperCase()}${word.substring(1)}',
            )
            .join(' ');
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  String _currencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'NGN':
        return '₦';
      case 'USD':
        return '\$';
      default:
        return currency.toUpperCase();
    }
  }

  String _readableErrorMessage(Object error, {required String fallback}) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'] ?? data['error'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }

      final dioMessage = error.message?.trim();
      if (dioMessage != null && dioMessage.isNotEmpty) {
        return dioMessage;
      }
    }

    return fallback;
  }
}
