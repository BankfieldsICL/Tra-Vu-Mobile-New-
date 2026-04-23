import 'package:intl/intl.dart';

class AmountFormatter {
  AmountFormatter._();

  static final NumberFormat _groupedDecimal = NumberFormat('#,##0.00');

  static String decimal(num amount) {
    return _groupedDecimal.format(amount);
  }

  static String withCurrencyCode(num amount, String currency) {
    return '${currency.toUpperCase()} ${decimal(amount)}';
  }

  static String withCurrencySymbol(num amount, String currency) {
    final normalizedCurrency = currency.toUpperCase();
    final symbol = switch (normalizedCurrency) {
      'NGN' => '₦',
      'USD' => '\$',
      _ => normalizedCurrency,
    };

    if (symbol == normalizedCurrency) {
      return '$symbol ${decimal(amount)}';
    }

    return '$symbol${decimal(amount)}';
  }
}
