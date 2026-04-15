import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/currency_format.dart';

class TripSummaryView extends StatelessWidget {
  const TripSummaryView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final currencyCode = args['currency']?.toString();
    final grossEarnings = parseCurrencyAmount(args['earnings']);
    final platformFee = grossEarnings * 0.1;
    final netPayout = grossEarnings - platformFee;
    final jobId = args['jobId']?.toString() ?? 'N/A';
    final pickupAddress =
        args['pickupAddress']?.toString() ?? 'Pickup not available';
    final dropoffAddress =
        args['dropoffAddress']?.toString() ?? 'Dropoff not available';
    final customerName = args['customerName']?.toString() ?? 'Customer';

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      const Center(
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.greenAccent,
                          child: Icon(
                            Icons.check,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Center(
                        child: Text(
                          'Trip Complete!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Job #$jobId for $customerName',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Your Earnings',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _formatCurrency(
                                  grossEarnings,
                                  currencyCode: currencyCode,
                                ),
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 52,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Divider(color: Colors.white12, height: 32),
                            _earningsRow(
                              'Platform Fee (10%)',
                              '- ${_formatCurrency(platformFee, currencyCode: currencyCode)}',
                            ),
                            const SizedBox(height: 8),
                            _earningsRow(
                              'Net Payout',
                              _formatCurrency(
                                netPayout,
                                currencyCode: currencyCode,
                              ),
                              bold: true,
                              color: Colors.greenAccent,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Trip details',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _detailRow('Pickup', pickupAddress),
                            const SizedBox(height: 10),
                            _detailRow('Dropoff', dropoffAddress),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Get.offAllNamed('/dispatch'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Back to Dispatch',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatCurrency(double value, {String? currencyCode}) =>
      formatCurrencyAmount(value, currencyCode: currencyCode);

  Widget _detailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
          softWrap: true,
        ),
      ],
    );
  }

  Widget _earningsRow(
    String label,
    String value, {
    bool bold = false,
    Color color = Colors.white70,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54)),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
