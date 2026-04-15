import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'wallet_controller.dart';

class WalletView extends GetView<WalletController> {
  const WalletView({super.key});

  static const Color _blue = Color(0xFF1D4ED8);
  static const Color _blueDark = Color(0xFF1E3A8A);
  static const Color _blueDeep = Color(0xFF172554);
  static const Color _blueSoft = Color(0xFFEFF6FF);
  static const Color _orange = Color(0xFFF97316);
  static const Color _orangeSoft = Color(0xFFFFEDD5);
  static const Color _ink = Color(0xFF0F172A);
  static const Color _slate = Color(0xFF64748B);
  static const Color _line = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Wallet', style: TextStyle(color: _ink)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _blueDark),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {}, // Navigate to full history
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: controller.loadWalletData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBalanceCard(),
                  if (controller.loadError.value != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      controller.loadError.value!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Recent Transactions",
                        style: Get.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: controller.loadWalletData,
                        child: const Text(
                          "Refresh",
                          style: TextStyle(color: _blue),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (controller.transactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _line),
                      ),
                      child: const Text(
                        'No wallet transactions yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _slate),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.transactions.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 32, color: _line),
                      itemBuilder: (context, index) {
                        final tx = controller.transactions[index];
                        final isCredit = tx.amountMinor > 0;
                        return ListTile(
                          onTap: () => _showTransactionDetails(context, tx),
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: isCredit
                                ? _blueSoft
                                : _orangeSoft,
                            child: Icon(
                              isCredit
                                  ? Icons.arrow_downward
                                  : Icons.arrow_outward,
                              color: isCredit ? _blue : _orange,
                            ),
                          ),
                          title: Text(
                            'Transaction ${tx.id.substring(0, 6)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _ink,
                            ),
                          ),
                          subtitle: Text(
                            tx.createdAt.toLocal().toString(),
                            style: const TextStyle(color: _slate),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                tx.amountMinor > 0
                                    ? '+${controller.formatMinorAmount((tx.amountMinor / 100).toInt(), tx.currency)}'
                                    : '-${controller.formatMinorAmount((tx.amountMinor.abs() / 100).toInt(), tx.currency)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isCredit ? _blue : _orange,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tx.currency,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _slate,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFundWalletDialog(context),
        backgroundColor: _orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Fund Wallet",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, dynamic tx) {
    final isCredit = tx.amountMinor > 0;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: _line,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: isCredit ? _blueSoft : _orangeSoft,
                          child: Icon(
                            isCredit
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_outward_rounded,
                            color: isCredit ? _blue : _orange,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _readableReferenceType(tx.referenceType),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDateTime(tx.createdAt),
                                style: const TextStyle(color: _slate),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCredit
                                ? '+${_displayAmount((tx.amountMinor / 100).toInt(), tx.currency)}'
                                : '-${_displayAmount((tx.amountMinor.abs() / 100).toInt(), tx.currency)}',
                            style: TextStyle(
                              color: isCredit ? _blue : _orange,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildStatusChip(tx.status),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _detailRow(
                      'Transaction',
                      _readableReferenceType(tx.referenceType),
                    ),
                    _detailRow(
                      'Type',
                      isCredit ? 'Money in' : 'Money out',
                    ),
                    _detailRow(
                      'Status',
                      _readableStatus(tx.status),
                    ),
                    _detailRow(
                      'Amount',
                      _displayAmount((tx.amountMinor.abs() / 100).toInt(), tx.currency),
                    ),
                    _detailRow('Currency', tx.currency),
                    _detailRow(
                      'Date',
                      _formatDateTime(tx.createdAt),
                    ),
                    _detailRow(
                      'Recorded',
                      _formatDateTime(tx.updatedAt),
                    ),
                    _detailRow(
                      'Reference',
                      _humanReference(tx),
                    ),
                    _detailRow(
                      'Summary',
                      _transactionSummary(tx),
                    ),
                    if (tx.tags.isNotEmpty)
                      _detailSection(
                        'Labels',
                        tx.tags
                            .map(_readableReferenceType)
                            .join(', '),
                      ),
                    if (tx.metadata['note'] != null)
                      _detailSection(
                        'More Info',
                        tx.metadata['note'].toString(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _blueSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: _blueDark,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 124,
            child: Text(
              label,
              style: const TextStyle(
                color: _slate,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _slate,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _line),
            ),
            child: Text(
              body,
              style: const TextStyle(
                color: _ink,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _readableReferenceType(String referenceType) {
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

  String _readableStatus(String status) {
    return status
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

  String _displayAmount(int amountMinor, String currency) {
    final symbol = _currencySymbol(currency);
    final formatted = controller.formatMinorAmount(amountMinor, currency);
    if (symbol == currency.toUpperCase()) {
      return '$symbol $formatted';
    }
    return '$symbol$formatted';
  }

  String _currencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'NGN':
        return '₦';
      case 'USD':
        return '\$';
      case 'GBP':
        return '£';
      case 'EUR':
        return 'EUR';
      default:
        return currency.toUpperCase();
    }
  }

  String _humanReference(dynamic tx) {
    final metadata = tx.metadata as Map<String, dynamic>;
    final paymentIntentId = metadata['paymentIntentId']?.toString();
    final candidate = paymentIntentId ?? tx.referenceId.toString();
    if (candidate.length <= 12) {
      return candidate;
    }
    return '${candidate.substring(0, 8)}...${candidate.substring(candidate.length - 4)}';
  }

  String _transactionSummary(dynamic tx) {
    final type = _readableReferenceType(tx.referenceType);
    final status = _readableStatus(tx.status).toLowerCase();
    if (tx.amountMinor > 0) {
      return '$type was added to your wallet and is currently $status.';
    }
    return '$type was charged from your wallet and is currently $status.';
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final month = _monthName(local.month);
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$month $day, ${local.year} • $hour:$minute';
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

  void _showFundWalletDialog(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Fund Wallet',
          style: TextStyle(color: _blueDark, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Enter the amount you want to add to your wallet (NGN).'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                prefixText: '₦ ',
                hintText: '5000',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _blue),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _line),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: _blue)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final amountText = amountController.text;
              final amount = double.tryParse(amountText);
              if (amount == null || amount <= 0) {
                Get.snackbar('Error', 'Please enter a valid amount.');
                return;
              }
              Get.back();
              controller.fundWallet(amount);
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_blueDeep, _blueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: _blueDark.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Available Balance",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _orange.withValues(alpha: 0.28),
                  ),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(
            () => Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  controller.primaryBalanceSymbol == controller.primaryBalanceCurrencyCode
                      ? '${controller.primaryBalanceCurrencyCode} '
                      : '${controller.primaryBalanceSymbol} ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  controller.formattedPrimaryBalance,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Other Balance",
                style: TextStyle(color: Colors.white70),
              ),
              Obx(
                () => Text(
                  controller.secondaryBalanceSymbol ==
                          controller.secondaryBalanceCurrencyCode
                      ? '${controller.secondaryBalanceCurrencyCode} ${controller.formattedSecondaryBalance}'
                      : '${controller.secondaryBalanceSymbol} ${controller.formattedSecondaryBalance}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
