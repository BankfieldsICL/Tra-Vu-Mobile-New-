double amountFromMinorUnits(num? value) {
  if (value == null) {
    return 0;
  }

  return value.toDouble() / 100;
}

double parseCurrencyAmount(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is num) {
    return value > 999 ? value / 100 : value.toDouble();
  }

  final parsed = double.tryParse(
    value.toString().replaceAll(RegExp(r'[^\d.]'), ''),
  );
  if (parsed == null) {
    return 0;
  }

  return parsed > 999 ? parsed / 100 : parsed;
}

String currencyPrefix(String? currencyCode) {
  final normalized = currencyCode?.trim().toUpperCase();
  switch (normalized) {
    case 'USD':
      return '\$';
    case 'NGN':
      return '₦';
    case 'EUR':
      return '€';
    case 'GBP':
      return '£';
    case 'KES':
      return 'KSh ';
    case 'GHS':
      return 'GH₵';
    case 'ZAR':
      return 'R';
    case 'CAD':
      return 'CA\$';
    case 'AUD':
      return 'A\$';
    default:
      return normalized == null || normalized.isEmpty ? '\$' : '$normalized ';
  }
}

String formatCurrencyAmount(double amount, {String? currencyCode}) {
  return '${currencyPrefix(currencyCode)}${amount.toStringAsFixed(2)}';
}
